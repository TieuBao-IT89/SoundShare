"""Prepare the opt-in recommendation browser review from the isolated V3 harness.

Run from the repository root with Flutter, Python 3, Node (global WebSocket),
backend dependencies and Chrome installed. Build into a separate output folder
so an existing build/web stays untouched:

  flutter build web --release --no-web-resources-cdn --no-wasm-dry-run \
    --output=build/recommendation-web \
    --dart-define-from-file=.local/web-config.json \
    --dart-define=API_BASE_URL=http://localhost:3000
  python scripts/prepare-recommendation-review.py

Then, in PowerShell, run each case in a fresh owned Chrome profile:

  $env:QA_RECOMMENDATION_MODE='personalized' # or 'cold'
  $env:QA_WIDTH='390' # or '1280'
  node build/review-recommendations.mjs

The build must contain a syntactically valid public Clerk publishable key.
No secret, real Clerk session, dotenv, live Neon or Cloudinary is used. Every
localhost:3000 request is intercepted and sent to an isolated in-memory PGlite
database with actual migrations/services and test RSA JWT verification. The
Clerk browser SDK is simulated. Audio/artwork are generated fixtures; two seeded
valid listens on separate days and a fixed 23:30 Vietnam recommendation clock
make the personalized case deterministic. Audio playback uses real elapsed time.
Only the Chrome profile created by the harness is opened and closed.

The generated MJS, reports, raw PNGs and owned profiles remain in ignored build/.
Results are under build/recommendation-review/<mode>-<width>/; each run checks
API metadata, visible Vietnamese notes/reasons, actual shared-player playback,
audio continuity on profile navigation, and absence of API/browser errors.
Set CHROME_PATH if Chrome is installed at a nondefault path. These fixtures do
not replace real-device or real-provider acceptance testing.
"""
from pathlib import Path

source = Path('backend/scripts/review-nocturne.mjs').read_text(encoding='utf-8')
source = source.replace('from "express"', 'from "../backend/node_modules/express/index.js"')
source = source.replace('from "../src/', 'from "../backend/src/').replace('from "../test/', 'from "../backend/test/')
source = source.replace('"../..",', '"..",')
source = source.replace('const output = path.join(root, "build/nocturne-review");', '''const qaMode = process.env.QA_RECOMMENDATION_MODE || "personalized";
const qaWidth = Number(process.env.QA_WIDTH || 390);
assert.ok(["personalized", "cold"].includes(qaMode));
assert.ok([390, 1280].includes(qaWidth));
const qaNow = new Date("2026-11-06T16:30:00.000Z");
const output = path.join(root, "build/recommendation-review", `${qaMode}-${qaWidth}`);''')
source = source.replace('webDirectory: path.join(root, "build/web")', 'webDirectory: path.join(root, "build/recommendation-web")')
source = source.replace('createCommunityService({ repository, storage })', 'createCommunityService({ repository, storage, now: () => qaNow })')
source = source.replace('  const storage = {', '''  if (qaMode === "personalized") {
    const me = await repository.user("user_a");
    const creator = await repository.user("user_b");
    await pool.query("INSERT INTO user_follows(follower_id,following_id) VALUES ($1,$2)", [me.id, creator.id]);
    for (const daysAgo of [1, 2]) {
      const at = new Date(qaNow.getTime() - daysAgo * 86400000);
      const session = (await pool.query(
        "INSERT INTO playback_sessions(user_id,track_id,started_at,last_heartbeat_at,credited_ms,last_position_ms,threshold_ms,is_valid) VALUES ($1,$2,$3,$3,10000,10000,10000,TRUE) RETURNING id",
        [me.id, songs[0], at],
      )).rows[0].id;
      await pool.query(
        "INSERT INTO valid_play_events(session_id,user_id,track_id,dedup_bucket,created_at) VALUES ($1,$2,$3,$4,$5)",
        [session, me.id, songs[0], Math.floor(at.getTime()/1800000), at],
      );
    }
  }
  const storage = {''')
