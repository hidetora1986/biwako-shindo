"""Isolated existing boss_test=15 fixture; actual Web render and touch input, no production save."""
import json, subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright
OUT=Path('/tmp/boss-visual-web');OUT.mkdir(exist_ok=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
 c=b.new_context(viewport={'width':640,'height':360},has_touch=True,is_mobile=True)
 page=c.new_page();errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto('http://127.0.0.1:8765/?boss_test=15');page.locator('#start').tap()
 page.wait_for_function("!document.getElementById('start-screen')",timeout=90000)
 page.wait_for_timeout(300);page.touchscreen.tap(570,38);page.wait_for_timeout(500)
 page.screenshot(path=str(OUT/'01_before_cast.png'))
 def until(word):
  for _ in range(180):
   f=OUT/'probe.png';page.screenshot(path=str(f),clip={'x':472,'y':272,'width':152,'height':72})
   text=subprocess.check_output(['tesseract',str(f),'stdout','--psm','6'],text=True,stderr=subprocess.DEVNULL)
   if word in text:return
   page.wait_for_timeout(100)
  raise AssertionError('Primary never showed '+word)
 until('CAST');page.touchscreen.tap(548,308);until('HOOK');page.screenshot(path=str(OUT/'02_hook_16x9.png'))
 page.touchscreen.tap(548,308);until('REEL')
 for name,w in [('03_fight_16x9',640),('04_fight_19_5x9',780),('05_fight_20x9',800)]:
  page.set_viewport_size({'width':w,'height':360});page.wait_for_timeout(120);page.screenshot(path=str(OUT/(name+'.png')))
  size=page.evaluate('({w:canvas.getBoundingClientRect().width,h:canvas.getBoundingClientRect().height})');assert size['w']<=w and size['h']<=360
 page.set_viewport_size({'width':640,'height':360});page.wait_for_timeout(120)
 cdp=c.new_cdp_session(page);cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':548,'y':308,'id':5}]})
 page.wait_for_timeout(600);page.screenshot(path=str(OUT/'06_reel_held.png'));cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(200)
 assert not errors,errors
 result={'result':'PASS','real_web_cast_hook_reel':True,'aspect_ratios':['16:9 / 640x360','19.5:9','20:9'],'fixture':'Existing isolated boss_test=15, no normal save access','errors':errors,'quality_and_phone':'MANUAL REVIEW REQUIRED'}
 (OUT/'results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));b.close()
