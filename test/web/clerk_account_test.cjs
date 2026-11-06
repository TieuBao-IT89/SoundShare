const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const source = readFileSync(require('node:path').join(__dirname, '../../web/clerk-bridge.js'), 'utf8');

function bridge(clerk) {
  const window = { Clerk: clerk };
  vm.runInNewContext(source, { window });
  return window.soundshareAuth;
}

test('Account UI requires an active Clerk identity', () => {
  let opened = 0;
  for (const status of [undefined, 'pending', 'ended']) {
    const auth = bridge({ session: { status }, user: { id: 'fixture' }, openUserProfile() { opened++; } });
    assert.equal(auth.manageAccount(), false);
  }
  assert.equal(bridge(undefined).manageAccount(), false);
  assert.equal(bridge({ session: { status: 'active' } }).manageAccount(), false);
  assert.equal(opened, 0);
});

test('Active account opens Clerk profile without reading or changing tokens', () => {
  let opened = 0;
  const auth = bridge({
    session: { status: 'active', getToken() { assert.fail('Account UI must not request a token'); } },
    user: { id: 'fixture' },
    openUserProfile() { opened++; },
    signOut() { assert.fail('Account UI must not sign out'); },
  });
  assert.equal(auth.manageAccount(), true);
  assert.equal(opened, 1);
});

test('Unavailable Clerk UI returns false; provider failures reach safe Dart handling', () => {
  assert.equal(bridge({ session: { status: 'active' }, user: { id: 'fixture' } }).manageAccount(), false);
  const auth = bridge({ session: { status: 'active' }, user: { id: 'fixture' }, openUserProfile() { throw new Error('fixture failure'); } });
  assert.throws(() => auth.manageAccount(), /fixture failure/);
});
