import json,subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
 c=b.new_context(viewport={'width':844,'height':390},has_touch=True,is_mobile=True)
 page=c.new_page();logs=[];page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}));page.on('pageerror',lambda e:logs.append({'type':'pageerror','text':str(e)}))
 def snap(name):
  path='/tmp/feedback-web-'+name+'.png';page.screenshot(path=path)
  return subprocess.check_output(['tesseract',path,'stdout','--psm','6'],text=True,stderr=subprocess.DEVNULL)
 def start():
  page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000);page.wait_for_timeout(300)
 def save_text(suffix):
  return page.evaluate("""async suffix=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const keys=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').getAllKeys();r.onsuccess=()=>ok(r.result);});const key=keys.find(k=>String(k).endsWith(suffix));if(!key){d.close();return null;}const v=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').get(key);r.onsuccess=()=>ok(r.result);});d.close();return new TextDecoder().decode(v.contents);}""",suffix)
 page.goto('http://127.0.0.1:8765/');start()
 page.touchscreen.tap(136,145);page.wait_for_timeout(400);page.touchscreen.tap(250,345)
 page.wait_for_function('window.biwakoSaveConfirmed === true',timeout=15000)
 normal=save_text('/biwako-shindo/save.json');assert normal
 page.goto('http://127.0.0.1:8765/?boss_test=15');assert '湖底の主' in page.locator('#start').inner_text();start()
 assert 'ABYSS' in snap('boss-ready')
 page.touchscreen.tap(700,342)
 def until_button(word,limit=180):
  for i in range(limit):
   path='/tmp/bossweb-primary.png';page.screenshot(path=path,clip={'x':600,'y':295,'width':180,'height':80})
   text=subprocess.check_output(['tesseract',path,'stdout','--psm','6'],text=True,stderr=subprocess.DEVNULL)
   if word in text:return
   page.wait_for_timeout(100)
  raise AssertionError('Primary button never showed '+word)
 until_button('HOOK');page.touchscreen.tap(700,342);until_button('REEL')
 snap('boss-fight')
 cdp=c.new_cdp_session(page)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':700,'y':342,'id':5}]});page.wait_for_timeout(700)
 snap('boss-reel-held');cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(500)
 assert save_text('/biwako-shindo/save.json')==normal
 data=json.loads(save_text('/web-boss-playtest/no15/save.json'))
 assert data['rod_level']==data['reel_level']==data['line_level']==data['sonar_level']==5 and not data['boss15_defeated']
 page.goto('http://127.0.0.1:8765/');start();assert 'ABYSS' not in snap('back-normal')
 assert save_text('/biwako-shindo/save.json')==normal
 errors=[m for m in logs if m['type'] in ['error','pageerror']];assert not errors,errors
 print(json.dumps({'boss_web':'PASS','real_cast_hook_reel':True,'normal_save_unchanged':True,'return_normal':True,'errors':errors}));b.close()
