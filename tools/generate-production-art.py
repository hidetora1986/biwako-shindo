#!/usr/bin/env python3
"""Original offline raster art. No network, runtime generation, or game RNG."""
from PIL import Image,ImageDraw
from pathlib import Path
import random,math,json
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets/visual/v2'; manifest=[]
def save(im,path,purpose,area='all',depth='all'):
 p=OUT/path;p.parent.mkdir(parents=True,exist_ok=True);im.save(p,optimize=True)
 manifest.append([str(p.relative_to(ROOT)),purpose,'Original code-authored',area,depth,f'{im.width}×{im.height}'])
def rgb(s):return tuple(bytes.fromhex(s))
def mix(a,b,t):return tuple(int(x*(1-t)+y*t) for x,y in zip(a,b))
def gradient(im,a,b):
 d=ImageDraw.Draw(im)
 for y in range(im.height):d.line((0,y,im.width,y),fill=mix(rgb(a),rgb(b),y/max(1,im.height-1)))
PALETTES={'morning':('9cc8d2','f0e0b0','9cb6af','708f88','3f665b','548f92'),'day':('85bfdb','cde7dc','9bb9bb','648c8c','38695f','4e969f'),'sunset':('718d9e','e8bc8b','87938f','576f75','344e51','4c777c'),'night':('061c2d','153743','284855','183541','0e2833','163e4b')}
for area in ['south_shore','north_shore','north_center']:
 for time,pal in PALETTES.items():
  rng=random.Random(131+len(area)*7);sky=Image.new('RGB',(640,136));gradient(sky,*pal[:2]);d=ImageDraw.Draw(sky)
  if time=='night':
   for n in range(62):x=rng.randrange(640);y=rng.randrange(3,77);d.point((x,y),fill=' '+pal[1] if False else '#567784')
   d.ellipse((176,18,186,28),fill='#d9e3c9');d.rectangle((180,19,182,21),fill='#b7d4d1')
  elif time!='sunset':d.ellipse((174,20,184,30),fill='#f2e5b9')
  for x,y,w in [(28,35,92),(252,22,105),(435,42,127),(112,54,67)]:
   for i in range(4):d.rectangle((x+i*9,y+i*2,x+w-i*11,y+i*2+1),fill=mix(rgb(pal[0]),rgb(pal[1]),.35+i*.08))
  save(sky,Path('environment')/area/time/'sky.png','Sky / light / thin clouds',area)
  ridges=[[(0,91),(28,84),(54,87),(91,65),(109,70),(128,63),(168,82),(214,92),(251,84),(297,78),(320,87),(358,70),(384,73),(413,61),(429,66),(455,78),(491,82),(519,68),(552,72),(578,90),(609,85),(640,92)],[(0,101),(36,97),(67,78),(90,83),(107,94),(134,87),(160,99),(208,105),(248,91),(290,98),(315,106),(352,92),(386,101),(418,85),(454,91),(478,79),(519,93),(561,97),(603,87),(640,99)]]
  for k,points in enumerate(ridges):
   im=Image.new('RGBA',(640,136));d=ImageDraw.Draw(im)
   if area!='south_shore':points=[(x,int(y-(12 if area=='north_shore' else -5)*(1-k*.3))) for x,y in points]
   d.polygon(points+[(640,114),(0,114)],fill=rgb(pal[2+k])+(255,))
   for x,y in points[1:-1]:d.line((x,y+2,x-17,y+12,x-27,111),fill=mix(rgb(pal[2+k]),rgb(pal[0]),.10)+(255,),width=1)
   save(im,Path('environment')/area/time/('far.png' if k==0 else 'middle.png'),'Independent atmospheric ridge',area)
  im=Image.new('RGBA',(640,136));d=ImageDraw.Draw(im)
  if area!='north_center':
   base=107 if area=='south_shore' else 110
   for x in range(640):
    y=base+rng.randrange(-2,2);d.line((x,y,x,113),fill='#'+pal[4])
    if rng.random()<.33:
     h=rng.randrange(2,7) if area=='south_shore' else rng.randrange(1,4);d.polygon([(x-2,y),(x,y-h),(x+2,y)],fill='#'+pal[4])
   if area=='south_shore':
    for x in [48,61,185,202,511,534]:d.rectangle((x,107,x+5,110),fill='#a6afa0' if time!='night' else '#384746');d.point((x+2,109),fill='#e6cf97')
    d.line((74,112,107,112),fill='#30494d');d.line((78,111,78,115),fill='#30494d')
  save(im,Path('environment')/area/time/'shore.png','Distant shore / isolation',area)
  im=Image.new('RGBA',(640,136));d=ImageDraw.Draw(im);d.rectangle((0,114,640,136),fill='#'+pal[5])
  for n in range(430):
   x=rng.randrange(640);y=rng.randrange(115,136);w=rng.randrange(2,17);c=mix(rgb(pal[5]),rgb(pal[1] if n%3==0 else pal[3]),rng.uniform(.2,.5));d.line((x,y,x+w,y),fill=c+(255,))
  for y in range(115,136,2):
   w=rng.randrange(2,12);d.line((180-w,y,181+w,y),fill=rgb('c4d8c8' if time!='night' else 'aac8c6')+(160,))
  save(im,Path('environment')/area/time/'surface.png','Broken sky / mountain / celestial reflections',area)
