// Clerk owns credentials, verification, recovery and session storage.
// Only short-lived tokens cross into Dart when an API request needs them.
(() => {
  let ready;
  const listeners = new Set();
  const navigate = (to, { windowNavigate }, replace = false) => {
    const current = new URL(window.location.href);
    const destination = new URL(to, current);
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
            variables: { colorPrimary: '#6742BF', colorPrimaryForeground: '#FFFFFF', colorBackground: '#11131D', colorInput: '#1B1D29', colorForeground: '#F7F7FA', colorInputForeground: '#F7F7FA', colorMutedForeground: '#9B9EAE', colorDanger: '#F47187', fontFamily: 'BeVietnamPro, sans-serif', borderRadius: '.75rem' },
            options: { showOptionalFields: true },
            elements: {
              formFieldInput: { minHeight: '48px' },
              formFieldInputShowPasswordButton: { color: '#9B9EAE', minWidth: '48px' },
              formButtonPrimary: { minHeight: '48px', color: '#FFFFFF', background: '#6742BF' },
              socialButtonsBlockButton: { minHeight: '48px', color: '#F7F7FA', backgroundColor: '#1B1D29' },
              socialButtonsBlockButtonText: { color: '#F7F7FA' },
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
    open(mode) {
      const options = { fallbackRedirectUrl: window.location.origin + '/#/', forceRedirectUrl: window.location.origin + '/#/' };
      if (mode === 'sign-up') window.Clerk.openSignUp(options);
      else window.Clerk.openSignIn(options);
    },
  };
})();
