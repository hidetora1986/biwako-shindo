"""Opening cinematic QA against a locally exported Web build.
Serve build/web on 127.0.0.1:8765. Requires Python Playwright and Chromium.
Artifacts remain outside the repository unless explicitly copied for review.
"""
import json
import os
import time
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path(os.environ.get('BIWAKO_QA_OUT','/tmp/biwako-opening-web'))
OUT.mkdir(parents=True,exist_ok=True)
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,
        args=['--no-sandbox','--enable-unsafe-swiftshader','--use-gl=angle','--use-angle=swiftshader'])
    context=browser.new_context(viewport={'width':844,'height':390},has_touch=True,is_mobile=True)
    page=context.new_page();errors=[]
    page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
    page.on('pageerror',lambda e:errors.append(str(e)))
    def start():
        page.locator('#start').tap();page.wait_for_function("!document.getElementById('start-screen')",timeout=90000)
    def saved():
        return page.evaluate('''async()=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const keys=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').getAllKeys();r.onsuccess=()=>ok(r.result);});const key=keys.find(k=>String(k).endsWith('/biwako-shindo/save.json'));if(!key){d.close();return null;}const v=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').get(key);r.onsuccess=()=>ok(r.result);});d.close();return JSON.parse(new TextDecoder().decode(v.contents));}''')
    def snap(name):page.screenshot(path=str(OUT/(name+'.png')))
    page.goto('http://127.0.0.1:8765/');start();began=time.monotonic()
    # Capture each chapter at its midpoint. Crossfades are included in card time.
    for scene,at in [('room',0.8),('journal',5.7),('mystery',10.5),('decision',17.7),('title',22.2)]:
        page.wait_for_timeout(max(0,at-(time.monotonic()-began))*1000)
        for w,h in ([(844,390)] if scene=='title' else [(844,390),(640,360),(800,360)]):
            page.set_viewport_size({'width':w,'height':h});page.wait_for_timeout(120)
            snap(f'{scene}-{w}x{h}')
            fit=page.evaluate('({r:canvas.getBoundingClientRect().toJSON(),w:innerWidth,h:innerHeight,scrollX,scrollY})')
            assert fit['r']['width']<=fit['w'] and fit['r']['height']<=fit['h'] and fit['scrollX']==fit['scrollY']==0
    for _ in range(100):
        data=saved()
        if data and data['opening_seen']:break
        page.wait_for_timeout(100)
    assert data['opening_seen'] and data['money']==0 and data['line_level']==1
    duration=time.monotonic()-began
    snap('natural-game-start')
    page.reload();start();page.wait_for_timeout(300);snap('save-continue-no-opening')
    assert saved()['opening_seen']
    # Separate context: touch skip a fresh Opening, never deleting an existing save.
    fresh=browser.new_context(viewport={'width':844,'height':390},has_touch=True,is_mobile=True)
    second=fresh.new_page();second.on('pageerror',lambda e:errors.append(str(e)))
    second.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
    second.goto('http://127.0.0.1:8765/');second.locator('#start').tap()
    second.wait_for_function("!document.getElementById('start-screen')",timeout=90000)
    second.wait_for_timeout(400);second.touchscreen.tap(775,40);second.wait_for_timeout(600)
    second.screenshot(path=str(OUT/'touch-skip-game-start.png'))
    # Reuse storage read helper with the fresh page so persistence is asserted.
    page=second
    for _ in range(60):
        skip_save=saved()
        if skip_save and skip_save['opening_seen']:break
        page.wait_for_timeout(100)
    assert skip_save['opening_seen'] and skip_save['money']==0
    assert not errors,errors
    result={'result':'PASS','browser':'Chromium touch emulation','natural_completion_save':True,
        'wall_seconds_until_completion_checked':round(duration,2),'touch_skip_save':True,
        'existing_save_no_replay':True,'ratios':['16:9 / 640x360','19.5:9 / 844x390','20:9 / 800x360'],
        'errors':errors,'clarity_emotion_mystery_physical_phone':'MANUAL TEST REQUIRED'}
    (OUT/'results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));browser.close()
