// Clerk owns credentials, verification, recovery and session storage.
// Only short-lived tokens cross into Dart when an API request needs them.
(() => {
  let ready;
  const listeners = new Set();
  const navigate = (to, { windowNavigate }, replace = false) => {
    const current = new URL(window.location.href);
    const destination = new URL(to, current);
    // The dedicated auth document uses Clerk's supported hash routing. Mode
    // links change only its query; handle those in place without an unload.
    if (current.pathname.endsWith('/auth.html') && destination.origin === current.origin && destination.pathname === current.pathname && destination.search !== current.search && window.soundshareAuthPage) {
      window.history[replace ? 'replaceState' : 'pushState'](null, '', destination.href);
      return Promise.resolve().then(() => window.soundshareAuthPage.sync());
    }
    if (current.pathname.endsWith('/auth.html') && destination.origin === current.origin && destination.pathname === current.pathname && destination.search === current.search) {
      if (destination.href !== current.href) window.location[replace ? 'replace' : 'assign'](destination.href);
      return;
    }
    // Flutter uses hash routes. Clerk's default window navigation marks even a
    // hash-only redirect as unloading and skips publishing the activated session.
    const isFlutterRoute = destination.origin === current.origin
      && destination.pathname === current.pathname
      && destination.search === current.search
      && (!destination.hash || destination.hash.startsWith('#/'));
    if (!isFlutterRoute) return windowNavigate(destination);
    if (!destination.hash) destination.hash = '#/';
    if (destination.href === current.href) return;
    // Native hash navigation also emits popstate, which Flutter listens to.
    window.location[replace ? 'replace' : 'assign'](destination.href);
  };
  const snapshot = () => {
    const session = window.Clerk?.session;
    const user = session?.user || window.Clerk?.user;
    // Clerk can publish the user before activating their session. Wait for the
    // active session, and distinguish a replacement session for the same user.
    return JSON.stringify(session?.status === 'active' && session.id && user?.id
      ? { id: user.id, name: user.fullName || user.username || 'Người yêu nhạc', sessionId: session.id }
      : null);
  };
  window.soundshareAuth = {
    initialize(key) {
      if (!ready) ready = (async () => {
        if (!/^pk_(test|live)_[A-Za-z0-9_=-]+$/.test(key)) throw new Error('Sign-in configuration is unavailable.');
        // Public build configuration only; passwords, OTPs and tokens are never stored here.
        try { window.sessionStorage?.setItem('soundshare.clerk.publishableKey', key); } catch (_) { /* Handled by the auth entry page. */ }
        const loadScript = (source, publishableKey) => new Promise((resolve, reject) => {
          const script = document.createElement('script');
          script.src = source;
          script.async = true;
          script.crossOrigin = 'anonymous';
          if (publishableKey) script.dataset.clerkPublishableKey = publishableKey;
          script.onload = resolve;
          script.onerror = () => reject(new Error('Sign-in could not be loaded.'));
          document.head.appendChild(script);
        });
        // Core 3 separates the UI bundle. Protect requires ClerkJS >= 6.39.
        await loadScript('https://cdn.jsdelivr.net/npm/@clerk/ui@1.42.3/dist/ui.browser.js');
        await loadScript('https://cdn.jsdelivr.net/npm/@clerk/clerk-js@6.42.2/dist/clerk.browser.js', key);
        await window.Clerk.load({
          routerPush: (to, metadata) => navigate(to, metadata),
          routerReplace: (to, metadata) => navigate(to, metadata, true),
          localization: window.soundshareClerkVi,
          ui: { ClerkUI: window.__internal_ClerkUICtor },
          appearance: {
            // Supported Appearance variables reference our root tokens. A theme
            // change updates mounted OTP/recovery/account UI without a remount.
            variables: { colorPrimary: 'var(--auth-action)', colorPrimaryForeground: '#FFFFFF', colorBackground: 'var(--auth-surface)', colorInput: 'var(--auth-input)', colorForeground: 'var(--auth-text)', colorInputForeground: 'var(--auth-text)', colorMutedForeground: 'var(--auth-muted)', colorBorder: 'var(--auth-field-border)', colorDanger: 'var(--auth-error)', colorSuccess: 'var(--auth-cyan)', fontFamily: 'BeVietnamPro, sans-serif', fontSize: '14px', borderRadius: '.625rem' },
            options: { showOptionalFields: false },
            elements: {
              formFieldInput: { minHeight: '48px' },
              formFieldInputShowPasswordButton: { color: 'var(--auth-muted)', minWidth: '48px' },
              formButtonPrimary: { minHeight: '48px', color: '#FFFFFF', background: 'var(--auth-action)' },
              socialButtonsBlockButton: { minHeight: '48px', color: 'var(--auth-text)', backgroundColor: 'var(--auth-input)' },
              socialButtonsBlockButtonText: { color: 'var(--auth-text)' },
              modalContent: { maxHeight: 'calc(100dvh - 32px)', overflowY: 'auto' },
            },
          },
        });
        window.Clerk.addListener(() => { for (const listener of listeners) listener(snapshot()); });
      })().catch(() => { ready = null; throw new Error('Sign-in could not be loaded.'); });
      return ready.then(snapshot);
    },
    watch(listener) {
      listeners.add(listener);
      // Replay current state so a sign-in between initialize and watch is not lost.
      listener(snapshot());
    },
    unwatch(listener) { listeners.delete(listener); },
    async token(refresh) {
      const session = window.Clerk?.session;
      if (session?.status !== 'active') throw new Error('Sign in again.');
      const token = await session.getToken({ skipCache: refresh });
      if (!token) throw new Error('Sign in again.');
      return token;
    },
    async signOut() { await window.Clerk.signOut(); },
    manageAccount() {
      const clerk = window.Clerk;
      if (clerk?.session?.status !== 'active' || !clerk.user?.id || typeof clerk.openUserProfile !== 'function') return false;
      clerk.openUserProfile({});
      return true;
    },
    enter(mode = 'welcome') {
      const current = new URL(window.location.href);
      const url = new URL('auth.html', document.baseURI || current.href);
      url.searchParams.set('mode', ['sign-in', 'sign-up'].includes(mode) ? mode : 'welcome');
      url.searchParams.set('return', current.href);
      try {
        const pending = JSON.parse(window.sessionStorage?.getItem('soundshare.auth.entry') || 'null');
        window.sessionStorage?.removeItem('soundshare.auth.entry');
        if (pending && ['welcome', 'sign-in', 'sign-up'].includes(pending.mode)) {
          const target = new URL(pending.return, current);
          const base = new URL('./', url);
          if (target.origin === base.origin && [base.pathname, base.pathname + 'index.html'].includes(target.pathname) && (!target.hash || target.hash.startsWith('#/'))) {
            url.searchParams.set('mode', pending.mode);
            url.searchParams.set('return', target.href);
          }
        }
      } catch (_) { /* Invalid UI hints never affect session or token state. */ }
      window.location.replace(url.href);
    },
    open(mode) {
      window.soundshareAuth.enter(mode);
    },
  };
})();
