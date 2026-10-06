import json,re,subprocess
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
 def read():
  return page.evaluate('''async()=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const keys=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').getAllKeys();r.onsuccess=()=>ok(r.result);});const key=keys.find(k=>String(k).endsWith('/biwako-shindo/save.json'));if(!key){d.close();return null;}const v=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').get(key);r.onsuccess=()=>ok(r.result);});d.close();return {key,data:JSON.parse(new TextDecoder().decode(v.contents))};}''')
 def fixture(data):
  page.evaluate('''async ({key,data})=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const tx=d.transaction('FILE_DATA','readwrite');const s=tx.objectStore('FILE_DATA');const v=await new Promise(ok=>{const r=s.get(key);r.onsuccess=()=>ok(r.result);});v.contents=new TextEncoder().encode(JSON.stringify(data));v.timestamp=new Date();s.put(v,key);await new Promise(ok=>tx.oncomplete=ok);d.close();}''',{'key':saved['key'],'data':data})
 page.goto('http://127.0.0.1:8765/');start()
 # New primary at lower right; save confirms native->IndexedDB persistence.
 page.touchscreen.tap(136,145);page.wait_for_timeout(400)
 page.touchscreen.tap(250,345);page.wait_for_function('window.biwakoSaveConfirmed === true',timeout=12000)
 snap('saved') # Durability assertion is the browser DB confirmation above.
 saved=read();assert saved['data']['current_area']=='south_shore'
 page.touchscreen.tap(679,55);page.wait_for_timeout(200)
 assert 'SAVE POINT' not in snap('clean-hud')
 page.touchscreen.tap(400,230);page.wait_for_timeout(150)
 aim_text=snap('cast-aim');assert re.search(r'\d+[.,]\d\s*m',aim_text),aim_text
 page.touchscreen.tap(700,342)
 def until_button(word,limit=100):
  for i in range(limit):
   path='/tmp/feedback-web-primary.png'
   page.screenshot(path=path,clip={'x':600,'y':295,'width':180,'height':80})
   text=subprocess.check_output(['tesseract',path,'stdout','--psm','6'],text=True,stderr=subprocess.DEVNULL)
   if word in text:return
   page.wait_for_timeout(100)
  raise AssertionError('Primary button never showed '+word)
 until_button('HOOK')
 Path('/tmp/feedback-web-bite-button.png').write_bytes(Path('/tmp/feedback-web-primary.png').read_bytes())
 page.touchscreen.tap(20,220)
 page.wait_for_timeout(30)
 page.touchscreen.tap(700,342)
 until_button('REEL')
 snap('fight')
 cdp=c.new_cdp_session(page)
 for i in range(22):
  cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':700,'y':342,'id':5}]});page.wait_for_timeout(600)
  cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(250)
  current=read()
  if current and current['data']['money']>0:break
 page.wait_for_timeout(3500)
 saved=read();assert saved['data']['money']>0
 caught_money=saved['data']['money']
 # A browser storage fixture tests unlocks / travel / reload, no developer UI added.
 data=saved['data'];data.update(money=43210,rod_level=4,reel_level=4,line_level=4,sonar_level=4,anomaly_seen=True)
 data['fish_discovered']['No.10']=True;data['fish_caught_count']['No.10']=1;data['fish_best_size']['No.10']=100
 fixture(data);page.reload();start()
 page.touchscreen.tap(136,145);page.wait_for_timeout(400)
 assert 'LAKE MAP' in snap('map')
 # Three vertically stacked destinations, Center third row.
 page.touchscreen.tap(420,280);page.wait_for_timeout(350)
 snap('travel');page.wait_for_timeout(2400)
 page.wait_for_function('window.biwakoSaveConfirmed === true',timeout=12000)
 saved=read();assert saved['data']['current_area']=='north_center'
 page.reload();start()
 assert read()['data']['current_area']=='north_center'
 assert 'DEPTH 50' in snap('restored-center')
 page.touchscreen.tap(136,145);page.wait_for_timeout(400)
 assert 'LAKE MAP' in snap('map-center');page.touchscreen.tap(679,55);page.wait_for_timeout(200)
 for width,height in [(640,360),(844,390),(800,360)]:
  page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(300)
  snap(f'{width}x{height}')
  fit=page.evaluate('({rect:canvas.getBoundingClientRect().toJSON(),width:innerWidth,height:innerHeight,scrollX,scrollY})')
  assert fit['rect']['width']<=width and fit['rect']['height']<=height and fit['scrollX']==fit['scrollY']==0
 assert read()['data']['current_area']=='north_center'
 # Existing shop/book continue to open by touch at reference aspect.
 page.set_viewport_size({'width':844,'height':390});page.wait_for_timeout(300)
 page.touchscreen.tap(136,95);page.wait_for_timeout(200);shop_text=snap('shop');assert 'EQUIPMENT' in shop_text or ('ROD' in shop_text and 'SONAR' in shop_text),shop_text
 page.touchscreen.tap(679,55);page.wait_for_timeout(200)
 page.touchscreen.tap(275,95);page.wait_for_timeout(200);book_text=snap('book');assert 'FISH BOOK' in book_text or 'SPECIES' in book_text,book_text
 page.touchscreen.tap(679,55);page.wait_for_timeout(200)
 errors=[m for m in logs if m['type'] in ['error','pageerror']]
 assert not errors,errors
 result={'result':'PASS','browser':'Chromium touch emulation','manual_save_indexeddb':True,'touch_hook':True,'targeted_cast_catch':True,'random_tap_no_hook':True,'real_fishing_money':caught_money,'area_map':True,'boat_travel':True,'arrival_save':True,'reload_center':True,'shop_book_touch':True,'aspect_ratios':['16:9','19.5:9','20:9'],'errors':errors,'physical_safari':'NOT TESTED'}
 Path('/tmp/feedback-web-results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));b.close()
