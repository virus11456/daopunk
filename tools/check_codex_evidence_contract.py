"""Run from anywhere: python3 tools/check_codex_evidence_contract.py."""
import json
from pathlib import Path
from copy import deepcopy
from codex_evidence_reference import new_memory, record, player_view, reincarnate, validate_catalog

ROOT = Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / 'docs/contracts/codex-evidence-sample.json').read_text())
events = {e['id']: e for e in catalog['events']}
checks = []

def check(name, condition):
    if not condition:
        raise AssertionError(name)
    checks.append({'name': name, 'passed': True})

def rejects(fn):
    try:
        fn()
    except ValueError:
        return True
    return False

def add(mem, name, **kwargs):
    return record(mem, catalog, events[name], known=kwargs.get('known', []),
                  occurred=kwargs.get('occurred', [name]), now=kwargs.get('now', 100))

m = new_memory()
check('未取得條目不顯示作者目錄', player_view(m, catalog, 'DEMO-ANCIENT') is None)
check('未發生事件不能入記憶', not add(m, 'read-1', occurred=[]))
add(m, 'read-1')
check('背過經文不等於親見', player_view(m, catalog, 'DEMO-BIRD')['flags'] == ['未親見'])
check('輸出不含作者秘密', '不得出現在' not in json.dumps(player_view(m, catalog, 'DEMO-BIRD'), ensure_ascii=False))
check('重播同一事件冪等', not add(m, 'read-1') and len(m['records']) == 1)
changed = deepcopy(events['read-1']); changed['text'] = 'changed'
check('同ID異文拒絕覆寫歷史', rejects(lambda: record(m, catalog, changed, known=[], occurred=['read-1'], now=100)))
add(m, 'heard-1'); add(m, 'heard-2')
check('兩人轉述同源保留兩份但不算兩個源頭', len(m['records']) == 3 and player_view(m, catalog, 'DEMO-BIRD')['source_lineage_count'] == 2)
check('未到世界時間不可提前知情', rejects(lambda: add(m, 'seen-1', now=3)))
add(m, 'seen-1'); add(m, 'absent-1')
v = player_view(m, catalog, 'DEMO-BIRD')
check('再訪未見保留既有親見且不斷言滅絕', {'親見', '再訪未見'} <= set(v['flags']) and '滅絕' not in v['flags'])
check('訂正知識門檻未達不洩露', not add(m, 'correct-1'))
check('訂正缺引用證據拒絕', rejects(lambda: add(new_memory(), 'correct-1', known=['comparison-learned'])))
add(m, 'correct-1', known=['comparison-learned'])
check('訂正追加保留原文', len(m['records']) == 6 and m['records'][0]['text'] == events['read-1']['text'])
future = deepcopy(events['seen-1']); future.update(id='seen-2', life=8, world_time=90, acquired_at=90)
record(m, catalog, future, known=[], occurred=['seen-2'], now=100)
check('跨世親见不綁指定世次', '跨世再見' in player_view(m, catalog, 'DEMO-BIRD')['flags'])
world = {'time': 100, 'items': {'book-a': {'custodian': 'library', 'place': 'test-library'}}}
m2, w2, body = reincarnate(m, world, at_time=130)
check('輪迴保存所有取得記憶實物留原處', m2 == m and w2['items'] == world['items'] and body['inventory'] == [])
m2['records'][0]['text'] = 'modified'
check('新狀態不意外改寫舊快照', m['records'][0]['text'] == events['read-1']['text'])
check('正式輪迴世界時間不倒轉', rejects(lambda: reincarnate(m, world, at_time=99)))
bad = deepcopy(catalog); bad['entries'][0]['kind'] = 'individual_npc'
check('拒絕個別NPC條目', rejects(lambda: validate_catalog(bad)))
bad = deepcopy(catalog); bad['entries'][2]['editorial_status'] = 'canon'
check('古籍神與人物邊界保持提案', rejects(lambda: validate_catalog(bad)))
solo = new_memory(); add(solo, 'seen-1')
check('可直接親見不用先讀經文或聽傳聞', player_view(solo, catalog, 'DEMO-BIRD')['flags'] == ['親見'])
report = {'status': 'passed', 'scope': 'offline_synthetic_contract_only_not_godot',
          'count': len(checks), 'checks': checks}
(ROOT / 'docs/contracts/codex-evidence-validation.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'{len(checks)} codex evidence checks passed')
