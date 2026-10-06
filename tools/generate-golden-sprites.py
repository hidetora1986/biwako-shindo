"""Original pixel sprites for Golden Screen 01. Offline only; Pillow required.
No external assets or gameplay data; fixed decorative seed.
"""
from pathlib import Path
import math, random
from PIL import Image, ImageDraw
OUT=Path(__file__).resolve().parents[1]/'assets/visual/golden/south_shore'
OUT.mkdir(parents=True,exist_ok=True)
def save(im,path):im.save(OUT/path)
def poly(d,pts,c):d.polygon(pts,fill=c)
# Boat maintains the original 154x64 texture envelope and gameplay rod anchor.
im=Image.new('RGBA',(154,64));d=ImageDraw.Draw(im)
poly(d,[(7,49),(24,43),(111,43),(133,46),(138,51),(126,61),(24,61),(12,56)],'#617d7c')
poly(d,[(8,49),(24,44),(112,44),(132,47),(130,53),(122,58),(27,58),(14,54)],'#e8e9d4')
poly(d,[(17,51),(130,51),(124,56),(24,56)],'#283e4c')
poly(d,[(20,56),(123,56),(120,59),(28,59)],'#9fb2ac')
d.line([(15,48),(26,46),(111,46),(130,49)],fill='#fff3cf',width=2)
d.line([(28,53),(110,53)],fill='#71949a');d.line([(113,53),(120,53)],fill='#bb7857')
# Deck and bow's recessed storage seams.
poly(d,[(23,43),(111,43),(124,47),(27,47)],'#b5c8c1');d.line([(29,44),(58,44)],fill='#5d7779')
d.line([(26,46),(28,44),(40,44)],fill='#e9e8d1');d.line([(47,46),(48,44),(59,44)],fill='#e9e8d1')
# Outboard hood, propeller shaft and polished cover.
poly(d,[(131,40),(142,39),(148,43),(147,53),(137,55),(133,51)],'#2b4553')
poly(d,[(132,41),(141,40),(146,43),(140,45),(133,44)],'#667f85')
d.line([(136,42),(143,42)],fill='#a3b8b5');d.rectangle((140,53,143,61),fill='#314c56');d.line([(135,61),(146,61)],fill='#3a5862')
# Console windscreen: oblique transparent-looking cyan rather than blocks.
poly(d,[(90,28),(103,30),(108,42),(88,42)],'#486977')
poly(d,[(91,28),(101,30),(104,37),(90,37)],'#abc5c1');d.line([(91,29),(94,35)],fill='#e7eee0')
poly(d,[(86,38),(104,38),(105,44),(87,44)],'#294552');d.line([(87,39),(101,40)],fill='#79918e')
# Two upholstered seats with rounded/chamfered silhouettes.
for x in [79,112]:
 poly(d,[(x,30),(x+7,29),(x+9,31),(x+9,39),(x+2,40),(x,37)],'#304b58')
 d.line([(x+2,31),(x+6,30),(x+7,34)],fill='#a8bbb1');d.rectangle((x+2,40,x+6,44),fill='#577778')
