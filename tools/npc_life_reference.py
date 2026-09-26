"""Deterministic offline design fixture; not a Godot scheduler or pathfinder."""
from copy import deepcopy


def validate(data):
    if data['period'] <= 0:
        raise ValueError('period must be positive')
    ids = [n['id'] for n in data['npcs']]
    if len(ids) != len(set(ids)):
        raise ValueError('duplicate NPC')
    for n in data['npcs']:
        if not 0 <= n['work_start'] < n['work_end'] <= data['period']:
            raise ValueError('invalid schedule')
    for a, b in data['rain_intervals']:
        if not 0 <= a < b:
            raise ValueError('invalid weather interval')
    reports = {r['id']: r for r in data['reports']}
    if len(reports) != len(data['reports']):
        raise ValueError('duplicate report')
    for r in reports.values():
        if not 0 <= r['occurred_at'] <= r['published_at'] <= r['due_at']:
            raise ValueError('invalid report timeline')
        if r['channel'] not in ('caravan', 'wire') or not set(r['recipients']) <= set(ids):
            raise ValueError('invalid report routing')
        for prior_id in r.get('supersedes', []):
            prior = reports.get(prior_id)
            if not prior or prior['claim_id'] != r['claim_id'] or prior['published_at'] >= r['published_at']:
                raise ValueError('invalid correction')
    if data['shelter_capacity'] < 0:
        raise ValueError('negative capacity')


def initial(data):
    validate(data)
    return {'tick': -1, 'player_life': 1, 'player_memories': [],
            'npcs': {n['id']: {'intent': 'home', 'reason': 'rest',
                             'knowledge': [], 'recognises_player': False} for n in data['npcs']},
            'reports': deepcopy(data['reports']), 'delivered': {}, 'history': []}


def advance(state, data, target):
    """Tick-by-tick catch-up, for small fixtures only. No hidden random calls."""
    if target < state['tick']:
        raise ValueError('time cannot move backwards')
    for tick in range(state['tick'] + 1, target + 1):
        rainy = any(a <= tick < b for a, b in data['rain_intervals'])
        capacity = data['shelter_capacity']
        # Reproducible ID tie-break is only a fixture, not a fair production queue.
        for n in sorted(data['npcs'], key=lambda n: n['id']):
            npc = state['npcs'][n['id']]
            working = n['work_start'] <= tick % data['period'] < n['work_end']
            intent, reason = ('work', 'schedule') if working else ('home', 'rest')
            if working and n['outdoor'] and rainy:
                if capacity:
                    intent, reason = 'shelter', 'rain'; capacity -= 1
                else:
                    intent, reason = 'home', 'shelter_full'
            if (intent, reason) != (npc['intent'], npc['reason']):
                state['history'].append({'tick': tick, 'npc_id': n['id'], 'intent': intent, 'reason': reason})
            npc.update(intent=intent, reason=reason)
        for r in state['reports']:
            if r['id'] in state['delivered']:
                continue
            if tick >= r['published_at'] and rainy and r['channel'] == 'caravan':
                r['due_at'] += 1
            if tick >= r['due_at']:
                state['delivered'][r['id']] = tick
                for recipient in r['recipients']:
                    state['npcs'][recipient]['knowledge'].append(r['id'])
        state['tick'] = tick
    return state


def known_claim(state, npc_id, claim_id):
    known = set(state['npcs'][npc_id]['knowledge'])
    records = [r for r in state['reports'] if r['id'] in known and r['claim_id'] == claim_id]
    # Only an explicit correction supersedes a statement, not late arrival alone.
    superseded = {old for r in records for old in r.get('supersedes', [])}
    return [r['id'] for r in records if r['id'] not in superseded]


def independent_sources(state, npc_id, claim_id):
    active = set(known_claim(state, npc_id, claim_id))
    return sorted({r['root_source_id'] for r in state['reports'] if r['id'] in active})


def reincarnate_player(state):
    state['player_life'] += 1
    # World time, pending reports, NPC knowledge and recognition are not reset.
    return state