source = source.replace('      "--use-angle=swiftshader",', '')
source = source.replace('  ws.addEventListener("message", async (event) => {', '''  report.consoleErrors=[];
  report.homeResponses=[];
  report.homeOffsets=[];
  ws.addEventListener("message", async (event) => {''')
source = source.replace('    if (message.method === "Runtime.exceptionThrown")', '''    if (message.method === "Runtime.consoleAPICalled" && message.params.type === "error")
      report.consoleErrors.push(message.params.args.map(a=>a.value||a.description||"").join(" ").slice(0,800));
    if (message.method === "Runtime.exceptionThrown")''')
source = source.replace('          await send("Fetch.fulfillRequest", {\n            requestId,\n            responseCode: response.status,', '''          const responseBody = Buffer.from(await response.arrayBuffer());
          if (url.pathname === "/api/v1/discover/home") {
            report.homeOffsets.push(url.searchParams.get("utcOffsetMinutes"));
            report.homeResponses.push(JSON.parse(responseBody.toString("utf8")).data);
          }
          await send("Fetch.fulfillRequest", {
            requestId,
            responseCode: response.status,''')
source = source.replace('body: Buffer.from(await response.arrayBuffer()).toString("base64")', 'body: responseBody.toString("base64")')
source = source.replace('    await sleep(1100);', '    await sleep(1700);')
source = source.replace('let width = 390,\n    height = 844;', 'let width = qaWidth,\n    height = qaWidth < 768 ? 844 : 960;')
source = source.replace('    const { data } = await send("Page.captureScreenshot"', '    await send("Input.dispatchMouseEvent", { type: "mouseMoved", x: 2, y: 2 });\n    await sleep(500);\n    const { data } = await send("Page.captureScreenshot"')