# Angler: brim, jacket, forearm, seated knees, no recognisable face.
poly(d,[(64,23),(70,20),(76,22),(78,29),(72,35),(67,34),(64,29)],'#607f68')
poly(d,[(70,22),(74,23),(76,28),(72,29),(69,26)],'#96a384')
poly(d,[(65,27),(61,30),(53,28),(50,30),(60,34),(69,31)],'#697f66');d.rectangle((49,28,53,30),fill='#c6b797')
poly(d,[(70,34),(77,34),(81,40),(87,43),(83,45),(76,42),(70,39)],'#344e5c');d.line([(72,36),(77,36),(80,40)],fill='#758a88')
d.rectangle((69,17,75,22),fill='#b9ad88');d.line([(68,19),(66,19)],fill='#938862')
poly(d,[(65,15),(68,12),(74,12),(77,16),(78,18),(63,18)],'#b9c8ac');d.line([(66,15),(74,14)],fill='#e9e6c4');d.line([(63,18),(78,18)],fill='#536f69')
# Rail fittings, metal cleats and tiny hull glints.
for x in [29,59,117]:d.line([(x,42),(x+3,42)],fill='#f8edca');d.point((x+1,41),fill='#93aeb1')
save(im,Path('boat/boat.png'))
# Each sheet contains three original 40x22 frames, right-facing; no AI envelope change.
params={'bluegill':(24,8,['#425f53','#819574','#d2be87','#a2b28b','#c7d4a8']), 'bass':(31,6,['#3f5b4a','#8b9e74','#dacfa5','#74865c','#d4dfbd']), 'crucian':(27,7,['#637967','#b3bda0','#efe0b7','#9ca982','#f1eaca']), 'catfish':(33,4,['#4d6468','#8d9b95','#d0d6bf','#788d83','#bbcec2']), 'biwamasu':(31,4,['#3f7180','#92b8bc','#e5e6cf','#749ba1','#d2e6dc'])}
for species,(length,height,palette) in params.items():
 sheet=Image.new('RGBA',(120,22));back,body,belly,fin,shine=palette
 for phase in range(3):
  f=Image.new('RGBA',(40,22));dr=ImageDraw.Draw(f);tail=phase-1
  poly(dr,[(8,10),(1,5+tail),(2,11+tail),(1,16+tail),(9,13)],fin)
  dr.line([(2,8+tail),(8,11),(2,14+tail)],fill=back)
  if species=='biwamasu':poly(dr,[(0,9+tail),(4,11+tail),(0,13+tail)],(0,0,0,0))
  for x in range(7,min(39,7+length)):
   t=(x-7)/(length-1);r=max(1,round(math.sqrt(max(0,1-((t-.53)*2)**2))*height))
   if species=='catfish':r=max(2,round(2+2*math.sin(t*math.pi/2)))
   for y in range(11-r,12+r):
    c=back if y<11-r+2 else belly if y>=11+r-2 else body
    if y==10-r+3 and 9<x<7+length-5:c=shine
    dr.point((x,y),fill=c)
  nose=min(38,6+length)
  # Partial outline, gill and eye; not an all-black outline.
  dr.line([(nose-6,8),(nose-7,11),(nose-6,14)],fill=back)
  dr.point((nose-3,9),fill='#233f47');dr.point((nose-3,8),fill=shine)
  dr.line([(nose-1,12),(nose-3,12)],fill=back)
  poly(dr,[(13,6),(17,3 if species=='bluegill' else 5),(19,4),(21,5),(25,6),(23,8)],fin)
  dr.line([(14,7),(17,5),(20,6),(22,7)],fill=back)
  poly(dr,[(21,13),(17+tail,18),(25,16)],fin);dr.line([(21,14),(20+tail,17)],fill=shine)
  if species=='bass':dr.line([(10,11),(nose-8,11)],fill=back)
  if species=='bluegill':dr.rectangle((nose-8,9,nose-7,12),fill='#345357');dr.point((nose-9,13),fill='#c59968')
  if species=='catfish':
   dr.line([(nose-1,11),(39,8+tail)],fill=shine);dr.line([(nose-1,13),(39,16+tail)],fill=fin)
  if species=='biwamasu':
   for x in [12,16,21,25,28]:dr.point((x,9),fill=back)
  sheet.alpha_composite(f,(phase*40,0))
 save(sheet,Path('fish')/(species+'.png'))
 # Committed SpriteFrames load PNGs, never regenerate at runtime.
 lines=['[gd_resource type="SpriteFrames" load_steps=5 format=3]',f'[ext_resource type="Texture2D" path="res://assets/visual/golden/south_shore/fish/{species}.png" id="1"]']
 for n in range(3):lines += [f'[sub_resource type="AtlasTexture" id="Frame{n}"]','atlas = ExtResource("1")',f'region = Rect2({n*40}, 0, 40, 22)','filter_clip = true']
 lines += ['[resource]','animations = [{"frames": ['+','.join('{"duration":1.0,"texture":SubResource("Frame%d")}'%n for n in range(3))+'], "loop":true, "name": &"swim", "speed":4.0}]']
 (OUT/'fish'/(species+'.tres')).write_text('\n\n'.join(lines)+'\n')
# Lightweight reusable raster instrumentation and wave assets.
def plate(w,h,fill,edge):
 im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im)
 poly(d,[(4,0),(w-5,0),(w-1,4),(w-1,h-5),(w-5,h-1),(4,h-1),(0,h-5),(0,4)],fill)
 d.line([(4,0),(w-5,0),(w-1,4),(w-1,h-5),(w-5,h-1),(4,h-1),(0,h-5),(0,4),(4,0)],fill=edge)
 d.line([(5,2),(w-6,2)],fill='#b9d2c1');return im
for name,fill,edge in [('primary-normal','#d0e2cf','#718c80'),('primary-pressed','#adcab9','#d5e9d1'),('primary-disabled','#385451','#607d73')]:
 im=Image.new('RGBA',(144,64));d=ImageDraw.Draw(im)
 poly(d,[(12,2),(131,2),(141,12),(141,49),(130,60),(13,60),(3,50),(3,13)],'#203e45')
 poly(d,[(13,3),(130,3),(139,13),(139,47),(128,57),(15,57),(5,47),(5,14)],fill)
 d.line([(14,5),(128,5),(136,13)],fill=edge,width=2)
 d.line([(16,55),(127,55),(136,46)],fill='#6c8a7d',width=2)
 d.line([(17,7),(36,7)],fill='#e6d28b',width=1)
 save(im,Path('hud')/(name+'.png'))
im=plate(156,104,'#0d202c','#507477');d=ImageDraw.Draw(im);d.rectangle((5,27,150,98),fill='#102a35');d.line([(6,25),(149,25)],fill='#36595c');save(im,Path('hud/sonar-frame.png'))
im=Image.new('RGBA',(128,6));d=ImageDraw.Draw(im);rng=random.Random(1908)
for i in range(20):
 x=rng.randrange(128);y=rng.choice([1,2,3]);d.line([(x,y),(min(127,x+rng.randrange(2,12)),y)],fill=rng.choice(['#d0e4d1','#abcfc5','#789f9d']))
save(im,Path('water/waterline.png'))
im=Image.new('RGBA',(64,24));d=ImageDraw.Draw(im)
for pts,c in [([(5,9),(18,9)],'#b9d8ce'), ([(29,17),(53,17)],'#89bbb6'), ([(33,3),(41,3)],'#d6e3c5')]:d.line(pts,fill=c)
save(im,Path('water/glitter.png'))
im=Image.new('RGBA',(3,2));d=ImageDraw.Draw(im);d.point((1,0),fill=(207,223,199,85));d.point((2,0),fill=(183,218,203,50));save(im,Path('water/mote.png'))
print('Golden boat / five three-frame fish / HUD / water PNGs created')
