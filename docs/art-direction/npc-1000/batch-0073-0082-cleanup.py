from PIL import Image
from pathlib import Path
import json
base=Path('work/daopunk/docs/art-direction/npc-1000/assets')
for num,ver in [(n,1) for n in range(73,83)]:
 im=Image.open(base/f'NPC-{num:04d}-front-v{ver}.png').convert('RGBA')
 mask=im.getchannel('A').point(lambda x:255 if x>=128 else 0)
 box=mask.getbbox(); im=im.crop(box)
 im.thumbnail((36,44),Image.Resampling.NEAREST)
 alpha=im.getchannel('A').point(lambda x:255 if x>=128 else 0)
 palette=Image.new('P',(1,1)); colors=['191c25','30343e','505662','818484','b5b4a3','f6ead0','dec8a2','ae956f','756448','3a3040','333751','484f82','646ca0','8992bb','43342c','78442d','ac6135','da8645','f5ba4b','ffe07c','293e38','3d6452','588761','87b991','16594e','218e78','4ce4bc','5b2824','9a4030','ce6245','e99b6a','ffffff'];palette.putpalette([v for h in colors for v in bytes.fromhex(h)]+[25,28,37]*(256-len(colors)));rgb=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');rgb.putalpha(alpha)
 out=Image.new('RGBA',(40,48));out.alpha_composite(rgb,((40-rgb.width)//2,46-rgb.height))
 out.save(base/f'NPC-{num:04d}-front-clean-v1.png')
 out.resize((320,384),Image.Resampling.NEAREST).save(base/f'NPC-{num:04d}-front-clean-v1-preview.png')
 print(num,box,len(set(out.getdata())),set(out.getchannel('A').getdata()))
