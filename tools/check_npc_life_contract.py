#!/usr/bin/env python3
"""Run independent behavior assertions and optionally write a JSON report."""
import argparse
import copy
import json
from pathlib import Path
import unittest
from npc_life_reference import initial, advance, known_claim, independent_sources, reincarnate_player, validate

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / 'docs/contracts/npc-life-sample.json').read_text())


class LifeChecks(unittest.TestCase):
    def setUp(self):
        self.data = copy.deepcopy(DATA)
        self.state = initial(self.data)

    def test_schedule_boundaries(self):
        advance(self.state, self.data, 5)
        self.assertEqual(self.state['npcs']['fixture-repairer']['intent'], 'home')
        advance(self.state, self.data, 6)
        self.assertEqual(self.state['npcs']['fixture-repairer']['intent'], 'work')
        advance(self.state, self.data, 18)
        self.assertEqual(self.state['npcs']['fixture-repairer']['intent'], 'home')

    def test_shelter_and_indoor_work(self):
        advance(self.state, self.data, 8)
        n = self.state['npcs']
        self.assertEqual(sum(v['intent'] == 'shelter' for v in n.values()), 1)
        self.assertEqual(n['fixture-repairer']['reason'], 'shelter_full')
        self.assertEqual(n['fixture-clerk']['intent'], 'work')
        advance(self.state, self.data, 11)
        self.assertEqual(n['fixture-repairer']['intent'], 'work')

    def test_zero_shelter_capacity(self):
        self.data['shelter_capacity'] = 0
        advance(self.state, self.data, 8)
        self.assertFalse(any(n['intent'] == 'shelter' for n in self.state['npcs'].values()))

    def test_caravan_delay_not_wire_delay(self):
        advance(self.state, self.data, 9)
        self.assertNotIn('caravan-rumor', self.state['delivered'])
        self.assertEqual(self.state['delivered']['wire-original'], 9)
        advance(self.state, self.data, 12)
        self.assertEqual(self.state['delivered']['caravan-rumor'], 12)
        self.assertEqual(self.state['reports'][0]['occurred_at'], 4)

    def test_unlearned_secret_not_returned(self):
        advance(self.state, self.data, 30)
        self.assertEqual(known_claim(self.state, 'fixture-repairer', 'attackers_identity'), [])

    def test_correction_is_recipient_specific(self):
        advance(self.state, self.data, 15)
        self.assertEqual(known_claim(self.state, 'fixture-clerk', 'route_status'), ['wire-correction'])
        self.assertEqual(known_claim(self.state, 'fixture-repairer', 'route_status'), ['caravan-rumor'])
        self.assertIn('wire-original', self.state['npcs']['fixture-clerk']['knowledge'])

    def test_same_source_repeated_is_not_independent(self):
        advance(self.state, self.data, 13)
        self.assertEqual(independent_sources(self.state, 'fixture-clerk', 'route_status'), ['port-office'])

    def test_late_original_does_not_undo_correction(self):
        self.data['reports'][1]['due_at'] = 20
        self.state = initial(self.data)
        advance(self.state, self.data, 20)
        self.assertEqual(known_claim(self.state, 'fixture-clerk', 'route_status'), ['wire-correction'])

    def test_rebirth_preserves_world_and_memory(self):
        advance(self.state, self.data, 9)
        self.state['player_memories'] = ['read_old_atlas']
        self.state['npcs']['fixture-clerk']['recognises_player'] = True
        before = copy.deepcopy(self.state)
        reincarnate_player(self.state)
        before['player_life'] += 1
        self.assertEqual(self.state, before)
        advance(self.state, self.data, 12)
        self.assertIn('caravan-rumor', self.state['delivered'])

    def test_bulk_catchup_matches_steps(self):
        a, b = initial(self.data), initial(self.data)
        advance(a, self.data, 30)
        for t in range(31):
            advance(b, self.data, t)
        self.assertEqual(a, b)

    def test_save_resume_and_reenter_idempotent(self):
        advance(self.state, self.data, 9)
        restored = json.loads(json.dumps(self.state))
        advance(restored, self.data, 9)
        self.assertEqual(restored, self.state)
        advance(restored, self.data, 30)
        advance(self.state, self.data, 30)
        self.assertEqual(restored, self.state)
        self.assertEqual(len(restored['npcs']['fixture-clerk']['knowledge']), 3)

    def test_bad_time_and_duplicate_ids_rejected(self):
        advance(self.state, self.data, 10)
        with self.assertRaises(ValueError):
            advance(self.state, self.data, 9)
        self.data['npcs'].append(self.data['npcs'][0])
        with self.assertRaises(ValueError):
            validate(self.data)

    def test_report_before_event_rejected(self):
        self.data['reports'][0]['published_at'] = 0
        with self.assertRaises(ValueError):
            validate(self.data)

    def test_location_and_climate_reference(self):
        world = json.loads((ROOT / 'docs/worldbuilding/world-catalog.json').read_text())
        climate = json.loads((ROOT / 'docs/worldbuilding/climate-catalog.json').read_text())
        self.assertIn(self.data['location_id'], [c['id'] for c in world['cities']])
        self.assertIn(self.data['location_id'], [c['location_id'] for c in climate['locations']])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(LifeChecks))
    if args.report:
        args.report.write_text(json.dumps({'scope': 'offline_fixture_not_godot', 'tests_run': result.testsRun,
            'passed': result.wasSuccessful(), 'failures': len(result.failures), 'errors': len(result.errors)}, indent=2)+'\n')
    raise SystemExit(0 if result.wasSuccessful() else 1)
