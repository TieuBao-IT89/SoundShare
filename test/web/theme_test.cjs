const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../../web/theme.js'), 'utf8');

function fixture({ saved = null, dark = false, blocked = false } = {}) {
  const storage = new Map(saved == null ? [] : [['soundshare.themeMode', saved]]);
  const handlers = {}, media = { matches: dark, addEventListener: (_, fn) => { handlers.media = fn; } };
  const root = { dataset: {}, style: {} }, meta = { setAttribute: (_, v) => { meta.value = v; } };
  const toggle = { checked: false, addEventListener: (_, fn) => { handlers.toggle = fn; } };
  const system = { pressed: 'false', setAttribute: (_, value) => { system.pressed = value; }, addEventListener: (_, fn) => { handlers.system = fn; } };
  const status = { hidden: true };
  const window = {
    matchMedia: () => media,
    localStorage: { getItem: key => { if (blocked) throw Error('unavailable'); return storage.get(key) ?? null; }, setItem: (key, value) => { if (blocked) throw Error('unavailable'); storage.set(key, value); } },
    addEventListener: (name, fn) => { handlers[name] = fn; },
  };
  const document = { documentElement: root, querySelector: () => meta,
    getElementById: id => id === 'auth-theme' ? toggle : id === 'auth-theme-system' ? system : status,
    addEventListener: (name, fn) => { handlers[name] = fn; } };
  vm.runInNewContext(source, { window, document });
  return { root, meta, toggle, system, status, window, media, storage, handlers };
}

test('First paint is Pearl even on a dark OS; explicit persisted mode wins at F5', () => {
  assert.equal(fixture({ dark: true }).root.dataset.theme, 'light');
  const f = fixture();
  assert.equal(f.window.soundshareTheme.chooseMode('dark'), true);
  assert.equal(f.root.style.colorScheme, 'dark');
  assert.equal(f.meta.value, '#080A12');
  const refreshed = fixture({ saved: f.storage.get('soundshare.themeMode') });
  assert.equal(refreshed.root.dataset.theme, 'dark');
  assert.equal(refreshed.toggle.checked, true);
  for (const saved of ['invalid', '"unknown"', '42', 'null']) assert.equal(fixture({ saved }).root.dataset.theme, 'light');
});

test('System mode follows live OS changes; explicit light stays light', () => {
  const f = fixture({ saved: '"system"', dark: true });
  assert.equal(f.root.dataset.theme, 'dark');
  assert.equal(f.toggle.checked, true);
  assert.equal(f.system.pressed, 'true');
  f.media.matches = false; f.handlers.media();
  assert.equal(f.root.dataset.theme, 'light');
  assert.equal(f.toggle.checked, false);
  f.window.soundshareTheme.setMode('light');
  f.media.matches = true; f.handlers.media();
  assert.equal(f.root.dataset.theme, 'light');
});

test('Auth control persists without navigating or remounting provider forms', () => {
  const f = fixture();
  f.handlers.DOMContentLoaded();
  f.handlers.toggle({ target: { checked: true } });
  assert.equal(f.root.dataset.theme, 'dark');
  assert.equal(f.storage.get('soundshare.themeMode'), '"dark"');
});

test('Blocked storage keeps the UI usable and reports failure', () => {
  const f = fixture({ blocked: true });
  assert.equal(f.root.dataset.theme, 'light');
  f.handlers.DOMContentLoaded();
  f.handlers.toggle({ target: { checked: true } });
  assert.equal(f.root.dataset.theme, 'dark');
  assert.equal(f.status.hidden, false);
});

test('Automatic button toggles system tracking; the switch pins a manual choice', () => {
  const f = fixture({ dark: true });
  f.handlers.DOMContentLoaded();
  f.handlers.system();
  assert.equal(f.window.soundshareTheme.mode, 'system');
  assert.equal(f.toggle.checked, true);
  assert.equal(f.system.pressed, 'true');
  f.handlers.system();
  assert.equal(f.window.soundshareTheme.mode, 'dark');
  assert.equal(f.system.pressed, 'false');
  f.handlers.system();
  f.handlers.toggle({ target: { checked: false } });
  assert.equal(f.window.soundshareTheme.mode, 'light');
  assert.equal(f.system.pressed, 'false');
  f.media.matches = false; f.handlers.media();
  f.media.matches = true; f.handlers.media();
  assert.equal(f.root.dataset.theme, 'light');
  assert.equal(f.storage.get('soundshare.themeMode'), '"light"');
});
