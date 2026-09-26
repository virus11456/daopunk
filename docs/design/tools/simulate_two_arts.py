"""Offline reward-design check; not a Godot battle or balance simulator."""
from pathlib import Path
import json,random,itertools,collections
REGISTRY=Path(__file__).resolve().parents[2]/'art-direction/five-arts-v3/registry.json'
WEIGHTS={'early':{'common':80,'uncommon':20,'rare':0},'middle':{'common':65,'uncommon':30,'rare':5},'late':{'common':50,'uncommon':35,'rare':15}}

def rewards(registry, schools, mastery, phase, seed, preferences=()):
    if len(schools)!=2 or len(set(schools))!=2: raise ValueError('Choose exactly two different schools')
    known={a['id'] for a in registry['arts']}
    if not set(schools)<=known: raise ValueError('Unknown school')
    if any(not 1<=mastery[s]<=5 for s in schools): raise ValueError('Mastery must be 1..5')
    if len(set(preferences))>2: raise ValueError('At most two effect preferences')
    rng=random.Random(str(seed)); pair=sorted(schools); chosen=[]
    pools={s:[c for a in registry['arts'] if a['id']==s for c in a['cards'] if c['unlock_mastery']<=mastery[s] and WEIGHTS[phase][c['rarity']]>0] for s in pair}
    def draw(s):
        legal=[c for c in pools[s] if c['id'] not in {x['id'] for x in chosen}]
        tiers=[t for t in WEIGHTS[phase] if any(c['rarity']==t for c in legal)]
        if not tiers:return None
        tier=rng.choices(tiers,[WEIGHTS[phase][t] for t in tiers])[0]
        options=[c for c in legal if c['rarity']==tier]
        weights=[2 if set(preferences)&set(c['effect_tags']) else 1 for c in options]
        return rng.choices(options,weights)[0]
    for s in pair:
        c=draw(s)
        if c: chosen.append(c)
    s=rng.choice(pair);c=draw(s)
    if c is None:c=draw(next(x for x in pair if x!=s))
    if c: chosen.append(c)
    return chosen

def verify():
    r=json.loads(REGISTRY.read_text());schools=[a['id'] for a in r['arts']]
    allcards=[c for a in r['arts'] for c in a['cards']]
    assert len(allcards)==len({c['id'] for c in allcards})==len({c['name'] for c in allcards})==225
    for a in r['arts']:
        assert len(a['cards'])==45 and 'branches' not in a
        assert collections.Counter(c['unlock_mastery'] for c in a['cards'])=={i:9 for i in range(1,6)}
        assert all('branch' not in c and 'prerequisite' not in c for c in a['cards'])
    combos=list(itertools.combinations(schools,2));assert len(combos)==10
    n=0;mixed=collections.Counter()
    for pair in combos:
        for levels in [(1,1),(1,5),(5,1),(3,3),(5,5)]:
            mastery=dict(zip(pair,levels))
            for phase in WEIGHTS:
                for seed in range(100):
                    cards=rewards(r,pair,mastery,phase,f'{pair}:{levels}:{phase}:{seed}',('護體','抽牌'))
                    assert len(cards)==3 and len({c['id'] for c in cards})==3
                    assert {cards[0]['school'],cards[1]['school']}==set(pair)
                    assert all(c['school'] in pair and c['unlock_mastery']<=mastery[c['school']] and WEIGHTS[phase][c['rarity']]>0 for c in cards)
                    assert cards==rewards(r,pair[::-1],mastery,phase,f'{pair}:{levels}:{phase}:{seed}',('護體','抽牌'))
                    if levels==(1,5):mixed['smaller' if cards[2]['school']==pair[0] else 'larger']+=1
                    n+=1
    # Tiny pools: do not duplicate or unlock forbidden rarities to fill a missing slot.
    tiny={'arts':[{'id':'a','cards':[dict(id='a1',school='a',unlock_mastery=1,rarity='common',effect_tags=[])]},{'id':'b','cards':[dict(id='b1',school='b',unlock_mastery=1,rarity='rare',effect_tags=[])]}]}
    few=rewards(tiny,['a','b'],{'a':1,'b':1},'early','edge')
    assert [c['id'] for c in few]==['a1']
    try:rewards(r,[schools[0],schools[0]],{schools[0]:1},'early','bad')
    except ValueError:pass
    else:raise AssertionError('Duplicate schools accepted')
    return dict(status='passed',reward_draws=n,pairs=10,cards=225,unequal_pool_mixed_slot=dict(mixed),limits='Only selection invariants tested; no battle, economy, innate-skill stacking or Godot verification.')

if __name__=='__main__':print(json.dumps(verify(),ensure_ascii=False,indent=2))
