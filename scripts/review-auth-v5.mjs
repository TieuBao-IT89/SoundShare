// Opt-in, read-only live Clerk form review. Never enters credentials, submits
// a signup, starts OAuth, or reuses the user's Chrome profile. Public build key
// comes from the existing ignored client configuration, not a URL parameter.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from '../backend/node_modules/express/index.js';
import { createApp } from '../backend/src/app.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, process.env.QA_BEFORE ? 'build/auth-v5-before' : process.env.QA_INTERACTIONS ? 'build/auth-v5-interactions' : 'build/auth-v5-review');
fs.mkdirSync(output, { recursive: true });
const config = JSON.parse(fs.readFileSync(path.join(root, '.local/web-config.json'), 'utf8'));
const key = config.CLERK_PUBLISHABLE_KEY;
assert.match(key, /^pk_(test|live)_[A-Za-z0-9_=-]+$/);
const domain = Buffer.from(key.replace(/^pk_(test|live)_/, ''), 'base64').toString().replace(/\$$/, '');
assert.match(domain, /^[a-z0-9.-]+$/i);
const browserOrigin = 'http://localhost:3000';
const report = { scope: 'Real Clerk UI, read-only, no credentials/OAuth/OTP submitted; new owned Chrome profile.', screenshots: [], checks: [], exceptions: [], failures: [] };
const app = express();
app.use('/assets/assets/fonts', express.static(path.join(root, 'assets/fonts')));
app.use(createApp({ logging: false, clerkOptions: { issuer: `https://${domain}` }, webDirectory: path.join(root, process.env.QA_BEFORE ? 'build/web' : process.env.QA_BUILT ? 'build/auth-v5-web' : 'web') }));
let browser, ws;
const server = app.listen(0, '127.0.0.1');
await once(server, 'listening');
const origin = `http://127.0.0.1:${server.address().port}`;
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
try {
  const profile = fs.mkdtempSync(path.join(output, 'chrome-owned-'));
  browser = spawn(process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe', [
    '--headless=new', '--no-first-run', '--remote-debugging-port=0', '--remote-allow-origins=*', '--user-data-dir=' + profile, 'about:blank',
  ], { windowsHide: true, stdio: 'ignore' });
  let page;
  for (let i = 0; i < 60; i++) {
    try {
      const port = fs.readFileSync(path.join(profile, 'DevToolsActivePort'), 'utf8').split('\n')[0];
      page = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find(item => item.type === 'page');
      if (page) break;
    } catch (_) { /* Only the profile created above is inspected. */ }
    await sleep(200);
  }
  assert.ok(page, 'Owned Chrome must start');
  ws = new WebSocket(page.webSocketDebuggerUrl);
  await once(ws, 'open');
  const pending = new Map(); let id = 0;
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const number = ++id;
    const timer = setTimeout(() => { pending.delete(number); reject(new Error(`CDP timeout: ${method}`)); }, 30000);
    pending.set(number, { resolve, reject, timer });
    ws.send(JSON.stringify({ id: number, method, params }));
  });
  ws.addEventListener('message', async event => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const item = pending.get(message.id); pending.delete(message.id); clearTimeout(item.timer);
      if (message.error) item.reject(new Error(message.error.message)); else item.resolve(message.result);
    }
    if (message.method === 'Runtime.exceptionThrown') report.exceptions.push(message.params.exceptionDetails.text);
    if (message.method === 'Fetch.requestPaused') {
      const { requestId, request } = message.params;
      try {
        const url = new URL(request.url);
        const response = await fetch(origin + url.pathname + url.search, { signal: AbortSignal.timeout(15000) });
        if (!response.ok) report.failures.push({ path: url.pathname, status: response.status });
        await send('Fetch.fulfillRequest', { requestId, responseCode: response.status,
          responseHeaders: [...response.headers].filter(([name]) => !['transfer-encoding', 'content-length', 'content-encoding'].includes(name)).map(([name, value]) => ({ name, value })),
          body: Buffer.from(await response.arrayBuffer()).toString('base64') });
      } catch (_) { report.failures.push({ type: 'local-response' }); await send('Fetch.failRequest', { requestId, errorReason: 'Failed' }); }
    }
  });
  const evaluate = async expression => {
    const value = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (value.exceptionDetails) throw new Error('Browser evaluation failed');
    return value.result.value;
  };
  await send('Page.enable'); await send('Runtime.enable');
  await send('Fetch.enable', { patterns: [{ urlPattern: browserOrigin + '/*' }] });
  const seedScript = await send('Page.addScriptToEvaluateOnNewDocument', { source: `sessionStorage.setItem('soundshare.clerk.publishableKey',${JSON.stringify(key)});window.__csp=[];document.addEventListener('securitypolicyviolation',e=>window.__csp.push(e.effectiveDirective));` });
  const widths = process.env.QA_WIDTH ? [Number(process.env.QA_WIDTH)] : [320,390,430,768,1024,1280,1440];
  for (const width of widths) {
    assert.ok([320,390,430,768,1024,1280,1440].includes(width));
    const height = width === 430 ? 932 : width < 768 ? 844 : 960;
    await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: width < 768 });
    if (process.env.QA_BEFORE) {
      await send('Page.navigate', { url: browserOrigin + '/#/' });
      for (let retry=0;retry<100;retry++) {
        if (await evaluate('!!window.Clerk?.loaded')) break;
        await sleep(300);
      }
      assert.ok(await evaluate('!!window.Clerk?.loaded'), 'Before build must load real Clerk');
      await sleep(1500);
      for (const mode of ['welcome','sign-in','sign-up']) {
        if (mode==='sign-in') await evaluate('window.Clerk.openSignIn({});true');
        if (mode==='sign-up') { await evaluate('window.Clerk.closeSignIn();true'); await sleep(300); await evaluate('window.Clerk.openSignUp({});true'); }
        if (mode!=='welcome') for(let retry=0;retry<100;retry++) { if(await evaluate('document.querySelectorAll("input").length>0'))break;await sleep(200); }
        if (mode!=='welcome') assert.ok(await evaluate('document.querySelectorAll("input").length>0'), 'Before Clerk form must render');
        await sleep(700);
        const shot=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});
        const name=`${mode}-${width}.png`;
        fs.writeFileSync(path.join(output,name),Buffer.from(shot.data,'base64'));
        report.screenshots.push(name);
      }
      await evaluate('window.Clerk.closeSignUp();true');
      report.checks.push({width,before:'Preserved pre-V5 build, real Clerk welcome and modal forms, no credentials'});
      continue;
    }
    for (const mode of ['welcome', 'sign-in', 'sign-up']) {
      await send('Page.navigate', { url: browserOrigin + '/auth.html?mode=' + mode });
      let state;
      for (let retry = 0; retry < 100; retry++) {
        state = await evaluate(`({ready:document.readyState==='complete'&&!!window.Clerk?.loaded,fields:document.querySelectorAll('#clerk-auth input').length,error:document.querySelector('#auth-error')?.hidden===false})`);
        if ((mode === 'welcome' && state.ready) || state.fields > 0 || state.error) break;
        await sleep(300);
      }
      await evaluate('document.fonts.ready.then(()=>true)');
      await sleep(500);
      const name = `${mode}-${width}.png`;
      const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
      fs.writeFileSync(path.join(output, name), Buffer.from(shot.data, 'base64'));
      report.screenshots.push(name);
      const bounds = await evaluate(`({overflow:document.documentElement.scrollWidth>innerWidth,csp:window.__csp,mode:document.body.dataset.mode,modal:!!document.querySelector('[role="dialog"]'),sdk:window.Clerk?.version,inputs:[...document.querySelectorAll('#clerk-auth input')].map(x=>({type:x.type,width:x.getBoundingClientRect().width})),google:[...document.querySelectorAll('button')].some(x=>x.textContent.includes('Google'))})`);
      assert.equal(state.error, false, 'Clerk UI must load');
      if (mode !== 'welcome') assert.ok(state.fields > 0, 'Real Clerk form must render');
      assert.equal(bounds.overflow, false, 'No horizontal overflow');
      assert.equal(bounds.modal, false, 'Auth is embedded, not a modal');
      assert.deepEqual(bounds.csp, []);
      report.checks.push({ width, mode, ...bounds });
      console.log(`${width}px ${mode}: actual Clerk UI rendered, no modal/overflow`);
    }
  }
  if (process.env.QA_INTERACTIONS) {
    const waitFor = async (expression, label) => {
      for (let retry = 0; retry < 100; retry++) {
        if (await evaluate(expression)) return;
        await sleep(200);
      }
      report.interactionFailure = await evaluate(`({href:location.href,mode:document.body.dataset.mode,error:document.getElementById('auth-error')?.hidden,content:document.getElementById('clerk-auth')?.textContent,ready:window.Clerk?.loaded})`);
      const diagnostic = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
      fs.writeFileSync(path.join(output, 'interaction-failure.png'), Buffer.from(diagnostic.data, 'base64'));
      throw new Error(label);
    };
    const timeOrigin = await evaluate('performance.timeOrigin');
    await evaluate(`(()=>{const a=[...document.querySelectorAll('#clerk-auth a')].find(a=>a.href.includes('mode=sign-in'));if(!a)throw Error('Missing sign-in link');a.click();return true})()`);
    await waitFor(`document.body.dataset.mode==='sign-in'&&document.querySelectorAll('#clerk-auth input').length>0`, 'Sign-up to sign-in must render');
    assert.equal(await evaluate('performance.timeOrigin'), timeOrigin, 'Mode navigation does not reload the document');
    await evaluate('history.back();true');
    await waitFor(`document.body.dataset.mode==='sign-up'&&!!document.querySelector('#clerk-auth input[type="password"]')`, 'Back restores signup');
    await evaluate('history.forward();true');
    await waitFor(`document.body.dataset.mode==='sign-in'&&document.querySelectorAll('#clerk-auth input').length>0`, 'Forward restores signin');
    await send('Page.reload'); await sleep(1000);
    await waitFor(`document.body.dataset.mode==='sign-in'&&document.querySelectorAll('#clerk-auth input').length>0`, 'F5 restores signin');
    const hash = await evaluate('location.hash');
    await evaluate(`document.getElementById('auth-skip').click();true`);
    assert.equal(await evaluate('location.hash'), hash, 'Skip control does not change Clerk hash');
    assert.equal(await evaluate('document.activeElement.id'), 'auth-content');
    await evaluate(`document.querySelector('#clerk-auth input').focus();true`);
    assert.ok(await evaluate(`document.querySelector('#clerk-auth input').getBoundingClientRect().height>=48`));
    await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    assert.ok(await evaluate(`parseFloat(getComputedStyle(document.querySelector('.auth-welcome')).animationDuration)<=0.001`));
    report.checks.push({ interactions: 'Live Clerk SignUp to SignIn, browser back/forward, F5, skip focus without hash changes, 48px input and reduced motion', passed: true });
    if (process.env.QA_BUILT) {
      await send('Page.navigate', { url: browserOrigin + '/#/profile' });
      await waitFor(`location.pathname==='/auth.html'&&document.body.dataset.mode==='welcome'&&!!window.Clerk?.loaded`, 'Signed-out Flutter must enter the dedicated welcome page');
      assert.equal(await evaluate(`new URL(location.href).searchParams.get('return')`), browserOrigin + '/#/profile');
      report.checks.push({ interactions: 'Actual release Flutter signed-out gate enters auth.html and preserves protected profile deep link', passed: true });
      await send('Page.removeScriptToEvaluateOnNewDocument', { identifier: seedScript.identifier });
      await evaluate(`sessionStorage.removeItem('soundshare.clerk.publishableKey');sessionStorage.removeItem('soundshare.auth.entry');true`);
      await send('Page.navigate', { url: browserOrigin + '/auth.html?mode=sign-up&return=' + encodeURIComponent(browserOrigin + '/#/profile') });
      await waitFor(`location.pathname==='/auth.html'&&document.body.dataset.mode==='sign-up'&&document.querySelectorAll('#clerk-auth input').length>0`, 'A fresh bookmark must bootstrap the trusted Flutter build configuration and restore signup');
      assert.equal(await evaluate(`new URL(location.href).searchParams.get('return')`), browserOrigin + '/#/profile');
      report.checks.push({ interactions: 'First auth bookmark with no stored configuration bootstraps Flutter and returns to signup with protected deep link intact', passed: true });
    }
  }
  assert.deepEqual(report.exceptions, []);
  assert.deepEqual(report.failures, []);
  fs.writeFileSync(path.join(output, 'report.json'), JSON.stringify(report, null, 2));
} catch (error) {
  fs.writeFileSync(path.join(output, 'incomplete-report.json'), JSON.stringify(report, null, 2));
  console.error('Auth review failed:', error.message);
  process.exitCode = 1;
} finally {
  ws?.close(); browser?.kill(); server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
}
