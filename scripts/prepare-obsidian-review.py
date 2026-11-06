"""Generate the opt-in V4 browser review from the isolated V3 harness.

Run from the repository root after a release Web build:
  python scripts/prepare-obsidian-review.py
  node build/review-obsidian.mjs

Set QA_SNAPSHOT=1 and QA_WIDTH=320|390|430|768|1024|1280|1440 for a
fresh browser at one viewport. Without QA_SNAPSHOT the script also exercises
search, follow, playlist creation and real audio/heartbeat across navigation.
QA_ONLY_FLOW=1 skips the viewport loop; QA_DETAIL=1 adds section/playlist review.
No dotenv, existing browser profile or live Neon/Cloudinary session is used.
The generated file, browser profiles and raw evidence stay in ignored build/.
"""
from pathlib import Path
source = Path('backend/scripts/review-nocturne.mjs').read_text(encoding='utf-8')
source = source.replace('from "express"', 'from "../backend/node_modules/express/index.js"')
source = source.replace('from "../src/', 'from "../backend/src/').replace('from "../test/', 'from "../backend/test/')
source = source.replace('"../..",', '"..",').replace('build/nocturne-review', 'build/obsidian-review')
source = source.replace('"Bản thu kiểm thử · 02",', '"Bản thu kiểm thử · 02",\n    "Bản thu kiểm thử · 03",')
# Preserve the runner\'s isolated DB, verified JWT middleware, request interception,
# generated audio and owned Chrome. Only viewport/interactions differ for V4.
source = source.replace('await click("Bản thu kiểm thử · 01", true);', 'await click("Nghe ngay");')
source = source.replace('[320, 640],\n    [1280, 900],', '[320, 740],\n    [390, 844],\n    [430, 900],\n    [768, 1000],\n    [1024, 900],\n    [1280, 900],\n    [1440, 960],')
source = source.replace('["/upload", "upload"],', '["/upload", "upload"],\n      ["/library", "library"],\n      ["/search?q=%40qa.creator", "search"],')
anchor = '''      await shot(name);
    }
  }
  assert.deepEqual(report.apiFailures, []);'''
replacement = '''      await shot(name);
    }
    await navigate("/explore");
    await click("Nghe ngay");
    await shot("player");
    if (width >= 768) {
      await click("Danh sách phát");
      await shot("queue");
      await click("Đóng danh sách phát");
      report.checks.push(`Queue opens/closes at ${width}px without a second audio player`);
    }
  }
  assert.deepEqual(report.apiFailures, []);'''
assert anchor in source
source = source.replace(anchor, replacement)
source = source.replace('let width = 390,\n    height = 844;', 'let width = Number(process.env.QA_WIDTH || 390),\n    height = width < 768 ? 844 : 960;')
source = source.replace('  await shot("home");\n  await navigate("/search', '  if (!process.env.QA_SNAPSHOT) {\n  await shot("home");\n  await navigate("/search', 1)
source = source.replace('  for (const [w, h] of [\n', '  }\n  for (const [w, h] of (process.env.QA_ONLY_FLOW ? [] : process.env.QA_SNAPSHOT ? [[width, height]] : [\n', 1)
source = source.replace('    [1440, 960],\n  ]) {', '    [1440, 960],\n  ])) {')
source = source.replace('    await send("Page.reload", { ignoreCache: true });\n    await sleep(3000);', '    if (!process.env.QA_SNAPSHOT) { await send("Page.reload", { ignoreCache: true }); await sleep(3000); }')
source = source.replace('    await sleep(1100);', '    await sleep(1700);')
source = source.replace('    const { data } = await send("Page.captureScreenshot"', '    await send("Input.dispatchMouseEvent", { type: "mouseMoved", x: 2, y: 2 });\n    await sleep(700);\n    const { data } = await send("Page.captureScreenshot"')
source = source.replace('path.join(output, "report.json")', 'path.join(output, process.env.QA_SNAPSHOT ? `report-${width}.json` : "report.json")')
source = source.replace('      "--use-angle=swiftshader",', '')
source = source.replace('  ws.addEventListener("message", async (event) => {', '  report.console=[]; report.networkFailures=[];\n  ws.addEventListener("message", async (event) => {')
source = source.replace('    if (message.method === "Runtime.exceptionThrown")', '''    if (message.method === "Runtime.consoleAPICalled") report.console.push(message.params.args.map(a=>a.value||a.description||"").join(" ").slice(0,800));
    if (message.method === "Network.loadingFailed") report.networkFailures.push(message.params.errorText);
    if (message.method === "Runtime.exceptionThrown")''')
