// Runs synchronously before CSS/Flutter. Only a UI preference is stored here.
(() => {
  const key = 'soundshare.themeMode'; // SharedPreferencesAsync on Web uses JSON strings.
  const media = window.matchMedia('(prefers-color-scheme: dark)');
  const valid = value => ['light', 'dark', 'system'].includes(value) ? value : 'light';
  let mode = 'light';
  try { mode = valid(JSON.parse(window.localStorage.getItem(key))); } catch (_) { /* Light is the first-visit fallback. */ }
  const apply = () => {
    const theme = mode === 'system' ? (media.matches ? 'dark' : 'light') : mode;
    const root = document.documentElement;
    root.dataset.theme = theme;
    root.dataset.themeMode = mode;
    root.style.colorScheme = theme;
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', theme === 'dark' ? '#080A12' : '#F7F8FC');
    const toggle = document.getElementById('auth-theme');
    if (toggle) toggle.checked = theme === 'dark';
    document.getElementById('auth-theme-system')?.setAttribute('aria-pressed', String(mode === 'system'));
  };
  const setMode = value => { mode = valid(value); apply(); };
  window.soundshareTheme = {
    setMode,
    get mode() { return mode; },
    chooseMode(value) {
      setMode(value);
      try { window.localStorage.setItem(key, JSON.stringify(mode)); return true; }
      catch (_) { return false; }
    },
  };
  media.addEventListener('change', () => { if (mode === 'system') apply(); });
  const choose = value => {
    const saved = window.soundshareTheme.chooseMode(value);
    const status = document.getElementById('auth-theme-status');
    if (status) status.hidden = saved;
  };
  document.addEventListener('DOMContentLoaded', () => {
    apply();
    document.getElementById('auth-theme')?.addEventListener('change', event => {
      choose(event.target.checked ? 'dark' : 'light');
    });
    document.getElementById('auth-theme-system')?.addEventListener('click', () => {
      choose(mode === 'system' ? (media.matches ? 'dark' : 'light') : 'system');
    });
  });
  apply();
})();
