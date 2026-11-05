import assert from "node:assert/strict";
import { once } from "node:events";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { createApp } from "../src/app.js";

test("web CSP allows Clerk device checks on nonstandard ports and keeps executable sources restricted", async (t) => {
  const app = createApp({ logging: false, checkDatabaseConnection: async () => ({ now: new Date() }), webDirectory: new URL("../../web/", import.meta.url).pathname,
    clerkOptions: { issuer: "https://fixture.clerk.accounts.dev" } });
  const server = app.listen(0, "127.0.0.1"); await once(server, "listening");
  t.after(() => new Promise((resolve) => { server.close(resolve); server.closeAllConnections(); }));
  const response = await fetch(`http://127.0.0.1:${server.address().port}/api/v1/health`);
  const csp = Object.fromEntries(response.headers.get("content-security-policy").split(";").map((part) => {
    const [name, ...values] = part.trim().split(/\s+/); return [name, values];
  }));
  assert.ok(csp["script-src"].includes("https://*.protect.clerk.com"));
  assert.ok(csp["connect-src"].includes("https://*.protect.clerk.com:*"));
  assert.ok(csp["frame-src"].includes("https://*.protect.clerk.com"));
  assert.ok(csp["frame-src"].includes("https://challenges.cloudflare.com"));
  assert.ok(!csp["script-src"].some((value) => ["*", "https:", "'unsafe-eval'", "'unsafe-inline'"].includes(value)));
  assert.equal(response.headers.get("cross-origin-opener-policy"), "same-origin-allow-popups");
});

test("Clerk bridge loads Core 3 UI, shares initialization, refreshes tokens and emits only identity", async () => {
  const scripts = []; const notifications = []; const tokenOptions = [];
  let listener; let loadOptions; let modal; let signedOut = false;
  const window = { location: { origin: "http://localhost:3000" }, __internal_ClerkUICtor: {}, Clerk: {
    user: { id: "user_fixture", fullName: "Fixture", emailAddress: "private-sentinel", secret: "private-sentinel" },
    load: async (options) => { loadOptions = options; }, addListener: (callback) => { listener = callback; },
    session: { id: "sess_fixture", status: "active", getToken: async (options) => { tokenOptions.push(options.skipCache); return "token-fixture"; } },
    signOut: async () => { signedOut = true; }, openSignIn: (options) => { modal = ["in", options]; },
    openSignUp: (options) => { modal = ["up", options]; },
  } };
  const document = { createElement: () => ({ dataset: {} }), head: { appendChild: (script) => { scripts.push(script); queueMicrotask(script.onload); } } };
  vm.runInNewContext(await readFile(new URL("../../web/clerk-bridge.js", import.meta.url), "utf8"), { window, document });
  const bridge = window.soundshareAuth;
  const [first, second] = await Promise.all([bridge.initialize("pk_test_fixture"), bridge.initialize("pk_test_fixture")]);
  assert.equal(first, second); assert.equal(scripts.length, 2);
  assert.match(scripts[0].src, /@clerk\/ui@1\./); assert.match(scripts[1].src, /@clerk\/clerk-js@6\./);
  assert.equal(loadOptions.ui.ClerkUI, window.__internal_ClerkUICtor);
  assert.ok(loadOptions.appearance.variables.colorForeground); // Core 3 variable; deprecated names are ignored.
  assert.ok(!first.includes("private-sentinel"));
  assert.deepEqual(JSON.parse(first), { id: "user_fixture", name: "Fixture", sessionId: "sess_fixture" });
  const watch = (value) => notifications.push(value); bridge.watch(watch); listener();
  assert.equal(notifications.length, 2); bridge.unwatch(watch); listener(); assert.equal(notifications.length, 2);
  assert.equal(await bridge.token(false), "token-fixture"); await bridge.token(true); assert.deepEqual(tokenOptions, [false, true]);
  bridge.open("sign-up"); assert.equal(modal[0], "up"); assert.equal(modal[1].forceRedirectUrl, "http://localhost:3000/#/");
  bridge.open("sign-in"); assert.equal(modal[0], "in"); await bridge.signOut(); assert.ok(signedOut);
  window.Clerk.session = null; await assert.rejects(bridge.token(false), /Sign in again/);
});

test("Clerk bridge waits for an active session, replays current state and distinguishes replacement sessions", async () => {
  let listener;
  const notifications = [];
  const user = { id: "user_fixture", fullName: "Fixture", emailAddress: "private-sentinel" };
  const window = { Clerk: {
    user,
    session: null,
    load: async () => {},
    addListener: (callback) => { listener = callback; },
  } };
  const document = { createElement: () => ({ dataset: {} }), head: { appendChild: (script) => queueMicrotask(script.onload) } };
  vm.runInNewContext(await readFile(new URL("../../web/clerk-bridge.js", import.meta.url), "utf8"), { window, document });
  const bridge = window.soundshareAuth;
  assert.equal(await bridge.initialize("pk_test_fixture"), "null");
  window.Clerk.session = { id: "sess_pending", status: "pending", user, getToken: () => { throw new Error("must not request a pending token"); } };
  await assert.rejects(bridge.token(false), /Sign in again/);
  listener();
  // This sign-in happens before Dart has subscribed. watch must replay it.
  window.Clerk.session = { id: "sess_active", status: "active", user };
  listener();
  const watch = (value) => notifications.push(JSON.parse(value));
  bridge.watch(watch);
  assert.deepEqual(notifications, [{ id: "user_fixture", name: "Fixture", sessionId: "sess_active" }]);
  window.Clerk.session = { id: "sess_replacement", status: "active", user };
  listener();
  assert.equal(notifications.at(-1).sessionId, "sess_replacement");
  window.Clerk.session = { id: "sess_replacement", status: "expired", user };
  listener();
  assert.equal(notifications.at(-1), null);
  bridge.unwatch(watch);
  assert.ok(!JSON.stringify(notifications).includes("private-sentinel"));
});