source = source.replace('  await send("Runtime.enable");', '  await send("Runtime.enable"); await send("Network.enable");')
source = source.replace('    if (width >= 768) {\n      await click("Danh sách phát");', '    if (width >= 768) {\n      const audioCount=await evaluate("window.__qaAudio.length");\n      await click("Danh sách phát");')
source = source.replace('      report.checks.push(`Queue opens/closes at', '      assert.equal(await evaluate("window.__qaAudio.length"),audioCount,"Opening queue must retain the audio element");\n      report.checks.push(`Queue opens/closes at')
source = source.replace('  const storage = {', '''  if (process.env.QA_SNAPSHOT) {
    const ownArt=(await pool.query("INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes) VALUES ('user_a','artwork','qa-art-own','https://fixture.invalid/art','image','png',100) RETURNING id")).rows[0].id;
    const ownAudio=(await pool.query("INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes) VALUES ('user_a','audio','qa-audio-own','https://fixture.invalid/audio','video','mp3',100) RETURNING id")).rows[0].id;
    await pool.query("INSERT INTO private_tracks(clerk_user_id,audio_asset_id,artwork_asset_id,title,artist,genre,duration_seconds) VALUES ('user_a',$1,$2,'Bản nháp kiểm thử riêng tư','Âm thanh tổng hợp','Ambient',20)",[ownAudio,ownArt]);
    const playlist=await repository.createPlaylist('user_a',{title:'Tuyển chọn kiểm thử biệt lập',description:'Âm thanh tổng hợp',visibility:'private'});
    for(const trackId of songs) await repository.changePlaylist('user_a',playlist.id,{trackId});
  }
  const storage = {''')
source = source.replace('asset.public_id === "qa-art"', 'asset.public_id.startsWith("qa-art")')
source = source.replace('      report.checks.push(`Queue opens/closes at ${width}px without a second audio player`);', '''      report.checks.push(`Queue opens/closes at ${width}px without a second audio player`);
    }
    await navigate("/");
    await shot("home-playing");
    if (width >= 1100) {
      const slider = await evaluate(`(()=>{const items=[...document.querySelectorAll('[role="slider"]')].filter(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.height>0;}); const el=items.at(-1); if(!el)return null;const r=el.getBoundingClientRect();return {x:r.x+r.width*.3,y:r.y+r.height/2};})()`);
      assert.ok(slider,"Dock volume slider must be accessible");
      await send("Input.dispatchMouseEvent", {type:"mousePressed",...slider,button:"left",clickCount:1});
      await send("Input.dispatchMouseEvent", {type:"mouseReleased",...slider,button:"left",clickCount:1});
      await sleep(500);
      assert.ok(await evaluate("window.__qaAudio.some(a=>a.volume<.95)"),"Volume slider must change actual HTML audio");
      report.checks.push(`Actual dock volume changes at ${width}px`);
      const field=await evaluate(`(()=>{const el=[...document.querySelectorAll('input,textarea')].find(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.height>0;});if(!el)return null;const r=el.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};})()`);
      assert.ok(field,"Global search must expose a text field");
      await send("Input.dispatchMouseEvent",{type:"mousePressed",...field,button:"left",clickCount:1});
      await send("Input.dispatchMouseEvent",{type:"mouseReleased",...field,button:"left",clickCount:1});
      await send("Input.insertText",{text:"@qa.creator"});
      await send("Input.dispatchKeyEvent",{type:"keyDown",key:"Enter",code:"Enter",windowsVirtualKeyCode:13});
      await send("Input.dispatchKeyEvent",{type:"keyUp",key:"Enter",code:"Enter",windowsVirtualKeyCode:13});
      await sleep(1400);
      assert.ok((await evaluate("location.hash")).includes("search?q="),"Global search must navigate to real search results");
      report.checks.push(`Global search submits @username at ${width}px`);''')
source = source.replace('  assert.deepEqual(report.apiFailures, []);', '''  if (process.env.QA_DETAIL) {
    for (const [route,name,delta] of [["/explore","discover-creators",900],["/explore","discover-genres",1600],["/","home-releases",750]]) {
      await navigate(route);
      await send("Input.dispatchMouseEvent",{type:"mouseWheel",x:width-80,y:height*.6,deltaX:0,deltaY:delta});
      await sleep(1200);
      await shot(name);
    }
    const playlist=(await repository.playlists('user_a',{limit:20,offset:0}))[0];
    assert.ok(playlist,"Seed playlist must exist");
    await navigate("/playlists/"+playlist.id);
    await shot("playlist");
    await click("Phát tất cả");
    const playerVisible=()=>evaluate("document.body.innerText.includes('Đang phát') || [...document.querySelectorAll('[aria-label]')].some(e=>(e.getAttribute('aria-label')||'').includes('Thu nhỏ'))");
    for(let attempt=0;attempt<40;attempt++) {
      if(await playerVisible())break;
      await sleep(200);
    }
    await shot("playlist-after-play");
    report.playAllState={playerVisible:await playerVisible(),audio:await evaluate("window.__qaAudio.map(a=>({paused:a.paused,position:a.currentTime,error:a.error?.code||null}))")};
    assert.ok(report.playAllState.playerVisible,"Play all opens the shared player");
    assert.ok(await evaluate("window.__qaAudio.some(a=>!a.paused&&!a.error)"),"Play all must play real audio");
    report.checks.push("Seeded playlist plays through the actual Play all action");
  }
  assert.deepEqual(report.apiFailures, []);''')
Path('build/review-obsidian.mjs').write_text(source, encoding='utf-8')
