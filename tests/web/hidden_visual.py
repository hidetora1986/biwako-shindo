"""Local debug-only capture project; production entry point/preset are never modified."""
import json
from pathlib import Path
from playwright.sync_api import sync_playwright
OUT=Path('/tmp/hidden-visual-web');OUT.mkdir(exist_ok=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
 c=b.new_context(viewport={'width':640,'height':360},has_touch=True,is_mobile=True)
 page=c.new_page();errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 def start(stage):
  page.goto('http://127.0.0.1:8767/?qa_stage='+stage);page.locator('#start').tap()
  page.wait_for_function('window.no00VisualReady===true',timeout=90000)
  page.wait_for_timeout(80)
 start('CONTACT');page.screenshot(path=str(OUT/'01_contact.png'))
 start('FIGHT')
 for name,w in [('02_fight_16x9',640),('03_fight_19_5x9',780),('04_fight_20x9',800)]:
  page.set_viewport_size({'width':w,'height':360});page.wait_for_timeout(80);page.screenshot(path=str(OUT/(name+'.png')))
  box=page.evaluate('({w:canvas.getBoundingClientRect().width,h:canvas.getBoundingClientRect().height})');assert box['w']<=w and box['h']<=360
 page.set_viewport_size({'width':640,'height':360});page.wait_for_timeout(100)
 cdp=c.new_cdp_session(page)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':552,'y':308,'id':8}]});page.wait_for_timeout(120)
 assert page.evaluate('window.no00Reeling===true')
 page.screenshot(path=str(OUT/'05_reel_held.png'))
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(120);assert page.evaluate('window.no00Reeling===false')
 start('CHOICE');page.screenshot(path=str(OUT/'06_final_choice.png'))
 assert not errors,errors
 result={'result':'PASS','debug_capture_only':True,'hidden_reel_hold_release':True,'ratios':['16:9 / 640x360','19.5:9','20:9'],'errors':errors,'art':'MANUAL REVIEW REQUIRED'}
 (OUT/'results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));b.close()
