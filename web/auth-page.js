// This document owns Clerk's hash router. Flutter is not mounted here.
(() => {
  const auth = window.soundshareAuth;
  const root = document.getElementById('clerk-auth');
  const welcome = document.getElementById('auth-welcome');
  const status = document.getElementById('auth-status');
  const error = document.getElementById('auth-error');
  let mountedMode = null;
  let mountedNode = null;
  let initialized = false;
  let initializing;
  let mountAttempt = 0;
  let timeout;
  let observer;
  let signedIn = false;
  const mode = () => {
    const value = new URL(window.location.href).searchParams.get('mode');
    return ['sign-in', 'sign-up'].includes(value) ? value : 'welcome';
  };
  const destination = () => {
    const base = new URL('./', window.location.href);
    const fallback = new URL('#/', base);
    try {
      const candidate = new URL(new URL(window.location.href).searchParams.get('return') || fallback.href, base);
      return candidate.origin === base.origin &&
        [base.pathname, base.pathname + 'index.html'].includes(candidate.pathname) &&
        (!candidate.hash || candidate.hash.startsWith('#/')) ? candidate.href : fallback.href;
    } catch (_) { return fallback.href; }
  };
  const urlFor = (next) => {
    const url = new URL(window.location.href);
    url.hash = '';
    url.searchParams.set('mode', next);
    url.searchParams.set('return', destination());
    return url;
  };
  const unmount = () => {
    mountAttempt++;
    clearTimeout(timeout);
    observer?.disconnect();
    if (mountedMode === 'sign-in') window.Clerk.unmountSignIn(mountedNode);
    if (mountedMode === 'sign-up') window.Clerk.unmountSignUp(mountedNode);
    // Clerk owns the descendants. Detach only our outer container, never
    // clear a React tree while Clerk's unmount is still being committed.
    mountedNode?.remove();
    mountedMode = null;
    mountedNode = null;
  };
  const fail = () => {
    unmount();
    root.hidden = status.hidden = welcome.hidden = true;
    error.hidden = false;
  };
  const sync = () => {
    if (signedIn) return;
    const next = mode();
    document.body.dataset.mode = next;
    document.title = next === 'sign-up' ? 'Tạo tài khoản — SoundShare' : next === 'sign-in' ? 'Đăng nhập — SoundShare' : 'SoundShare — Không gian âm nhạc của riêng bạn';
    welcome.hidden = next !== 'welcome';
    error.hidden = true;
    if (next === 'welcome') {
      unmount();
      root.hidden = status.hidden = true;
      return;
    }
    if (mountedMode === next) return; // Keep OTP/recovery/MFA state on hash changes.
    unmount();
    if (!initialized) { status.hidden = false; root.hidden = true; return; }
    root.hidden = false;
    status.hidden = false;
    const attempt = mountAttempt;
    const options = {
      routing: 'hash',
      signInUrl: urlFor('sign-in').href,
      signUpUrl: urlFor('sign-up').href,
      fallbackRedirectUrl: destination(),
      forceRedirectUrl: destination(),
      signInForceRedirectUrl: destination(),
      signUpForceRedirectUrl: destination(),
      appearance: { elements: { rootBox: 'ss-clerk-root', cardBox: 'ss-clerk-box', card: 'ss-clerk-card', headerTitle: 'ss-clerk-title', headerSubtitle: 'ss-clerk-subtitle', formFieldInput: 'ss-clerk-input', formButtonPrimary: 'ss-clerk-primary', footer: 'ss-clerk-footer' } },
    };
    try {
      mountedMode = next;
      const node = document.createElement('div');
      mountedNode = node;
      root.appendChild(node);
      if (next === 'sign-in') window.Clerk.mountSignIn(node, options);
      else window.Clerk.mountSignUp(node, options);
      const wait = new MutationObserver(() => {
        if (node.childElementCount && attempt === mountAttempt) {
          status.hidden = true;
          clearTimeout(timeout);
          wait.disconnect();
        }
      });
      observer = wait;
      wait.observe(node, { childList: true, subtree: true });
      if (node.childElementCount) { status.hidden = true; wait.disconnect(); }
      timeout = setTimeout(() => { wait.disconnect(); if (attempt === mountAttempt && !status.hidden) fail(); }, 25000);
    } catch (_) { fail(); }
  };
  const receive = (value) => {
    if (signedIn) return;
    if (JSON.parse(value)) {
      signedIn = true;
      unmount();
      root.hidden = welcome.hidden = error.hidden = true;
      status.hidden = false;
      status.querySelector('p').textContent = 'Đang kết nối tài khoản của bạn…';
      window.location.replace(destination());
    }
  };
  const initialize = async () => {
    if (initializing) return initializing;
    if (!error.hidden) {
      error.hidden = welcome.hidden = root.hidden = true;
      status.hidden = false;
    }
    initializing = (async () => {
      let key;
      try { key = window.sessionStorage.getItem('soundshare.clerk.publishableKey'); } catch (_) { /* Storage may be unavailable. */ }
      if (!key) {
        // A first visit/bookmark can bootstrap the trusted public build config
        // through Flutter once. A blocked storage area gets an error, not a loop.
        try {
          window.sessionStorage.setItem('soundshare.auth.entry', JSON.stringify({ mode: mode(), return: destination() }));
          window.location.replace(new URL('./#/', window.location.href).href);
          return;
        } catch (_) { /* Display the accessible configuration error below. */ }
        welcome.hidden = true;
        document.getElementById('auth-error-message').textContent = 'Mở SoundShare để tải cấu hình đăng nhập cho phiên duyệt này.';
        fail();
        return;
      }
      try {
        let initializationTimeout;
        const value = await Promise.race([
          auth.initialize(key),
          new Promise((_, reject) => { initializationTimeout = setTimeout(() => reject(new Error('timeout')), 25000); }),
        ]).finally(() => clearTimeout(initializationTimeout));
        initialized = true;
        receive(value);
        if (!signedIn) { auth.watch(receive); sync(); }
      } catch (_) { fail(); }
    })().finally(() => { initializing = null; });
    return initializing;
  };
  window.soundshareAuthPage = { sync };
  document.addEventListener('click', (event) => {
    const link = event.target.closest('[data-auth-mode]');
    if (!link || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    window.history.pushState(null, '', urlFor(link.dataset.authMode));
    sync();
    document.getElementById('auth-content').focus({ preventScroll: true });
    if (!initialized) initialize();
  });
  window.addEventListener('popstate', sync);
  window.addEventListener('hashchange', sync);
  window.addEventListener('pagehide', (event) => {
    if (event?.persisted) return; // Preserve the provider form in back/forward cache.
    auth.unwatch(receive); unmount();
  });
  // Do not use an anchor hash: that belongs to Clerk's verification router.
  document.getElementById('auth-skip').addEventListener('click', () => document.getElementById('auth-content').focus());
  document.getElementById('auth-retry').addEventListener('click', () => { initialized = false; initialize(); });
  sync();
  initialize();
})();
