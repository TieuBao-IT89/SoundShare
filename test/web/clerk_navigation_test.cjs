const assert = require('node:assert/strict');
const { readFile } = require('node:fs/promises');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

async function fixture(href = 'http://localhost:3000/#/') {
  const events = [];
  const hashNavigations = [];
  const fullNavigations = [];
  let options;
  let listener;
  const window = {
    location: { href, origin: new URL(href).origin },
    Clerk: {
      session: null,
      user: null,
      load: async value => { options = value; },
      addListener: callback => { listener = callback; callback(); },
    },
  };
  for (const method of ['assign', 'replace']) {
    window.location[method] = url => {
      hashNavigations.push({ method, url });
      events.push({ oldURL: window.location.href, newURL: url });
      window.location.href = url;
    };
  }
  const document = {
    createElement: () => ({ dataset: {} }),
    head: { appendChild: script => queueMicrotask(script.onload) },
  };
  vm.runInNewContext(await readFile(path.join(__dirname, '../../web/clerk-bridge.js'), 'utf8'), {
    window, document, URL,
  });
  const bridge = window.soundshareAuth;
  await bridge.initialize('pk_test_fixture');
  const notifications = [];
  bridge.watch(value => notifications.push(JSON.parse(value)));
  const metadata = { windowNavigate: url => fullNavigations.push(url.href) };
  // Clerk Core 3 clears accessors during navigation. Its windowNavigate marks
  // unloading even for hash-only URLs, so setActive skips the final emission.
  async function activate(method, destination) {
    window.Clerk.session = undefined;
    window.Clerk.user = undefined;
    listener();
    await options[method](destination, metadata);
    if (fullNavigations.length) return;
    window.Clerk.user = { id: 'user_fixture', fullName: 'Fixture' };
    window.Clerk.session = {
      id: 'sess_fixture', status: 'active', user: window.Clerk.user,
      getToken: async () => 'fixture-token',
    };
    listener();
  }
  return { window, bridge, options, notifications, metadata, activate, events, hashNavigations, fullNavigations };
}

test('sign-in at the redirect URL publishes the active session without reload', async () => {
  const f = await fixture();
  assert.equal(f.notifications.at(-1), null);
  await f.activate('routerPush', '/#/');
  assert.deepEqual(f.notifications.at(-1), { id: 'user_fixture', name: 'Fixture', sessionId: 'sess_fixture' });
  assert.equal(await f.bridge.token(false), 'fixture-token');
  assert.deepEqual(f.fullNavigations, []);
  assert.deepEqual(f.hashNavigations, []);
  assert.deepEqual(f.events, []);
});

test('sign-in from a URL without a hash uses the Flutter root route', async () => {
  const f = await fixture('http://localhost:3000/');
  await f.activate('routerPush', '/#/');
  assert.equal(f.window.location.href, 'http://localhost:3000/#/');
  assert.equal(f.notifications.at(-1).sessionId, 'sess_fixture');
  assert.deepEqual(f.fullNavigations, []);
});

for (const method of ['routerPush', 'routerReplace']) {
  test(`${method} notifies Flutter and finishes activation after a hash route change`, async () => {
    const f = await fixture('http://localhost:3000/#/library');
    await f.activate(method, 'http://localhost:3000/#/');
    assert.equal(f.notifications.at(-1).sessionId, 'sess_fixture');
    assert.deepEqual(f.fullNavigations, []);
    assert.equal(f.hashNavigations[0].method, method === 'routerPush' ? 'assign' : 'replace');
    assert.equal(f.events.length, 1);
    assert.equal(f.events[0].oldURL, 'http://localhost:3000/#/library');
    assert.equal(f.events[0].newURL, 'http://localhost:3000/#/');
  });
}

test('root sign-out navigation stays within Flutter', async () => {
  const f = await fixture('http://localhost:3000/#/profile');
  await f.options.routerPush('/', f.metadata);
  assert.equal(f.window.location.href, 'http://localhost:3000/#/');
  assert.deepEqual(f.fullNavigations, []);
  assert.equal(f.hashNavigations[0].method, 'assign');
});

test('external URLs, Clerk callbacks and document changes keep full navigation', async () => {
  for (const destination of [
    'https://fixture.clerk.accounts.dev/v1/client/touch?redirect_url=fixture',
    '/?__clerk_synced=true#/', '/sso-callback', '/#verification',
  ]) {
    const f = await fixture();
    await f.options.routerPush(destination, f.metadata);
    assert.deepEqual(f.fullNavigations, [new URL(destination, f.window.location.href).href]);
    assert.deepEqual(f.hashNavigations, []);
    assert.deepEqual(f.events, []);
  }
});
