import { createRequire } from 'node:module';
import { mkdir, writeFile } from 'node:fs/promises';

const require = createRequire(new URL('../backend/package.json', import.meta.url));
require('dotenv').config({ path: new URL('../backend/.env', import.meta.url), quiet: true });
const key = process.env.CLERK_PUBLISHABLE_KEY;
if (!/^pk_(test|live)_[A-Za-z0-9_=-]+$/.test(key || '')) throw new Error('Configure the Clerk publishable key in backend/.env.');
const origin = process.env.WEB_API_BASE_URL || 'http://localhost:3000';
const url = new URL(origin);
if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash || url.pathname !== '/') throw new Error('WEB_API_BASE_URL must be an HTTP(S) origin.');
await mkdir(new URL('../.local/', import.meta.url), { recursive: true });
// An explicit allowlist: never serialize the environment or copy backend secrets.
await writeFile(new URL('../.local/web-config.json', import.meta.url), JSON.stringify({ CLERK_PUBLISHABLE_KEY: key, API_BASE_URL: url.origin, DEMO_MODE: false }, null, 2));
console.log('Prepared .local/web-config.json with public client configuration only.');
