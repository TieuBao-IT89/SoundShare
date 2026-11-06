// Opt-in browser review. Uses only an in-memory PostgreSQL database, generated
// JWT test keys, synthetic audio/artwork, and a newly created Chrome profile.
// It never imports dotenv or connects to Neon/Cloudinary/real Clerk sessions.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { deflateSync } from "node:zlib";
import express from "express";
import { createApp } from "../src/app.js";
import { createCommunityRepository } from "../src/repositories/community.repository.js";
import { createCommunityService } from "../src/services/community.service.js";
import { createTrackRepository } from "../src/repositories/track.repository.js";
import { createTrackService } from "../src/services/track.service.js";
import {
  communityDatabase,
  clerkOptions,
  token,
} from "../test/helpers/community-fixture.js";

const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);
const output = path.join(root, "build/nocturne-review");
const browserOrigin = "http://localhost:3000";
fs.mkdirSync(output, { recursive: true });
const fixture = await communityDatabase();
const { pool } = fixture;
let origin, browser, ws, server;
const report = {
  fixture:
    "Isolated PostgreSQL; synthetic audio/artwork; simulated Clerk SDK with server-verified RSA JWTs",
  screenshots: [],
  checks: [],
  exceptions: [],
  apiFailures: [],
};
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
try {
  const repository = createCommunityRepository(pool);
  await repository.user("user_a");
  await repository.user("user_b");
  await repository.updateProfile("user_a", {
    username: "qa.listener",
    displayName: "Người nghe kiểm thử",
    bio: "Hồ sơ kiểm thử biệt lập",
  });
  await repository.updateProfile("user_b", {
    username: "qa.creator",
    displayName: "Phòng thu kiểm thử",
    bio: "Âm thanh tổng hợp · Không phải nội dung thật",
  });
  const art = (
    await pool.query(`INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes)
    VALUES ('user_b','artwork','qa-art','https://fixture.invalid/art','image','png',100) RETURNING id`)
  ).rows[0].id;
  const songs = [];
  for (const [index, title] of [
    "Bản thu kiểm thử · 01",
    "Bản thu kiểm thử · 02",
  ].entries()) {
    const audio = (
      await pool.query(
        `INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes)
      VALUES ('user_b','audio',$1,'https://fixture.invalid/audio','video','mp3',100) RETURNING id`,
        [`qa-audio-${index}`],
      )
    ).rows[0].id;
    songs.push(
      (
        await pool.query(
          `INSERT INTO private_tracks(clerk_user_id,audio_asset_id,artwork_asset_id,title,artist,genre,visibility,rights_confirmed_at,duration_seconds)
      VALUES ('user_b',$1,$2,$3,'Âm thanh tổng hợp','Ambient','public',NOW(),20) RETURNING id`,
          [audio, art, title],
        )
      ).rows[0].id,
    );
  }
  const storage = {
    createAccess: (asset) => ({
      url: `${browserOrigin}/__qa/${asset.public_id === "qa-art" ? "art.png" : "audio.wav"}`,
      expiresAt: new Date(Date.now() + 300000).toISOString(),
    }),
    find: async () => ({ duration: 20 }),
  };
  const app = createApp({
    logging: false,
    clerkOptions,
    webDirectory: path.join(root, "build/web"),
    communityService: createCommunityService({ repository, storage }),
    trackService: createTrackService({
      repository: createTrackRepository(pool),
      storage,
    }),
  });
  const wrapper = express();
  const samples = 22050 * 20,
    wav = Buffer.alloc(44 + samples * 2);
  wav.write("RIFF");
  wav.writeUInt32LE(wav.length - 8, 4);
  wav.write("WAVEfmt ", 8);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(22050, 24);
  wav.writeUInt32LE(44100, 28);
  wav.writeUInt16LE(2, 32);
  wav.writeUInt16LE(16, 34);
  wav.write("data", 36);
  wav.writeUInt32LE(samples * 2, 40);
  for (let i = 0; i < samples; i++)
    wav.writeInt16LE(
      Math.round(Math.sin((i / 22050) * 220 * Math.PI * 2) * 500),
      44 + i * 2,
    );
  wrapper.get("/__qa/audio.wav", (_, res) => res.type("audio/wav").send(wav));
  // Small procedural PNG fixture; no external or copyrighted artwork.
  const pixels = Buffer.alloc(400 * (400 * 3 + 1));
  for (let y = 0; y < 400; y++)
    for (let x = 0; x < 400; x++) {
      const dx = x - 200,
        dy = (y - 200) * 0.85;
      const radius = Math.hypot(dx, dy),
        ring = Math.sin(radius / 5 + Math.atan2(dy, dx) * 5);
      const accent = ring > 0.94 && radius < 180 && radius > 45;
      const index = y * 1201 + 1 + x * 3;
      pixels[index] = accent ? 150 : 23;
      pixels[index + 1] = accent ? 180 : 26;
      pixels[index + 2] = accent ? 240 : 44;
    }
  const chunk = (type, data) => {
    const name = Buffer.from(type),
      content = Buffer.concat([name, data]);
    let crc = 0xffffffff;
    for (const byte of content) {
      crc ^= byte;
      for (let bit = 0; bit < 8; bit++)
        crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
    }
    const length = Buffer.alloc(4),
      checksum = Buffer.alloc(4);
    length.writeUInt32BE(data.length);
    checksum.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
    return Buffer.concat([length, content, checksum]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(400);
  ihdr.writeUInt32BE(400, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  const artwork = Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(pixels)),
    chunk("IEND", Buffer.alloc(0)),
  ]);
  wrapper.get("/__qa/art.png", (_, res) => res.type("image/png").send(artwork));
  wrapper.use(app);
  server = wrapper.listen(0, "127.0.0.1");
  await once(server, "listening");
  origin = `http://localhost:${server.address().port}`;
  const profile = fs.mkdtempSync(path.join(output, "chrome-owned-"));
  const chromePath =
    process.env.CHROME_PATH ||
    "C:/Program Files/Google/Chrome/Application/chrome.exe";
  browser = spawn(
    chromePath,
    [
      "--headless=new",
      "--no-first-run",
      "--remote-debugging-port=0",
      "--remote-allow-origins=*",
      "--autoplay-policy=no-user-gesture-required",
      "--enable-unsafe-swiftshader",
      "--use-angle=swiftshader",
      "--user-data-dir=" + profile,
      "about:blank",
    ],
    { windowsHide: true, stdio: "ignore" },
  );
  let page;
  for (let attempt = 0; attempt < 60; attempt++) {
    try {
      const port = fs
        .readFileSync(path.join(profile, "DevToolsActivePort"), "utf8")
        .split("\n")[0];
      page = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find(
        (item) => item.type === "page",
      );
      if (page) break;
    } catch {
      /* Retry only the profile created above. */
    }
    await sleep(200);
  }
  assert.ok(page, "Owned Chrome must start");
  ws = new WebSocket(page.webSocketDebuggerUrl);
  await once(ws, "open");
  const pending = new Map();
  let nextId = 0;
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = ++nextId;
      const timeout = setTimeout(() => {
        pending.delete(id);
        reject(new Error(`CDP timeout: ${method}`));
      }, 20000);
      pending.set(id, { resolve, reject, timeout });
      ws.send(JSON.stringify({ id, method, params }));
    });
  const sdk = `const listeners=new Set(); const user={id:'user_a',fullName:'Người nghe kiểm thử'};
    const session={id:'sess_qa',status:'active',user,getToken:async()=>${JSON.stringify(token("user_a", { exp: Math.floor(Date.now() / 1000) + 3600 }))}};
    window.Clerk={session,user,load:async()=>{},addListener:cb=>{listeners.add(cb);cb();},signOut:async()=>{window.Clerk.session=null;window.Clerk.user=null;for(const cb of listeners)cb();}};`;
  ws.addEventListener("message", async (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const { resolve, reject, timeout } = pending.get(message.id);
      pending.delete(message.id);
      clearTimeout(timeout);
      message.error
        ? reject(new Error(message.error.message))
        : resolve(message.result);
    }
    if (message.method === "Runtime.exceptionThrown")
      report.exceptions.push(message.params.exceptionDetails.text);
    if (message.method === "Fetch.requestPaused") {
      const { requestId, request } = message.params;
      try {
        const url = new URL(request.url);
        if (url.hostname === "cdn.jsdelivr.net") {
          await send("Fetch.fulfillRequest", {
            requestId,
            responseCode: 200,
            responseHeaders: [
              { name: "Content-Type", value: "text/javascript" },
              { name: "Access-Control-Allow-Origin", value: "*" },
            ],
            body: Buffer.from(
              url.pathname.includes("/clerk-js@") ? sdk : "",
            ).toString("base64"),
          });
        } else if (url.origin === browserOrigin) {
          // Every local request, including document/assets and APIs, goes to
          // this isolated server. Nothing reaches the running application DB.
          const headers = { ...request.headers };
          delete headers.Host;
          delete headers["Content-Length"];
          const response = await fetch(origin + url.pathname + url.search, {
            method: request.method,
            headers,
            body: request.postData,
            signal: AbortSignal.timeout(15000),
          });
          if (!response.ok && url.pathname.startsWith("/api/v1/"))
            report.apiFailures.push({
              method: request.method,
              path: url.pathname,
              status: response.status,
            });
          await send("Fetch.fulfillRequest", {
            requestId,
            responseCode: response.status,
            responseHeaders: [...response.headers]
              .filter(
                ([name]) =>
                  ![
                    "transfer-encoding",
                    "content-length",
                    "content-encoding",
                  ].includes(name),
              )
              .map(([name, value]) => ({ name, value })),
            body: Buffer.from(await response.arrayBuffer()).toString("base64"),
          });
        } else await send("Fetch.continueRequest", { requestId });
      } catch (error) {
        report.apiFailures.push({ error: error.name });
        await send("Fetch.failRequest", { requestId, errorReason: "Failed" });
      }
    }
  });
  const evaluate = async (expression) => {
    const result = await send("Runtime.evaluate", {
      expression,
      returnByValue: true,
      awaitPromise: true,
    });
    if (result.exceptionDetails) throw new Error("Browser evaluation failed");
    return result.result.value;
  };
  await send("Page.enable");
  await send("Runtime.enable");
  await send("Fetch.enable", {
    patterns: [
      { urlPattern: browserOrigin + "/*" },
      { urlPattern: "https://cdn.jsdelivr.net/*" },
    ],
  });
  await send("Page.addScriptToEvaluateOnNewDocument", {
    source: `window.__qaAudio=[]; const play=HTMLMediaElement.prototype.play; HTMLMediaElement.prototype.play=function(...args){if(!window.__qaAudio.includes(this))window.__qaAudio.push(this);return play.apply(this,args);};`,
  });
  const semantics = async () => {
    await evaluate(
      "document.querySelector('flt-semantics-placeholder')?.click();true",
    );
    await sleep(100);
  };
  const navigate = async (route) => {
    await send("Page.navigate", { url: browserOrigin + "/#" + route });
    await sleep(1100);
    await semantics();
  };
  let width = 390,
    height = 844;
  const shot = async (name) => {
    await semantics();
    const { data } = await send("Page.captureScreenshot", { format: "png" });
    const file = `${name}-${width}.png`;
    fs.writeFileSync(path.join(output, file), Buffer.from(data, "base64"));
    report.screenshots.push(file);
  };
  const click = async (label, partial = false) => {
    const target = await evaluate(
      `(()=>{const el=[...document.querySelectorAll('[role="button"],button')].find(e=>{const t=(e.getAttribute('aria-label')||e.textContent||'').trim().normalize('NFC');return ${partial ? `t.includes(${JSON.stringify(label)})` : `t===${JSON.stringify(label)}`};});if(!el)return null;const r=el.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};})()`,
    );
    assert.ok(
      target && target.y > 0 && target.y < height,
      `Visible button: ${label}`,
    );
    await send("Input.dispatchMouseEvent", {
      type: "mousePressed",
      ...target,
      button: "left",
      clickCount: 1,
    });
    await send("Input.dispatchMouseEvent", {
      type: "mouseReleased",
      ...target,
      button: "left",
      clickCount: 1,
    });
    await sleep(700);
  };
  await send("Emulation.setDeviceMetricsOverride", {
    width,
    height,
    deviceScaleFactor: 1,
    mobile: true,
  });
  await navigate("/");
  await sleep(5000);
  await semantics();
  await shot("home");
  await navigate("/search?q=%40qa.creator");
  await shot("username-search");
  await click("Phòng thu kiểm thử", true);
  await shot("public-profile");
  await click("Theo dõi");
  assert.equal(
    (await repository.profile("user_a", "qa.creator")).following,
    true,
  );
  await send("Page.reload", { ignoreCache: true });
  await sleep(3500);
  await semantics();
  assert.equal(
    (await repository.profile("user_a", "qa.creator")).following,
    true,
  );
  report.checks.push(
    "Search @username opens the correct profile; follow persists after reload",
  );
  await navigate("/playlists");
  await click("Tạo playlist");
  await shot("playlist-dialog");
  const field = await evaluate(
    `(()=>{const el=[...document.querySelectorAll('[role="textbox"],input,textarea')].find(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.height>0;});if(!el)return null;const r=el.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};})()`,
  );
  assert.ok(field, "Playlist title input must be accessible");
  await send("Input.dispatchMouseEvent", {
    type: "mousePressed",
    ...field,
    button: "left",
    clickCount: 1,
  });
  await send("Input.dispatchMouseEvent", {
    type: "mouseReleased",
    ...field,
    button: "left",
    clickCount: 1,
  });
  await send("Input.insertText", { text: "Playlist kiểm thử biệt lập" });
  await click("Lưu thay đổi");
  assert.equal(
    (
      await pool.query(
        "SELECT count(*)::int AS count FROM playlists WHERE title=$1",
        ["Playlist kiểm thử biệt lập"],
      )
    ).rows[0].count,
    1,
  );
  await shot("playlist-created");
  report.checks.push(
    "Creating a playlist through the actual dialog persists it in isolated PostgreSQL",
  );
  await navigate("/explore");
  await shot("discover");
  await click("Bản thu kiểm thử · 01", true);
  await shot("player");
  await sleep(2200);
  let audio = await evaluate(
    "window.__qaAudio.map(a=>({paused:a.paused,position:a.currentTime,duration:a.duration,error:a.error?.code||null}))",
  );
  assert.ok(
    audio.some(
      (a) => !a.paused && a.position > 1 && a.duration === 20 && !a.error,
    ),
    "Actual HTML audio must advance",
  );
  await navigate("/u/qa.creator");
  await shot("profile-mini-player");
  audio = await evaluate(
    "window.__qaAudio.map(a=>({paused:a.paused,position:a.currentTime}))",
  );
  assert.ok(
    audio.some((a) => !a.paused && a.position > 2),
    "Profile navigation must preserve audio",
  );
  await sleep(13000);
  const events = await pool.query(
    "SELECT count(*)::int AS count FROM valid_play_events",
  );
  assert.ok(
    events.rows[0].count >= 1,
    "Real elapsed playback must generate a valid event",
  );
  report.checks.push(
    "Real 20-second synthetic audio plays across navigation and records a valid play via heartbeat",
  );
  for (const [w, h] of [
    [320, 640],
    [1280, 900],
  ]) {
    width = w;
    height = h;
    await send("Emulation.setDeviceMetricsOverride", {
      width,
      height,
      deviceScaleFactor: 1,
      mobile: width < 900,
    });
    await send("Page.reload", { ignoreCache: true });
    await sleep(3000);
    await semantics();
    for (const [route, name] of [
      ["/", "home"],
      ["/explore", "discover"],
      ["/profile", "profile"],
      ["/upload", "upload"],
    ]) {
      await navigate(route);
      await shot(name);
    }
  }
  assert.deepEqual(report.apiFailures, []);
  assert.deepEqual(report.exceptions, []);
  report.checks.push("No failed API responses or uncaught browser exceptions");
  fs.writeFileSync(
    path.join(output, "report.json"),
    JSON.stringify(report, null, 2),
  );
  console.log(
    JSON.stringify({
      screenshots: report.screenshots.length,
      checks: report.checks,
      output,
    }),
  );
} catch (error) {
  fs.writeFileSync(
    path.join(output, "incomplete-report.json"),
    JSON.stringify(report, null, 2),
  );
  console.error("Isolated browser review failed:", error.message);
  process.exitCode = 1;
} finally {
  ws?.close();
  browser?.kill();
  if (server) {
    server.closeAllConnections();
    await new Promise((resolve) => server.close(resolve));
  }
  await fixture.close();
}
