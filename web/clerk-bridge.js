// Clerk owns credentials, verification, recovery and session storage.
// Only short-lived tokens cross into Dart when an API request needs them.
(() => {
  let ready;
  const listeners = new Set();
  const snapshot = () => {
    const user = window.Clerk?.user;
    return JSON.stringify(user ? { id: user.id, name: user.fullName || user.username || 'Music lover' } : null);
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
          ui: { ClerkUI: window.__internal_ClerkUICtor },
          appearance: {
            variables: { colorPrimary: '#9B7BFF', colorPrimaryForeground: '#171220', colorBackground: '#17171F', colorInput: '#22222D', colorForeground: '#F5F3FA', colorInputForeground: '#F5F3FA', colorMutedForeground: '#B5B3BF', fontFamily: 'Roboto, sans-serif', borderRadius: '1rem' },
            options: { showOptionalFields: true },
            elements: {
              formFieldInput: { minHeight: '48px' },
              formFieldInputShowPasswordButton: { color: '#B5B3BF', minWidth: '48px' },
              formButtonPrimary: { minHeight: '48px', color: '#171220' },
              socialButtonsBlockButton: { minHeight: '48px', color: '#F5F3FA', backgroundColor: '#22222D' },
              socialButtonsBlockButtonText: { color: '#F5F3FA' },
              modalContent: { maxHeight: 'calc(100dvh - 32px)', overflowY: 'auto' },
            },
          },
        });
        window.Clerk.addListener(() => { for (const listener of listeners) listener(snapshot()); });
      })().catch(() => { ready = null; throw new Error('Sign-in could not be loaded.'); });
      return ready.then(snapshot);
    },
    watch(listener) { listeners.add(listener); },
    unwatch(listener) { listeners.delete(listener); },
    async token(refresh) {
      const token = await window.Clerk?.session?.getToken({ skipCache: refresh });
      if (!token) throw new Error('Sign in again.');
      return token;
    },
    async signOut() { await window.Clerk.signOut(); },
    open(mode) {
      const options = { fallbackRedirectUrl: window.location.origin + '/#/', forceRedirectUrl: window.location.origin + '/#/' };
      if (mode === 'sign-up') window.Clerk.openSignUp(options);
      else window.Clerk.openSignIn(options);
    },
  };
})();
