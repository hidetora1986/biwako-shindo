import json, subprocess, re
from pathlib import Path
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
 c=b.new_context(viewport={'width':844,'height':390},has_touch=True,is_mobile=True,device_scale_factor=1)
 page=c.new_page();logs=[];page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}));page.on('pageerror',lambda e:logs.append({'type':'pageerror','text':str(e)}))
 page.goto('http://127.0.0.1:8765/');page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000)
 page.touchscreen.tap(420,345)
 cdp=c.new_cdp_session(page)
 for i in range(18):
  cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':700,'y':345,'id':5}]})
  page.wait_for_timeout(650)
  cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
  page.wait_for_timeout(250)
  if i in [6,10,14]:page.screenshot(path=f'/tmp/biwako-web-fish-{i}.png')
 page.wait_for_timeout(4000)
 print('DBS',page.evaluate('async()=>await indexedDB.databases()'))
 print('ENGINE',page.evaluate('Object.getOwnPropertyNames(Object.getPrototypeOf(engine))'))
 dump=page.evaluate('''async()=>{let rows=[]; for(const db of await indexedDB.databases()){const d=await new Promise((ok,bad)=>{let r=indexedDB.open(db.name);r.onsuccess=()=>ok(r.result);r.onerror=()=>bad(r.error)}); for(const name of d.objectStoreNames){let tx=d.transaction(name);let vals=await new Promise(ok=>{let r=tx.objectStore(name).getAll();r.onsuccess=()=>ok(r.result)});let tx2=d.transaction(name);let keys=await new Promise(ok=>{let r=tx2.objectStore(name).getAllKeys();r.onsuccess=()=>ok(r.result)});rows.push({db:db.name,store:name,keys,values:vals.map(v=>({...v,contents:v.contents?new TextDecoder().decode(v.contents):null}))});}d.close();}return rows;}''')
 print('Storage save found:',any(str(k).endswith('/save.json') for row in dump for k in row['keys']))
 print('LOGS',json.dumps(logs))
 page.screenshot(path='/tmp/biwako-web-after-catch.png')
 Path('/tmp/biwako-web-save-probe.json').write_text(json.dumps(dump,ensure_ascii=False,indent=2,default=str))
 # Browser-owned IndexedDB, produced by a real touch-only catch.
 saves=[]
 for row in dump:
  for key,value in zip(row['keys'],row['values']):
   if str(key).endswith('/biwako-shindo/save.json'):
    saves.append((row['db'],row['store'],key,json.loads(value['contents'])))
 assert len(saves)==1 and saves[0][3]['money']>0 and sum(saves[0][3]['fish_caught_count'].values())>=1
 original=json.loads(json.dumps(saves[0][3]))
 page.reload();page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000);page.wait_for_timeout(1000)
 page.screenshot(path='/tmp/biwako-web-reloaded.png')
 restored_text=subprocess.check_output(['tesseract','/tmp/biwako-web-reloaded.png','stdout','--psm','6'],stderr=subprocess.DEVNULL,text=True)
 assert str(original['money']) in re.sub(r'[^0-9]','',restored_text),restored_text
 # A local storage fixture tests equipment / ending compatibility. No gameplay/debug UI changes.
 db,store,key,fixture=saves[0]
 fixture.update(money=43210,rod_level=5,reel_level=5,line_level=5,sonar_level=5,returned_unknown_a=True,returned_unknown_b=True,night_unlocked=True,hull_knock_count=3,zero_depth_contact_seen=True,boss15_defeated=True,main_ending_seen=True,hidden_cut_ending_seen=True,anomaly_seen=True)
 fixture['fish_discovered']={f'No.{i:02}':True for i in range(1,16)}
 fixture['fish_caught_count']={f'No.{i:02}':1 for i in range(1,16)}
 page.evaluate("async ({db,store,key,text})=>{const d=await new Promise(ok=>{let r=indexedDB.open(db);r.onsuccess=()=>ok(r.result)});const tx=d.transaction(store,'readwrite');const s=tx.objectStore(store);const old=await new Promise(ok=>{let r=s.get(key);r.onsuccess=()=>ok(r.result)});old.contents=new TextEncoder().encode(text);old.timestamp=new Date();s.put(old,key);await new Promise((ok,bad)=>{tx.oncomplete=ok;tx.onerror=()=>bad(tx.error)});d.close();}",{'db':db,'store':store,'key':key,'text':json.dumps(fixture)})
 page.reload();page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000);page.wait_for_timeout(1000)
 page.screenshot(path='/tmp/biwako-web-fixture-title.png')
 title_text=subprocess.check_output(['tesseract','/tmp/biwako-web-fixture-title.png','stdout','--psm','6'],stderr=subprocess.DEVNULL,text=True)
 assert 'CONTINUE' in title_text,title_text
 page.touchscreen.tap(422,262);page.wait_for_timeout(500)
 page.touchscreen.tap(136,96);page.wait_for_timeout(250)
 page.screenshot(path='/tmp/biwako-web-shop.png')
 shop_text=subprocess.check_output(['tesseract','/tmp/biwako-web-shop.png','stdout','--psm','6'],stderr=subprocess.DEVNULL,text=True)
 assert 'EQUIPMENT SHOP' in shop_text and all(category+' Lv.5 MAX' in shop_text for category in ['ROD','REEL','LINE','SONAR']),shop_text
 assert '43210' in re.sub(r'[^0-9]','',shop_text),shop_text
 page.touchscreen.tap(679,50);page.wait_for_timeout(250)
 page.touchscreen.tap(275,96);page.wait_for_timeout(250)
 page.screenshot(path='/tmp/biwako-web-book.png')
 book_text=subprocess.check_output(['tesseract','/tmp/biwako-web-book.png','stdout','--psm','6'],stderr=subprocess.DEVNULL,text=True)
 assert re.search(r'15\s*/\s*15',book_text),book_text
 page.touchscreen.tap(679,50);page.wait_for_timeout(250)
 for width,height in [(640,360),(844,390),(800,360)]:
  page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(500)
  fit=page.evaluate('({rect:canvas.getBoundingClientRect().toJSON(),width:innerWidth,height:innerHeight,isolated:crossOriginIsolated,scrollX,scrollY})')
  assert fit['rect']['width']<=width and fit['rect']['height']<=height and not fit['isolated'] and fit['scrollX']==0 and fit['scrollY']==0
  page.screenshot(path=f'/tmp/biwako-web-{width}x{height}.png')
  resized_text=subprocess.check_output(['tesseract',f'/tmp/biwako-web-{width}x{height}.png','stdout','--psm','6'],stderr=subprocess.DEVNULL,text=True)
  assert 'NIGHT' in resized_text,resized_text
 page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(200)
 assert page.locator('#orientation').is_visible()
 # Read disk again: reload must not erase any fields in the existing v1 schema.
 assert page.evaluate('async ({db,store,key})=>{let d=await new Promise(ok=>{let r=indexedDB.open(db);r.onsuccess=()=>ok(r.result)});let v=await new Promise(ok=>{let r=d.transaction(store).objectStore(store).get(key);r.onsuccess=()=>ok(r.result)});d.close();return JSON.parse(new TextDecoder().decode(v.contents));}',{'db':db,'store':store,'key':key})==fixture
 errors=[e for e in logs if e['type'] in ['error','pageerror']]
 assert not errors,errors
 result={'result':'PASS','browser':'Chromium touch emulation','single_thread':True,'cross_origin_isolated':False,'real_touch_catch_money':original['money'],'reload_save':True,'shop_touch':True,'book_touch':True,'continue_touch':True,'saved_equipment_and_flags_fixture':True,'ratios':['16:9','19.5:9','20:9'],'portrait_hint':True,'web_only_postgame_relayout':True,'errors':errors,'physical_safari':'NOT TESTED','physical_chrome':'NOT TESTED'}
 Path('/tmp/biwako-web-browser-results.json').write_text(json.dumps(result,indent=2))
 print('WEB_BROWSER_ACCEPTANCE',json.dumps(result))
 b.close()
