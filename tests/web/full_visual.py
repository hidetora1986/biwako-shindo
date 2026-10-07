"""Full screenshot matrix in an isolated local debug build. Art quality remains manual."""
from playwright.sync_api import sync_playwright
from pathlib import Path
import json,time,statistics
OUT=Path(__file__).resolve().parents[2]/'docs/visual-v2/full';OUT.mkdir(exist_ok=True)
MATRIX=[('01_title','title'),('02_opening_room','story_opening_0'),('03_opening_journal','story_opening_1'),('04_south_morning','south_morning'),('05_south_sunset','south_sunset'),('06_north_shore','north_shore'),('07_north_night','north_night'),('08_north_center','north_center'),*[(f'{i:02}_depth_{d}',f'depth_{d}') for i,d in enumerate([15,30,50,65,85,100,120],9)],('16_shop','shop'),('17_fish_book','book'),('18_journal','journal'),('19_area_map','map'),('20_catch','catch'),('21_no10_choice','no10_choice'),('22_no14_choice','no14_choice'),('23_no15','boss'),('24_main_ending','story_main_2'),('25_mysterious_sketch','story_main_3'),('26_hidden_104','hidden_104'),('27_hidden_121','hidden_121'),('28_no00_contact','hidden_contact'),('29_no00_fight','hidden_fight'),('30_hidden_choice','hidden_choice'),('31_contact_ending','story_contact_0'),('32_cut_ending','story_cut_2'),('33_credits','credits')]
results=[]
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
 for name,view in MATRIX:
  c=b.new_context(viewport={'width':1280,'height':720},has_touch=True,is_mobile=True);page=c.new_page();errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  started=time.monotonic();page.goto('http://127.0.0.1:8768/?view='+view);page.locator('#start').tap();page.wait_for_function('window.fullVisualReady===true',timeout=90000);cold=time.monotonic()-started
  page.wait_for_timeout(300);page.screenshot(path=str(OUT/(name+'.png')))
  if view in ['south_morning','north_night','shop','book','map','hidden_choice','hidden_fight','story_contact_0']:
   for aspect,w in [('19_5x9',780),('20x9',800),('640x360',640)]:
    page.set_viewport_size({'width':w,'height':360});page.wait_for_timeout(250);page.screenshot(path=str(OUT/(name+'_'+aspect+'.png')))
    box=page.evaluate('({w:canvas.getBoundingClientRect().width,h:canvas.getBoundingClientRect().height})');assert box['w']<=w and box['h']<=360
  result={'screen':name,'fixture':view,'cold_seconds':round(cold,3),'errors':errors};results.append(result);print(name,'PASS' if not errors else 'FAIL',errors,flush=True);c.close()
 b.close()
Path('/tmp/full-visual-web-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));assert not any(x['errors'] for x in results)