start = source.index('  await send("Emulation.setDeviceMetricsOverride", {')
end = source.index('  assert.deepEqual(report.apiFailures, []);', start)
source = source[:start] + '''  await send("Emulation.setTimezoneOverride", { timezoneId: "Asia/Ho_Chi_Minh" });
  await send("Emulation.setDeviceMetricsOverride", {
    width, height, deviceScaleFactor: 1, mobile: width < 768,
  });
  await navigate("/");
  for(let attempt=0; attempt<30 && !report.homeResponses.length; attempt++) {
    await sleep(200);
    await semantics();
  }
  assert.ok(report.homeResponses.length, "Real recommendation API must respond");
  const home = report.homeResponses.at(-1);
  assert.equal(home.recommendation.version, "taste-v1");
  assert.equal(home.recommendation.strategy, qaMode === "personalized" ? "personalized" : "new-releases");
  assert.equal(home.recommendation.daypart, "night");
  assert.equal(home.recommendation.utcOffsetMinutes, 420);
  assert.ok(report.homeOffsets.every(v=>v === "420"), "Device offset must reach the API");
  assert.ok(home.recommended.length > 0);
  assert.ok(home.recommended.every(song=>song.visibility === "public"));
  const note = qaMode === "personalized"
    ? "Gợi ý từ lịch sử nghe, bài đã thích/lưu và tài khoản bạn theo dõi, có xét thói quen nghe theo thời điểm."
    : "Bắt đầu với các bản thu mới. Nghe, thích, lưu và theo dõi để gợi ý dần phù hợp với bạn.";
  const reason = qaMode === "personalized"
    ? "Bạn hay nghe Ambient ban đêm"
    : "Bản thu mới để bạn khám phá";
  assert.ok(home.recommended.some(song=>song.recommendationReason?.code ===
    (qaMode === "personalized" ? "listening-time" : "new-release")));
  const textBounds = async (text) => evaluate(`(()=>{
    const labels=[...document.querySelectorAll('[aria-label]')];
    const el=labels.find(e=>(e.getAttribute('aria-label')||'').trim().normalize('NFC')===${JSON.stringify(text)})
      || [...document.querySelectorAll('flt-semantics')].filter(e=>(e.textContent||'').trim().normalize('NFC')===${JSON.stringify(text)}).at(-1);
    if(!el)return null;const r=el.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
  })()`);
  const reasonCardBounds = async () => evaluate(`(()=>{
    const el=[...document.querySelectorAll('[aria-label]')].find(e=>{
      const label=(e.getAttribute('aria-label')||'').normalize('NFC');
      return label.includes(${JSON.stringify(reason)}) && label.includes('Phát Bản thu kiểm thử');
    });
    if(!el)return null;const r=el.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
  })()`);
  for(let attempt=0; attempt<20; attempt++) {
    await semantics();
    const target=await reasonCardBounds();
    if(target && target.y>=210 && target.y<280) break;
    const delta = target ? target.y-240 : 240;
    await send("Input.dispatchMouseEvent", {type:"mouseWheel",x:width-45,y:height*.55,deltaX:0,deltaY:delta});
    await sleep(300);
  }
  await semantics();
  const noteBounds=await textBounds(note), reasonBounds=await reasonCardBounds();
  report.visibleRecommendation={note,noteBounds,reason,reasonBounds};
  report.debugLabels=await evaluate("[...document.querySelectorAll('[aria-label],flt-semantics')].filter(e=>((e.getAttribute('aria-label')||'')+' '+(e.textContent||'')).includes('Ambient') || ((e.getAttribute('aria-label')||'')+' '+(e.textContent||'')).includes('Gợi ý từ')).map(e=>{const r=e.getBoundingClientRect();return {tag:e.tagName,label:e.getAttribute('aria-label'),text:e.textContent,x:r.x,y:r.y,w:r.width,h:r.height};})");
  await shot("diagnostic-"+qaMode);
  assert.ok(noteBounds && reasonBounds && reasonBounds.y>=160,
    "Vietnamese recommendation note must be present above the artwork rail");
  assert.ok(reasonBounds.y+reasonBounds.height<height-80,
    "Recommended artwork and its explanation must fit the visible viewport");
  await shot("for-you-"+qaMode);
  report.checks.push(`Real API returned ${home.recommendation.strategy} with device offset and visible Vietnamese explanation at ${width}px`);
  const artworkTarget=await evaluate(`(()=>{
    const els=[...document.querySelectorAll('[aria-label]')].filter(e=>(e.getAttribute('aria-label')||'').includes('Phát Bản thu kiểm thử'));
    const candidates=els.map(e=>{const r=e.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+Math.min(84,r.height/2),width:r.width,height:r.height};});
    return candidates.find(r=>r.width>60&&r.height>60&&r.x>0&&r.x<${width}&&r.y>0&&r.y<${height-100})||null;
  })()`);
  assert.ok(artworkTarget,"Recommended artwork must expose a visible playback target");
  await send("Input.dispatchMouseEvent",{type:"mousePressed",x:artworkTarget.x,y:artworkTarget.y,button:"left",clickCount:1});
  await send("Input.dispatchMouseEvent",{type:"mouseReleased",x:artworkTarget.x,y:artworkTarget.y,button:"left",clickCount:1});
  await sleep(3000);
  await shot("player-"+qaMode);
  const initialAudio=await evaluate("window.__qaAudio.map(a=>({paused:a.paused,position:a.currentTime,duration:a.duration,error:a.error?.code||null}))");
  assert.ok(initialAudio.some(a=>!a.paused&&a.position>1&&a.duration===20&&!a.error),"Recommended track must advance real HTML audio");
  await navigate("/u/qa.creator");
  const laterAudio=await evaluate("window.__qaAudio.map(a=>({paused:a.paused,position:a.currentTime,error:a.error?.code||null}))");
  assert.equal(laterAudio.length,initialAudio.length,"Navigation keeps the same audio element");
  assert.ok(laterAudio.some(a=>!a.paused&&a.position>initialAudio[0].position&&!a.error),"Profile navigation preserves playback progress");
  report.playback={initialAudio,laterAudio};
  report.checks.push("Recommended artwork opens the shared player; real synthetic audio advances and continues on creator profile");
  assert.deepEqual(report.consoleErrors, []);
''' + source[end:]
build_dir = Path('build')
build_dir.mkdir(exist_ok=True)
(build_dir / 'review-recommendations.mjs').write_text(source, encoding='utf-8')
print('Prepared build/review-recommendations.mjs; no browser started.')
