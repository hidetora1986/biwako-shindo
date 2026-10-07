"""Original hand-built instrument glyphs; offline PNGs, single 1–2px stroke."""
from PIL import Image,ImageDraw
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'assets/visual/v2/hud/icons';out.mkdir(parents=True,exist_ok=True)
for name in ['money','rod','reel','line','sonar','shop','book','area','save','depth','cast','hook','boat','anchor']:
 im=Image.new('RGBA',(24,24));d=ImageDraw.Draw(im);c='#c8e4d8'
 if name=='money':
  d.ellipse((3,3,21,21),outline=c,width=2);d.line((8,6,12,11,16,6),fill=c);d.line((12,10,12,18),fill=c);d.line((8,12,16,12),fill=c);d.line((8,15,16,15),fill=c)
 elif name=='rod':d.line((5,21,15,4,19,3),fill=c,width=2);d.line((19,3,20,16,17,18),fill=c)
 elif name=='reel':d.ellipse((5,5,18,18),outline=c,width=2);d.ellipse((9,9,14,14),outline=c);d.line((18,12,22,12,22,17),fill=c,width=2);d.rectangle((21,16,23,19),fill=c)
 elif name=='line':
  d.ellipse((5,5,17,17),outline=c);d.ellipse((7,7,15,15),outline=c);d.ellipse((9,9,13,13),outline=c);d.line((17,12,20,12,20,21),fill=c)
 elif name=='sonar':
  d.rectangle((3,4,21,19),outline=c,width=2);d.line((6,15,9,11,12,10,15,11,18,15),fill=c);d.line((6,7,8,7),fill=c);d.line((10,7,12,7),fill=c)
 elif name=='shop':d.rectangle((3,9,21,20),outline=c,width=2);d.line((8,9,8,5,16,5,16,9),fill=c,width=2);d.line((3,13,21,13),fill=c);d.rectangle((10,12,14,16),outline=c)
 elif name=='book':d.rectangle((3,4,21,20),outline=c);d.line((12,4,12,20),fill=c,width=2);d.line((6,8,9,8),fill=c);d.line((15,8,18,8),fill=c);d.line((6,12,9,12),fill=c);d.line((15,12,18,12),fill=c)
 elif name=='area':d.polygon([(10,3),(16,5),(18,9),(14,13),(13,18),(7,21),(6,18),(8,14),(6,10)],outline=c);d.line((19,3,19,7),fill=c);d.line((17,5,21,5),fill=c)
 elif name in ['save','anchor']:d.ellipse((9,2,15,8),outline=c);d.line((12,7,12,20),fill=c,width=2);d.line((7,11,17,11),fill=c);d.line((4,15,5,18,9,21,15,21,19,18,20,15),fill=c,width=2)
 elif name=='depth':
  d.line((8,3,8,20),fill=c);d.line((15,3,15,20,12,17),fill=c);d.line((15,20,18,17),fill=c)
  for y in [5,10,15,20]:d.line((4,y,8,y),fill=c)
 elif name=='cast':d.line((3,19,8,8,14,4,20,8),fill=c);d.rectangle((19,12,22,15),fill=c);d.line((20,8,21,11),fill=c);d.line((3,18,7,21),fill=c,width=2)
 elif name=='hook':d.line((13,3,13,16),fill=c,width=2);d.arc((6,12,14,21),0,180,fill=c,width=2);d.line((6,16,6,12,9,14),fill=c)
 elif name=='boat':d.polygon([(2,14),(21,14),(17,20),(7,20)],outline=c);d.rectangle((9,9,14,13),outline=c);d.line((5,13,5,6),fill=c);d.line((3,22,20,22),fill=c)
 im.save(out/(name+'.png'),optimize=True)
