const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const test = require('node:test');
const source = readFileSync(path.join(__dirname, '../../web/auth-page.js'), 'utf8');

async function fixture({ mode = 'sign-in', target, missingKey = false, failure = false, active = false, writable = false } = {}) {
  let href = `http://localhost:3000/auth.html?mode=${mode}` + (target ? `&return=${encodeURIComponent(target)}` : '');
  const mounted = [], unmounted = [], redirects = [], handlers = {}, timers = new Map();
  let watch, timer = 0;
  const stored = new Map();
  const element = () => ({ hidden: false, childElementCount: 0, textContent: '',
    replaceChildren() { this.childElementCount = 0; }, querySelector() { return this; }, focus() {},
    appendChild(node) { this.childElementCount++; node.parent = this; },
    remove() { if (this.parent) this.parent.childElementCount--; },
    addEventListener(event, callback) { this[event] = callback; } });
  const elements = Object.fromEntries(['clerk-auth', 'auth-welcome', 'auth-status', 'auth-error', 'auth-error-message', 'auth-content', 'auth-retry', 'auth-skip'].map(id => [id, element()]));
  const window = {
    location: { get href() { return href; }, replace: to => redirects.push(to) },
    history: { pushState: (_, __, to) => { href = String(to); } },
    sessionStorage: { getItem: () => missingKey ? null : 'pk_test_fixture', ...(writable ? { setItem: (key, value) => stored.set(key, value) } : {}) },
    addEventListener: (name, callback) => { handlers[name] = callback; },
    Clerk: {},
    soundshareAuth: {
      initialize: async () => { if (failure) throw new Error('private provider failure'); return active ? '{"id":"fixture"}' : 'null'; },
      watch: callback => { watch = callback; }, unwatch() {},
    },
  };
  for (const modeName of ['SignIn', 'SignUp']) {
    window.Clerk[`mount${modeName}`] = (root, options) => { mounted.push({ mode: modeName, options }); root.childElementCount = 1; };
    window.Clerk[`unmount${modeName}`] = () => unmounted.push(modeName);
  }
  const document = { body: { dataset: {} }, createElement: element, getElementById: id => elements[id], addEventListener: (name, callback) => { handlers[name] = callback; } };
  vm.runInNewContext(source, { window, document, URL, Promise,
    MutationObserver: class { observe() {} disconnect() {} },
    setTimeout: callback => { timers.set(++timer, callback); return timer; }, clearTimeout: id => timers.delete(id),
  });
  const flush = async () => { for (let i = 0; i < 15; i++) await Promise.resolve(); };
  await flush();
  const navigate = async (next, hash = '') => {
    href = `http://localhost:3000/auth.html?mode=${next}${hash}`;
    handlers.popstate(); await flush();
  };
  return { window, document, elements, mounted, unmounted, redirects, handlers, navigate, flush, stored, receive: value => watch?.(JSON.stringify(value)) };
}

test('embedded forms use Clerk hash routing and unmount only when the auth mode changes', async () => {
  const f = await fixture();
  assert.equal(f.mounted[0].mode, 'SignIn');
  assert.equal(f.mounted[0].options.routing, 'hash');
  assert.equal(f.elements['auth-status'].hidden, true);
  await f.navigate('sign-in', '#/verify-email-address');
  assert.equal(f.mounted.length, 1, 'verification/recovery keeps the mounted form');
  await f.navigate('sign-up');
  assert.deepEqual(f.unmounted, ['SignIn']);
  assert.equal(f.mounted.at(-1).mode, 'SignUp');
  await f.navigate('welcome');
  assert.equal(f.elements['auth-welcome'].hidden, false);
  assert.deepEqual(f.unmounted, ['SignIn', 'SignUp']);
});

test('session completion returns once to the protected Flutter deep link', async () => {
  const f = await fixture({ target: 'http://localhost:3000/#/u/creator' });
  f.receive({ id: 'fixture' }); f.receive({ id: 'fixture' });
  assert.deepEqual(f.redirects, ['http://localhost:3000/#/u/creator']);
  assert.deepEqual(f.unmounted, ['SignIn']);
});

test('open redirects and auth-document return loops fall back to the Flutter root', async () => {
  for (const target of ['https://evil.invalid/', 'javascript:alert(1)', 'http://localhost:3000/auth.html', 'http://localhost:3000/#not-flutter']) {
    const f = await fixture({ target, active: true });
    assert.deepEqual(f.redirects, ['http://localhost:3000/#/']);
    assert.equal(f.mounted.length, 0);
  }
});

test('loading and missing configuration have safe errors and never create a redirect loop', async () => {
  for (const options of [{ failure: true }, { missingKey: true }]) {
    const f = await fixture(options);
    assert.equal(f.elements['auth-error'].hidden, false);
    assert.equal(f.elements['auth-status'].hidden, true);
    assert.equal(f.mounted.length, 0);
    assert.deepEqual(f.redirects, []);
    assert.ok(!f.elements['auth-error-message'].textContent.includes('private provider'));
  }
});

test('welcome does not mount an auth form and browser back restores the previous mode', async () => {
  const f = await fixture({ mode: 'welcome' });
  assert.equal(f.mounted.length, 0);
  await f.navigate('sign-up');
  assert.equal(f.mounted.at(-1).mode, 'SignUp');
  await f.navigate('sign-in');
  assert.equal(f.mounted.at(-1).mode, 'SignIn');
  f.handlers.pagehide({ persisted: true });
  assert.deepEqual(f.unmounted, ['SignUp']);
  f.handlers.pagehide();
  assert.deepEqual(f.unmounted, ['SignUp', 'SignIn']);
});

test('a fresh bookmark bootstraps public build configuration while retaining only safe UI intent', async () => {
  const f = await fixture({ mode: 'sign-up', missingKey: true, writable: true, target: 'http://localhost:3000/#/profile' });
  assert.deepEqual(f.redirects, ['http://localhost:3000/#/']);
  assert.equal(f.mounted.length, 0);
  assert.deepEqual(JSON.parse(f.stored.get('soundshare.auth.entry')), { mode: 'sign-up', return: 'http://localhost:3000/#/profile' });
  assert.equal(f.stored.size, 1);
});
