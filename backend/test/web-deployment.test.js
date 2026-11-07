import assert from 'node:assert/strict';
import test from 'node:test';
import { publicWebConfig } from '../../scripts/web-config.mjs';
import { createApp } from '../src/app.js';

test('Web configuration exports only public values and supports the browser origin', () => {
  const env = {
    CLERK_PUBLISHABLE_KEY: 'pk_test_fixture',
    DATABASE_URL: 'secret-sentinel', CLERK_SECRET_KEY: 'secret-sentinel',
    CLOUDINARY_API_SECRET: 'secret-sentinel', DEMO_MODE: 'true',
  };
  assert.deepEqual(publicWebConfig(env), {
    CLERK_PUBLISHABLE_KEY: 'pk_test_fixture', API_BASE_URL: '', DEMO_MODE: false,
  });
  assert.equal(publicWebConfig({ ...env, WEB_API_BASE_URL: 'https://example.com/' }).API_BASE_URL, 'https://example.com');
  assert.equal(publicWebConfig({ ...env, WEB_API_BASE_URL: 'http://localhost:3000' }).API_BASE_URL, 'http://localhost:3000');
  assert.throws(() => publicWebConfig({}), /CLERK_PUBLISHABLE_KEY/);
  for (const origin of [
    'http://example.com', 'https://user:secret@example.com', 'https://example.com/api',
    'https://example.com/?token=secret', 'https://example.com/#secret', 'file:///secret', 'invalid-secret',
  ]) {
    assert.throws(() => publicWebConfig({ ...env, WEB_API_BASE_URL: origin }), (error) => {
      assert.ok(!error.message.includes('secret'));
      return /WEB_API_BASE_URL/.test(error.message);
    });
  }
});

test('proxy trust is opt-in and takes the closest forwarded client, ignoring forged prefixes', () => {
  for (const trustProxyHops of [0, 1]) {
    const app = createApp({ trustProxyHops, logging: false,
      clerkOptions: { issuer: 'https://fixture.clerk.accounts.dev' },
    });
    // Exercise Express's real req.ip getter with the configured application.
    const req = Object.create(app.request);
    req.app = app;
    req.connection = { remoteAddress: '127.0.0.1' };
    req.headers = { 'x-forwarded-for': '198.51.100.123, 203.0.113.42' };
    assert.equal(req.ip, trustProxyHops ? '203.0.113.42' : '127.0.0.1');
  }
  for (const trustProxyHops of [true, '1', -1, 3, NaN]) {
    assert.throws(() => createApp({ trustProxyHops,
      clerkOptions: { issuer: 'https://fixture.clerk.accounts.dev' },
    }), /TRUST_PROXY_HOPS/);
  }
});
