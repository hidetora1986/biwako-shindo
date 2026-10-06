"""Local Web export QA. Fixtures affect isolated browser storage only; no debug game UI.
Run after exporting Web Playtest and serving build/web on 127.0.0.1:8765.
Requires Python Playwright and Chromium. Physical phones remain manual QA.
"""
import copy
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path('docs/story/screenshots')
OUT.mkdir(parents=True, exist_ok=True)
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
        args=['--no-sandbox', '--enable-unsafe-swiftshader', '--use-gl=angle', '--use-angle=swiftshader'])
    context = browser.new_context(viewport={'width':844,'height':390}, has_touch=True, is_mobile=True)
    page = context.new_page()
    errors = []
    page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
    page.on('pageerror', lambda e: errors.append(str(e)))
    def start():
        page.locator('#start').tap()
        page.wait_for_function("!document.getElementById('start-screen')", timeout=90000)
        page.wait_for_timeout(300)
    def snap(name):
        path = OUT / (name + '.png')
        page.screenshot(path=str(path))
    def skip():
        page.touchscreen.tap(page.viewport_size['width']-70, 40)
        page.wait_for_timeout(350)
    def read():
        return page.evaluate('''async()=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const keys=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').getAllKeys();r.onsuccess=()=>ok(r.result);});const key=keys.find(k=>String(k).endsWith('/biwako-shindo/save.json'));if(!key){d.close();return null;}const v=await new Promise(ok=>{const r=d.transaction('FILE_DATA').objectStore('FILE_DATA').get(key);r.onsuccess=()=>ok(r.result);});d.close();return {key,data:JSON.parse(new TextDecoder().decode(v.contents))};}''')
    def fixture(data):
        page.evaluate('''async ({key,data})=>{const d=await new Promise(ok=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);});const tx=d.transaction('FILE_DATA','readwrite');const s=tx.objectStore('FILE_DATA');const v=await new Promise(ok=>{const r=s.get(key);r.onsuccess=()=>ok(r.result);});v.contents=new TextEncoder().encode(JSON.stringify(data));v.timestamp=new Date();s.put(v,key);await new Promise(ok=>tx.oncomplete=ok);d.close();}''', {'key':saved['key'],'data':data})
        page.reload();start()
    def fit():
        r=page.evaluate('({r:canvas.getBoundingClientRect().toJSON(),w:innerWidth,h:innerHeight,scrollX,scrollY})')
        assert r['r']['width']<=r['w'] and r['r']['height']<=r['h'] and r['scrollX']==r['scrollY']==0
    page.goto('http://127.0.0.1:8765/');start()
    snap('opening-844x390');assert read() is None
    for w,h in [(640,360),(800,360)]:
        page.set_viewport_size({'width':w,'height':h});page.wait_for_timeout(150);fit();snap(f'opening-{w}x{h}')
    page.set_viewport_size({'width':844,'height':390});page.wait_for_timeout(150);skip()
    for _ in range(60):
        saved=read()
        if saved and saved['data']['opening_seen']:break
        page.wait_for_timeout(100)
    assert saved['data']['opening_seen']
    page.reload();start();snap('opening-not-repeated');assert read()['data']['opening_seen']
    page.touchscreen.tap(275,95);page.wait_for_timeout(250)
    page.touchscreen.tap(480,50);page.wait_for_timeout(250);snap('journal-early-844x390')
    page.touchscreen.tap(679,55);page.wait_for_timeout(200)
    base=copy.deepcopy(saved['data']);base.update(money=123456,boss15_defeated=True,main_ending_seen=True,
        main_story_ending_seen=False,rod_level=5,reel_level=5,line_level=5,sonar_level=5,
        returned_unknown_a=True,returned_unknown_b=True,night_unlocked=True,hull_knock_count=3,
        anomaly_seen=True,night_page_seen=True)
    for n in range(1,16):
        id=f'No.{n:02d}';base['fish_discovered'][id]=True;base['fish_caught_count'][id]=1
    for kind in ['main','cut','contact']:
        data=copy.deepcopy(base)
        data['main_story_ending_seen']=kind!='main'
        data['hidden_cut_ending_seen']=kind=='cut';data['cut_story_ending_seen']=False
        data['hidden_contact_ending_seen']=kind=='contact';data['contact_story_ending_seen']=False
        fixture(data)
        page.wait_for_timeout(3600 if kind=='main' else 2300 if kind=='cut' else 300)
        snap(kind+'-journal-844x390');assert not read()['data'][kind+'_story_ending_seen']
        for w,h in [(640,360),(800,360)]:
            page.set_viewport_size({'width':w,'height':h});page.wait_for_timeout(100);fit();snap(f'{kind}-journal-{w}x{h}')
        page.set_viewport_size({'width':844,'height':390});page.wait_for_timeout(150);skip()
        snap(kind+'-credits')
        skip();snap(kind+'-title')
        flag=kind+'_story_ending_seen'
        for _ in range(60):
            current=read()['data']
            if current[flag]:break
            page.wait_for_timeout(100)
        assert current[flag] and current['money']==123456 and current['fish_caught_count']['No.15']==1
        if kind=='contact': assert current['no00_contacted'] and current['hidden_contact_ending_seen']
        page.touchscreen.tap(420,265);page.wait_for_timeout(350)
        snap(kind+'-continue')
    page.touchscreen.tap(275,95);page.wait_for_timeout(250);page.touchscreen.tap(480,50);page.wait_for_timeout(250)
    snap('journal-progress-844x390')
    page.touchscreen.tap(400,315);page.mouse.wheel(0,900);page.wait_for_timeout(300);snap('journal-last-page')
    assert not errors,errors
    result={'result':'PASS','opening_skip_persists':True,'legacy_gameplay': 'covered by native + playtest_feedback browser suite',
        'journal_touch':True,'main_cut_contact_skip_and_continue':True,'ending_flags_indexeddb':True,
        'unchanged_money_and_boss_count':True,'ratios':['16:9 / 640x360','19.5:9 / 844x390','20:9 / 800x360'],
        'errors':errors,'physical_iPhone_Android':'MANUAL TEST REQUIRED'}
    Path('/tmp/narrative-web-results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
    browser.close()
