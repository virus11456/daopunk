#!/usr/bin/env python3
"""Offline reference checks for proposed lifecycle boundaries, not game runtime."""
import copy
import json


def initial():
    return {
        'world': {'tick': 100, 'history': ['caravan_route_opened'],
                  'npc': {'life_id': 'npc-7', 'recognizes_player': True}},
        'permanent': {'karma_unspent': 73, 'memories': ['met_red'], 'arts': {
            'fixture_life_a': {'years': 10, 'health': 5, 'qi': 0},
            'fixture_life_b': {'years': 20, 'health': 3, 'qi': 4}},
            'laws': ['fate']},
        'life': {'id': 1, 'elapsed': 30, 'medical_qualified': True,
                 'medical_used': False, 'temporary_years': 0},
        'body': {'id': 'body-a', 'health': 4, 'qi': 2},
        'rebirth_transactions': [],
    }


def limits(state):
    effects = state['permanent']['arts'].values()
    return {'years': 99 + sum(x['years'] for x in effects)
            + state['life']['temporary_years'],
            'health': 10 + sum(x['health'] for x in effects),
            'qi': 10 + sum(x['qi'] for x in effects)}


def apply_medical(state):
    life = state['life']
    if not life['medical_qualified'] or life['medical_used']:
        return False
    life['medical_used'] = True
    life['temporary_years'] += 20  # Fixture only, not a balanced skill value.
    return True


def grant_law(state, law):
    # Preconditions (Dao ruler qualification) are supplied by future runtime.
    if law in state['permanent']['laws']:
        return False
    state['permanent']['laws'].append(law)
    return True


def rebirth(state, transaction, next_tick, next_body):
    if transaction in state['rebirth_transactions']:
        return False
    if next_tick < state['world']['tick']:
        raise ValueError('world time cannot move backward')
    state['world']['tick'] = next_tick
    state['life'] = {'id': state['life']['id'] + 1, 'elapsed': 0,
                     'medical_qualified': False, 'medical_used': False,
                     'temporary_years': 0}
    # Caller provides these because age/body timing and spawn resources are undecided.
    state['body'] = copy.deepcopy(next_body)
    state['rebirth_transactions'].append(transaction)
    return True


def run_checks():
    checks = []

    def check(label, condition):
        if not condition:
            raise AssertionError(label)
        checks.append(label)

    state = initial()
    check('distinct_arts_stack', limits(state) == {'years': 129, 'health': 18, 'qi': 14})
    check('medical_first_use', apply_medical(state) and limits(state)['years'] == 149)
    before = copy.deepcopy(state)
    check('medical_repeat_rejected', not apply_medical(state) and state == before)
    state['body']['id'] = 'replacement'
    check('body_change_does_not_refresh_medical', not apply_medical(state))
    permanent = copy.deepcopy(state['permanent'])
    history = copy.deepcopy(state['world']['history'])
    npc = copy.deepcopy(state['world']['npc'])
    rebirth(state, 'rebirth-1', 150, {'id': 'new-human', 'health': 3, 'qi': 1})
    check('permanent_memories_arts_laws_preserved', state['permanent'] == permanent)
    check('unspent_karma_preserved_in_full', state['permanent']['karma_unspent'] == 73)
    check('world_and_npc_history_preserved', state['world']['history'] == history and state['world']['npc'] == npc)
    check('medical_bonus_reset_not_permanent', limits(state)['years'] == 129)
    check('recultivation_required', not apply_medical(state))
    state['life']['medical_qualified'] = True
    check('medical_available_after_recultivation', apply_medical(state) and limits(state)['years'] == 149)
    saved = json.loads(json.dumps(state))
    check('save_roundtrip_keeps_once_only_guard', not apply_medical(saved) and saved == state)
    before = copy.deepcopy(saved)
    check('same_law_cannot_be_regranted', not grant_law(saved, 'fate') and saved == before)
    check('different_laws_can_coexist', grant_law(saved, 'space') and saved['permanent']['laws'] == ['fate', 'space'])
    check('stat_limits_do_not_refill_resources', saved['body']['health'] == 3 and saved['body']['qi'] == 1)
    before = copy.deepcopy(saved)
    check('rebirth_retry_is_idempotent', not rebirth(saved, 'rebirth-1', 170, {}) and saved == before)
    try:
        rebirth(saved, 'invalid', 1, {})
    except ValueError:
        check('reject_backward_time_without_mutation', saved == before)
    else:
        raise AssertionError('backward time accepted')
    for i in range(2, 6):
        rebirth(saved, f'rebirth-{i}', 150 + i, {'id': f'human-{i}', 'health': 3, 'qi': 1})
    check('repeated_lives_do_not_multiply_permanent_bonus', limits(saved)['years'] == 129 and len(saved['permanent']['arts']) == 2)
    return {'status': 'passed', 'scope': 'offline_proposed_reference_model',
            'checks': checks, 'count': len(checks),
            'not_tested': ['Godot', 'full_save_system', 'karma_transactions',
                           'law_eligibility', 'world_simulation', 'production_balance']}


if __name__ == '__main__':
    print(json.dumps(run_checks(), ensure_ascii=False, indent=2))
