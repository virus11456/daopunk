"""Offline proposal: evidence-backed player codex, not an engine/save implementation."""
from copy import deepcopy

KINDS = {'text', 'rumor', 'observation', 'revisit_absent', 'correction', 'annotation'}
ENTRY_KINDS = {'species', 'type', 'landscape', 'ruin', 'ancient_subject'}


def validate_catalog(catalog):
    entries = catalog['entries']
    ids = [e['id'] for e in entries]
    if len(ids) != len(set(ids)):
        raise ValueError('duplicate entry')
    for e in entries:
        if e['kind'] not in ENTRY_KINDS:
            raise ValueError('individual NPC entries are excluded')
        if e['kind'] == 'ancient_subject' and e.get('editorial_status') != 'proposal':
            raise ValueError('ancient divine subject boundary remains a proposal')
    return {e['id']: e for e in entries}


def new_memory():
    return {'records': []}


def record(memory, catalog, event, *, known, occurred, now):
    """Only trusted caller-supplied acquired events; never ingest author-only fields."""
    entries = validate_catalog(catalog)
    required = {'id', 'entry_id', 'kind', 'source_id', 'root_source_id',
                'life', 'world_time', 'acquired_at', 'place', 'text', 'requires', 'citations'}
    if not required <= event.keys() or event['entry_id'] not in entries:
        raise ValueError('invalid evidence record')
    if event['kind'] not in KINDS:
        raise ValueError('invalid evidence kind')
    if not event['source_id'] or not event['root_source_id']:
        raise ValueError('source identity required')
    if not isinstance(event['life'], int) or event['life'] < 1:
        raise ValueError('invalid life')
    if event['world_time'] > event['acquired_at'] or event['acquired_at'] > now:
        raise ValueError('future evidence')
    if event['id'] not in occurred or not set(event['requires']) <= set(known):
        return False
    old = next((r for r in memory['records'] if r['id'] == event['id']), None)
    safe = {key: deepcopy(event[key]) for key in required}
    if old is not None:
        if old != safe:
            raise ValueError('same event ID with changed content')
        return False
    if event['kind'] == 'correction':
        prior = {r['id']: r for r in memory['records']}
        refs = event['citations']
        if not refs or any(r not in prior or prior[r]['entry_id'] != event['entry_id'] for r in refs):
            raise ValueError('correction needs acquired same-entry evidence')
        # This establishes a traceable player judgement, not author-confirmed truth.
    memory['records'].append(safe)
    return True


def player_view(memory, catalog, entry_id):
    entry = validate_catalog(catalog)[entry_id]
    rows = [deepcopy(r) for r in memory['records'] if r['entry_id'] == entry_id]
    if not rows:
        return None
    flags = set()
    observations = [r for r in rows if r['kind'] == 'observation']
    if not observations:
        flags.add('未親見')
    if any(r['kind'] == 'rumor' for r in rows):
        flags.add('聽聞')
    if observations:
        flags.add('親見')
    if len({r['life'] for r in observations}) > 1:
        flags.add('跨世再見')
    if any(r['kind'] == 'revisit_absent' for r in rows):
        flags.add('再訪未見')
    if any(r['kind'] == 'correction' for r in rows):
        flags.add('有訂正判斷')
    return {'id': entry_id, 'label': entry['public_label'], 'flags': sorted(flags),
            'records': rows,
            'source_lineage_count': len({r['root_source_id'] for r in rows})}


def reincarnate(memory, world, *, at_time):
    if at_time < world['time']:
        raise ValueError('world time cannot rewind')
    next_world = deepcopy(world)
    next_world['time'] = at_time
    # Custody is unchanged by this operation; a world simulation may change it separately.
    return deepcopy(memory), next_world, {'inventory': []}