DEPTH=[('shallow','3c8b91','24545f'),('mid','327f88','214f61'),('lower_mid','296777','1c4355'),('deep','204f64','133446'),('cold','183c52','0e263a'),('dark','102d40','0a1c2c'),('abyss','0c2334','071723')]
for index,(name,a,b) in enumerate(DEPTH):
 rng=random.Random(764+index);im=Image.new('RGB',(640,224));gradient(im,a,b);d=ImageDraw.Draw(im)
 # Narrow, broken light shafts with depth attenuation; baked, not a full-screen shader.
 if index<4:
  for x in [72,193,334,471,562]:
   for y in range(0,160-index*35,3):
    c=mix(rgb(a),rgb('86bbba'),(.12-.025*index)*(1-y/200));d.line((x+y//9,y,x+y//9+4+y//24,y),fill=c)
 for n in range(30+index*5):x=rng.randrange(640);y=rng.randrange(210);d.point((x,y),fill=mix(rgb(a),rgb('9fb5ad'),.24))
 # Shallow bed: foreground-heavy arrangement keeps the middle fishing lane open.
 for x in range(640):
  y=200+int(4*math.sin(x*.013))+rng.randrange(0,2);d.line((x,y,x,224),fill=mix(rgb(b),rgb('435d50'),max(.02,.42-index*.06)))
 for n in range(300 if index<3 else 80):
  x=rng.randrange(640);y=rng.randrange(204,224);w=rng.randrange(1,5);d.line((x,y,x+w,y),fill=mix(rgb(b),rgb('82927b'),.15 if index>2 else .3))
 for x in [20,68,117,503,561,610]:
  h=rng.randrange(3,8);y=206+rng.randrange(10);d.polygon([(x-6,y),(x-4,y-h),(x+4,y-h+2),(x+7,y),(x+2,y+2)],fill=mix(rgb(b),rgb('799188'),.28));d.line((x-4,y-h,x+3,y-h+1),fill=mix(rgb(b),rgb('94ac99'),.34))
 if index<3:
  for x in [11,34,59,574,597,623]:
   for off in range(4):
    h=rng.randrange(12,32)//(index+1);d.line([(x+off*3,220),(x+off*3-2,215-h//2),(x+off*3+4,220-h)],fill=mix(rgb(b),rgb('6d927b'),.5),width=2)
 if index==0:
  d.line([(57,216),(83,210),(101,212),(140,201),(158,202)],fill='#485949',width=5);d.line([(84,210),(79,191),(85,184)],fill='#536b58',width=2);d.line([(105,210),(124,220)],fill='#536b58',width=2)
 if index==6:
  d.line((34,212,188,207,205,214),fill='#132833',width=3);d.line((171,208,177,182),fill='#132833',width=2)
 save(im,Path('depth')/name/'water.png','Depth attenuation / substrate / restrained motes',depth=name)
# Instrument frame and notebook are authored small reusable nine-slices.
for name,bg,edge in [('catalog','122e3a','6a9699'),('chart','102832','60898c'),('instrument','0d202c','668f93'),('paper','dfd2aa','9b8969'),('journal','cab791','786649')]:
 im=Image.new('RGB',(128,128),rgb(bg));d=ImageDraw.Draw(im);rng=random.Random(9)
 for n in range(500):x=rng.randrange(128);y=rng.randrange(128);d.point((x,y),fill=mix(rgb(bg),rgb(edge),.06))
 d.rectangle((1,1,126,126),outline='#'+edge);d.line((5,5,122,5),fill=mix(rgb(bg),rgb(edge),.4));d.line((5,122,122,122),fill=mix(rgb(bg),rgb(edge),.3))
 if name in ['paper','journal']:
  d.line((14,7,14,120),fill='#b39c7d');d.rectangle((98,15,115,37),outline='#aa9475')
 save(im,Path('hud')/(name+'.png'),'Reusable raster nine-slice')
icons=['money','rod','reel','line','sonar','shop','book','area','save','depth','cast','hook','boat','anchor']
for i,name in enumerate(icons):
 im=Image.new('RGBA',(24,24));d=ImageDraw.Draw(im);c='#c8e4d8'
 if name in ['book','save']:d.rectangle((5,4,19,20),outline=c,width=2);d.line((9,5,9,19),fill=c)
 elif name in ['rod','cast','hook']:d.line((5,20,17,4),fill=c,width=2);d.line((17,4,19,15),fill=c);d.arc((13,12,20,20),0,180,fill=c,width=2)
 elif name in ['sonar','reel','money']:d.ellipse((4,4,20,20),outline=c,width=2);d.line((12,7,12,17),fill=c);d.line((7,12,17,12),fill=c)
 elif name=='area':d.polygon([(11,3),(17,6),(15,12),(18,17),(10,21),(6,15),(8,9)],outline=c)
 elif name in ['boat','anchor']:d.line((12,3,12,17),fill=c,width=2);d.line((5,14,8,20,16,20,19,14),fill=c,width=2);d.line((6,9,18,9),fill=c)
 else:d.line((4,7,20,7,18,18,6,18,4,7),fill=c,width=2)
 save(im,Path('hud/icons')/(name+'.png'),'Unified original pixel icon')
# Navigation chart, distinct from the paper specimen book.
im=Image.new('RGB',(160,214),rgb('102832'));d=ImageDraw.Draw(im)
for x in range(0,160,20):d.line((x,0,x,214),fill='#173640')
for y in range(0,214,20):d.line((0,y,160,y),fill='#173640')
poly=[(91,17),(115,25),(133,49),(118,82),(115,109),(102,134),(90,150),(79,184),(64,198),(51,194),(59,176),(56,160),(69,133),(57,121),(58,93),(74,77),(65,51),(77,31)]
d.polygon(poly,fill='#2f5660',outline='#8fafad');d.line((76,180,85,126,96,65),fill='#b1c9bc',width=1)
for x,y in [(76,180),(85,126),(96,65)]:d.rectangle((x-3,y-3,x+3,y+3),fill='#d4c28c')
save(im,Path('area_map/chart.png'),'Lake Biwa boat navigation chart')
# Species sheets: native frame envelopes retained, original 3-phase tail/body art.
species={'giant_catfish':(60,26,'7d8e81','3e6266','adbaa2'),'pale_biwamasu':(60,26,'c9d3c6','869f9d','e4e5ce'),'long_eel':(88,18,'89968a','45646b','afbb9e'),'blind_isaza':(28,18,'bdc9b8','809a9c','d9dbbe'),'unknown_a':(60,26,'93a7a0','526c7a','bfccaf'),'thread_jaw':(72,32,'91a39d','456473','bfccaf'),'split_belly':(72,32,'889e99','456573','bcc7b0'),'reverse_scale':(80,32,'8d9e9e','426376','bac6b4'),'unknown_b':(96,36,'728d94','354f65','9eadab')}
for name,(w,h,body,back,belly) in species.items():
 sheet=Image.new('RGBA',(w,h*3))
 for phase in range(3):
  im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im);cy=h//2
  for x in range(5,w-6):
   u=(x-5)/(w-11);radius=max(1,int(math.sin(u*math.pi)*(h*.31)))
   if name=='long_eel':radius=max(1,int(math.sin(u*math.pi)*3))
   if name=='unknown_b':radius=max(2,int(2+12*math.exp(-((u-.77)/.22)**2)))
   bend=int(math.sin(u*math.pi*2+phase*.8)) if name=='long_eel' else 0
   y=cy+bend
   d.line((x,y-radius,x,y+radius),fill='#'+body)
   d.line((x,y-radius,x,y-radius+1),fill='#'+back)
   d.line((x,y+radius-2,x,y+radius),fill='#'+belly)
   if x%4==0:
    for sy in range(y-radius+3,y+radius-3,4):d.point((x,sy),fill=mix(rgb(body),rgb(belly),.45))
  d.polygon([(2,cy-4+phase-1),(10,cy-1),(10,cy+2),(2,cy+4+phase-1)],fill='#'+back)
  d.polygon([(w//3,cy-3),(w//2,3),(w*2//3,cy-4)],fill='#'+back)
  d.line((w-17,cy-5,w-19,cy,w-16,cy+6),fill='#'+back)
  if name!='blind_isaza':d.point((w-10,cy-2),fill='#243b48')
  if name in ['giant_catfish','thread_jaw']:
   for k in range(2):d.line((w-10,cy+2,w-7+k*2,cy+7+k*3),fill='#'+belly)
  if name=='split_belly':d.line((21,cy+6,w-17,cy+7),fill=(0,0,0,0),width=2)
  if name=='reverse_scale':
   for x in range(18,w-18,7):d.line((x+3,cy-3,x,cy,x+3,cy+3),fill='#'+belly)
  sheet.paste(im,(0,phase*h))
 category='midgame' if name in list(species)[:5] else 'lategame'
 save(sheet,Path('fish')/category/(name+'.png'),'Native envelope / three swim phases')
# Save deterministic inventory, regenerated with every offline run.
p=ROOT/'docs/visual-v2/asset-manifest.md';p.write_text('# Asset manifest\n\nAll new raster assets are original offline code-authored. Approved Golden, opening, No.15 and No.00 sources remain separately audited. Runtime does not regenerate images.\n\n| Path | Purpose | Origin | Area | Depth | Resolution |\n|---|---|---|---|---|---|\n'+''.join('| '+' | '.join(row)+' |\n' for row in manifest))
print('Generated',len(manifest),'assets')
