import { mkdir, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

export function publicWebConfig(env) {
  const key = env.CLERK_PUBLISHABLE_KEY || '';
  if (!/^pk_(test|live)_[A-Za-z0-9_=-]+$/.test(key)) {
    throw new Error('Configure CLERK_PUBLISHABLE_KEY before building Web.');
  }
  // Empty means the browser origin, so a Render-assigned URL needs no rebuild.
  const origin = env.WEB_API_BASE_URL || '';
  let apiBaseUrl = '';
  if (origin) {
    let url;
    try { url = new URL(origin); } catch {
      throw new Error('WEB_API_BASE_URL must be an HTTP(S) origin.');
    }
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash || url.pathname !== '/') {
      throw new Error('WEB_API_BASE_URL must be an HTTP(S) origin.');
    }
    if (url.protocol !== 'https:' && !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) {
      throw new Error('Remote WEB_API_BASE_URL must use HTTPS.');
    }
    apiBaseUrl = url.origin;
  }
  // Explicit allowlist; never serialize backend secrets or the environment.
  return { CLERK_PUBLISHABLE_KEY: key, API_BASE_URL: apiBaseUrl, DEMO_MODE: false };
}

export async function writePublicWebConfig(env) {
  const config = publicWebConfig(env);
  await mkdir(new URL('../.local/', import.meta.url), { recursive: true });
  await writeFile(new URL('../.local/web-config.json', import.meta.url), JSON.stringify(config, null, 2));
  console.log('Prepared .local/web-config.json with public client configuration only.');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await writePublicWebConfig(process.env);
}
