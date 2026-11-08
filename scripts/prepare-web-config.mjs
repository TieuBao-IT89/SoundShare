import { createRequire } from 'node:module';
import { writePublicWebConfig } from './web-config.mjs';

const require = createRequire(new URL('../backend/package.json', import.meta.url));
require('dotenv').config({ path: new URL('../backend/.env', import.meta.url), quiet: true });
await writePublicWebConfig(process.env);
