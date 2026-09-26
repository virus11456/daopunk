"""Offline proposal: persistent event occurrences; not a Godot runtime."""
from copy import deepcopy
import hashlib


def new_state(seed=1):
    return {'tick': 0, 'seed': seed, 'flags': [], 'resolved': [],
            'last_completed': {}, 'occurrences': {}, 'history': []}


def validate_catalog(catalog):
    ids = [e['id'] for e in catalog['events']]
    if len(ids) != len(set(ids)):
        raise ValueError('duplicate event ID')
    for e in catalog['events']:
        if e['kind'] not in ('once', 'periodic', 'consequence'):
            raise ValueError('unknown kind')
        if e['cooldown'] < 0 or e['window'] < 1:
            raise ValueError('invalid duration')
        if e['kind'] == 'consequence' and not e['requires_flags']:
            raise ValueError('consequence needs historical condition')
        for mode in ('present', 'absent'):
            outcomes = e['outcomes'][mode]
            if not outcomes or len({o['id'] for o in outcomes}) != len(outcomes):
                raise ValueError('invalid outcomes')
            if any(o['weight'] <= 0 for o in outcomes):
                raise ValueError('nonpositive weight')


def event_by_id(catalog, event_id):
    return next(e for e in catalog['events'] if e['id'] == event_id)


def eligible(state, event, context):
    flags = set(state['flags'])
    if event['id'] in state['resolved']:
        return False
    if not set(event['requires_flags']) <= flags or set(event['forbids_flags']) & flags:
        return False
    if not set(event['location_tags']) <= set(context.get('location_tags', [])):
        return False
    if not set(event['participant_tags']) <= set(context.get('participant_tags', [])):
        return False
    completed = state['last_completed'].get(event['id'])
    if completed is not None:
        if event['kind'] != 'periodic' or state['tick'] < completed + event['cooldown']:
            return False
    for occurrence in state['occurrences'].values():
        if occurrence['status'] == 'pending' and (
            occurrence['event_id'] == event['id'] or
            (event['mutex'] and occurrence['mutex'] == event['mutex'])
        ):
            return False
    return True


def start(state, catalog, event_id, occurrence_id, context):
    """Existing IDs are idempotent; candidates do not become outcomes on map load."""
    old = state['occurrences'].get(occurrence_id)
    if old:
        if old['event_id'] != event_id:
            raise ValueError('occurrence ID collision')
        return deepcopy(old)
    event = event_by_id(catalog, event_id)
    if not eligible(state, event, context):
        return None
    occurrence = {'id': occurrence_id, 'event_id': event_id, 'mutex': event['mutex'],
                  'status': 'pending', 'created_at': state['tick'],
                  'deadline': state['tick'] + event['window'],
                  'context': deepcopy(context), 'definition': deepcopy(event)}
    # Definition snapshot keeps pending outcomes stable across catalog revisions.
    state['occurrences'][occurrence_id] = occurrence
    return deepcopy(occurrence)


def resolve(state, occurrence_id, mode='present'):
    occurrence = state['occurrences'][occurrence_id]
    if occurrence['status'] == 'completed':
        return deepcopy(occurrence)
    if mode not in ('present', 'absent'):
        raise ValueError('unknown mode')
    if state['tick'] >= occurrence['deadline']:
        mode = 'absent'
    event = occurrence['definition']
    outcomes = event['outcomes'][mode]
    digest = hashlib.sha256(f"{state['seed']}:{occurrence_id}:{mode}".encode()).digest()
    draw = int.from_bytes(digest, 'big') % sum(o['weight'] for o in outcomes)
    for outcome in outcomes:
        if draw < outcome['weight']:
            break
        draw -= outcome['weight']
    flags = set(state['flags']) - set(outcome['remove_flags'])
    state['flags'] = sorted(flags | set(outcome['add_flags']))
    state['resolved'] = sorted(set(state['resolved']) | set(outcome['permanently_resolve']))
    state['last_completed'][event['id']] = state['tick']
    occurrence.update(status='completed', completed_at=state['tick'], mode=mode,
                      outcome=deepcopy(outcome))
    state['history'].append({'occurrence_id': occurrence_id, 'event_id': event['id'],
                             'tick': state['tick'], 'outcome_id': outcome['id'], 'mode': mode})
    return deepcopy(occurrence)


def advance(state, target_tick):
    if target_tick < state['tick']:
        raise ValueError('world time cannot reverse')
    due = sorted((o['deadline'], o['id']) for o in state['occurrences'].values()
                 if o['status'] == 'pending' and o['deadline'] <= target_tick)
    for deadline, occurrence_id in due:
        state['tick'] = deadline
        resolve(state, occurrence_id, 'absent')
    state['tick'] = target_tick
