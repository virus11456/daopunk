"""Behavior checks for the small offline event proposal."""
import argparse
from copy import deepcopy
import json
from pathlib import Path
from random_event_reference import new_state, validate_catalog, event_by_id, eligible, start, resolve, advance

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / 'docs/contracts/random-event-sample.json').read_text())
CONTEXT = {'location_tags': ['settlement'], 'participant_tags': ['local_service']}
A, B, C, D = [e['id'] for e in CATALOG['events']]
results = []

def check(name, condition):
    if not condition:
        raise AssertionError(name)
    results.append({'check': name, 'passed': True})

def rejected(fn):
    try:
        fn()
    except ValueError:
        return True
    return False

validate_catalog(CATALOG)
s = new_state()
check('participant eligibility', start(s,CATALOG,A,'a',{'location_tags':['settlement']}) is None)
check('location eligibility', start(s,CATALOG,A,'a',{'participant_tags':['local_service']}) is None)
check('consequence requires prior effect', start(s,CATALOG,C,'c',CONTEXT) is None)
start(s,CATALOG,A,'a',CONTEXT)
check('mutex blocks overlapping occurrence', start(s,CATALOG,B,'b',CONTEXT) is None)
check('independent group can coexist', start(s,CATALOG,D,'d',CONTEXT) is not None)
resolve(s,'a')
check('once event never restarts', start(s,CATALOG,A,'a2',CONTEXT) is None)
check('history is idempotent', resolve(s,'a') and len(s['history']) == 1)
check('same occurrence returns saved outcome', start(s,CATALOG,A,'a',CONTEXT)['outcome']['id'] == 'route_checked')
check('occurrence ID cannot alias another event', rejected(lambda:start(s,CATALOG,B,'a',CONTEXT)))
resolve(s,'d')
check('periodic cooldown active', start(s,CATALOG,D,'d2',CONTEXT) is None)
advance(s,3)
check('periodic cooldown boundary', start(s,CATALOG,D,'d2',CONTEXT) is not None)
start(s,CATALOG,B,'b',CONTEXT)
advance(s,5)
check('absence resolves deadline without player', s['occurrences']['b']['mode']=='absent' and 'parts_needed' in s['flags'])
check('consequence enabled by persisted effect', start(s,CATALOG,C,'c',CONTEXT) is not None)
resolve(s,'c')
advance(s,20)
check('permanently resolved periodic event excluded', start(s,CATALOG,B,'b2',CONTEXT) is None)
check('completed consequence never restarts', start(s,CATALOG,C,'c2',CONTEXT) is None)
check('reverse time rejected', rejected(lambda:advance(s,19)))

s = new_state(73)
start(s,CATALOG,B,'stable',CONTEXT)
loaded = json.loads(json.dumps(s))
r = resolve(s,'stable')
check('pending save/load preserves result', resolve(loaded,'stable') == r)
loaded = json.loads(json.dumps(s))
check('completed save/load cannot reroll or duplicate effects', resolve(loaded,'stable') == r and loaded == s)
changed = deepcopy(CATALOG)
changed['events'][1]['outcomes']['present'] = [changed['events'][1]['outcomes']['absent'][0]]
pending = new_state(73)
start(pending,CATALOG,B,'stable',CONTEXT)
start(pending,changed,B,'stable',CONTEXT)
check('pending definition retained after catalog changes', resolve(pending,'stable') == r)

s = new_state()
start(s,CATALOG,B,'absent',CONTEXT)
start(s,CATALOG,D,'independent',CONTEXT)
step = deepcopy(s)
advance(s,50)
for t in range(1,51):
    advance(step,t)
check('large absence catchup equals small steps', s == step)
check('repeated catchup has no duplicate history', len(s['history']) == 2)
bad = deepcopy(CATALOG)
bad['events'].append(bad['events'][0])
check('duplicate catalog IDs rejected', rejected(lambda:validate_catalog(bad)))

parser=argparse.ArgumentParser()
parser.add_argument('--report',type=Path)
args=parser.parse_args()
report={'scope':'offline_reference_only','sample_templates':4,'passed':len(results),'failed':0,'checks':results}
if args.report:
    args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'passed':len(results),'failed':0,'sample_templates':4}))
