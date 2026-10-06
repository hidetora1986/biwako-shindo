"""Isolated Chromium-touch QA. Export current branch and base to ports 8765/8766.
Artifacts /tmp/golden-web-final. Human aesthetics/physical devices are not automatic PASS.
"""
import json,time,subprocess,os,statistics
from pathlib import Path
from playwright.sync_api import sync_playwright
OUT=Path('/tmp/golden-web-final');OUT.mkdir(exist_ok=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
 def start(page,port):
  at=time.monotonic();page.goto(f'http://127.0.0.1:{port}/');page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000)
  cold=time.monotonic()-at;page.wait_for_timeout(200);page.touchscreen.tap(570,38);page.wait_for_timeout(600);return cold
 def read(page):
  return page.evaluate('''async()=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const keys=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').getAllKeys();r.onsuccess=()=>ok(r.result);});const key=keys.find(k=>String(k).endsWith('/biwako-shindo/save.json'));if(!key){d.close();return null;}const v=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').get(key);r.onsuccess=()=>ok(r.result);});d.close();return JSON.parse(new TextDecoder().decode(v.contents));}''')
 def frames(page):
  return page.evaluate('''async()=>{const times=[];let last=performance.now();await new Promise(ok=>{const began=last;function next(now){times.push(now-last);last=now;if(now-began<3000)requestAnimationFrame(next);else ok();}requestAnimationFrame(next);});times.shift();times.sort((a,b)=>a-b);return {frames:times.length,median_ms:times[Math.floor(times.length/2)],p95_ms:times[Math.floor(times.length*.95)]};}''')
 baseline=b.new_context(viewport={'width':640,'height':360},has_touch=True,is_mobile=True);old=baseline.new_page();base_cold=start(old,8766);old.screenshot(path=str(OUT/'00_before_16x9.png'));base_frame=frames(old);baseline.close()
 context=b.new_context(viewport={'width':640,'height':360},has_touch=True,is_mobile=True);page=context.new_page();errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 cold=start(page,8765);frame=frames(page)
 for name,w,h in [('01_ready_16x9',640,360),('02_ready_19_5x9',780,360),('03_ready_20x9',800,360)]:
  page.set_viewport_size({'width':w,'height':h});page.wait_for_timeout(250);page.screenshot(path=str(OUT/(name+'.png')))
  fit=page.evaluate('({r:canvas.getBoundingClientRect().toJSON(),w:innerWidth,h:innerHeight,scrollX,scrollY})');assert fit['r']['width']<=fit['w'] and fit['r']['height']<=fit['h'] and fit['scrollX']==fit['scrollY']==0
 page.set_viewport_size({'width':640,'height':360});page.wait_for_timeout(200)
 def snap(name):page.screenshot(path=str(OUT/(name+'.png')))
 def ocr_button():
  path=OUT/'primary-probe.png';page.screenshot(path=str(path),clip={'x':478,'y':278,'width':148,'height':68})
  return subprocess.check_output(['tesseract',str(path),'stdout','--psm','6'],text=True,stderr=subprocess.DEVNULL)
 def until_button(word):
  for _ in range(100):
   if word in ocr_button():return
   page.wait_for_timeout(80)
  raise AssertionError('Primary never showed '+word)
 # Existing controls, modal and durable manual save. No fixture/progress cheats.
 page.touchscreen.tap(42,82);page.wait_for_timeout(200);snap('08_shop');page.touchscreen.tap(560,45);page.wait_for_timeout(200)
 page.touchscreen.tap(100,82);page.wait_for_timeout(200);snap('09_book');page.touchscreen.tap(560,45);page.wait_for_timeout(200)
 page.touchscreen.tap(158,82);page.wait_for_timeout(350);snap('10_area');page.touchscreen.tap(160,318)
 page.wait_for_function('window.biwakoSaveConfirmed === true',timeout=15000);page.touchscreen.tap(560,45);page.wait_for_timeout(250)
 assert read(page)['opening_seen'] and read(page)['money']==0
 page.touchscreen.tap(430,193);page.wait_for_timeout(100);page.touchscreen.tap(552,314);page.wait_for_timeout(150);snap('04_cast')
 until_button('HOOK');snap('05_hook');page.touchscreen.tap(552,314);until_button('REEL');snap('06_reel')
 cdp=context.new_cdp_session(page)
 for _ in range(24):
  cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':552,'y':314,'id':5}]});page.wait_for_timeout(550)
  cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(250)
  if read(page)['money']>0:break
 assert read(page)['money']>0;page.wait_for_timeout(1800);snap('07_sonar')
 money=read(page)['money'];page.reload();page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000);page.wait_for_timeout(400)
 assert read(page)['money']==money and read(page)['opening_seen'];until_button('CAST')
 # Compare real browser scheduling intervals, not a claim about physical mobile FPS.
 sizes={'before_pck_bytes':os.stat('/tmp/golden-baseline/build/web/index.pck').st_size,'after_pck_bytes':os.stat('build/web/index.pck').st_size}
 result={'result':'PASS','fishing_hook_reel_catch_sale_reload':True,'shop_book_area_touch':True,'area_save_indexeddb':True,'ratios':['16:9 / 640x360','19.5:9 / 780x360','20:9 / 800x360'],'errors':errors,'performance':{'before_cold_seconds':round(base_cold,2),'after_cold_seconds':round(cold,2),'before_frame_scheduling':base_frame,'after_frame_scheduling':frame,**sizes},'physical_mobile_and_art':'MANUAL REVIEW REQUIRED'}
 assert not errors,errors
 (OUT/'results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));b.close()
