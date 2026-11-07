import assert from 'node:assert/strict';
import { once } from 'node:events';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import test from 'node:test';
import { createApp } from '../src/app.js';
import { parseLrc } from '../src/validation/lyrics.schema.js';
import { createLyricsRepository } from '../src/repositories/lyrics.repository.js';
import { createLyricsService } from '../src/services/lyrics.service.js';
import { createTrackRepository } from '../src/repositories/track.repository.js';
import { createTrackService } from '../src/services/track.service.js';
import { communityDatabase, clerkOptions, token } from './helpers/community-fixture.js';

const cases = JSON.parse(await readFile(new URL('../../test/fixtures/lrc_cases.json', import.meta.url), 'utf8'));
for (const entry of cases.valid) test(`LRC: ${entry.name}`, () => assert.deepEqual(parseLrc(entry.source).cues, entry.cues));
test('LRC rejects malformed, untimed, binary, oversized and expanded inputs', () => {
  for (const source of [...cases.invalid, '[00:01]' + 'x'.repeat(501), '[00:01]' + '🎵'.repeat(18000), '[00:01]x\n'.repeat(1001), '[00:00]x\n' + '\n'.repeat(2000) + '[00:01]x', '[00:00]' + '\ud800']) {
    assert.throws(() => parseLrc(source), e => e.code === 'INVALID_LRC');
  }
});

test('lyrics API enforces identity, visibility, ownership, revisions, atomic creation and safe failures on isolated PostgreSQL', async t => {
  const { db, pool, close } = await communityDatabase(); t.after(close);
  await db.exec("INSERT INTO users(clerk_user_id,username) VALUES('user_a','uploader'),('user_b','listener')");
  async function asset() { return (await db.query(`INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes)
    VALUES('user_a','audio',$1,'https://fixture.invalid/audio','video','mp3',100) RETURNING id`, [randomUUID()])).rows[0].id; }
  async function track(visibility = 'private') { return (await db.query(`INSERT INTO private_tracks(clerk_user_id,audio_asset_id,title,artist,genre,visibility,rights_confirmed_at)
    VALUES('user_a',$1,'Fixture recording','Fixture creator','Indie',$2,NOW()) RETURNING id`, [await asset(), visibility])).rows[0].id; }
  const id = await track(), pub = await track('public');
  const repository = createLyricsRepository(pool);
  const app = createApp({ lyricsService: createLyricsService(repository), logging: false, clerkOptions });
  const server = app.listen(0, '127.0.0.1'); await once(server, 'listening');
  t.after(() => new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }));
  const base = `http://127.0.0.1:${server.address().port}/api/v1/songs`;
  const request = (id, method = 'GET', body, identity = token()) => fetch(`${base}/${id}/lyrics`, {
    method, headers: { ...(identity ? { Authorization: `Bearer ${identity}` } : {}), ...(body ? { 'Content-Type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined,
  });
  for (const identity of [null, 'invalid', token('user_a', { exp: 1 }), token('user_a', { aud: 'other' }), token('user_a', { iss: 'https://other.invalid' }), token().slice(0, -5) + 'aaaaa']) {
    assert.equal((await request(id, 'GET', undefined, identity)).status, 401);
  }
  let response = await request(id);
  assert.equal(response.status, 200); assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual((await response.json()).data.cues, []);
  assert.equal((await request(id, 'GET', undefined, token('user_b'))).status, 404);
  const lrc = cases.valid[0].source;
  response = await request(id, 'PUT', { lrc, revision: 0 });
  assert.equal(response.status, 200); assert.deepEqual((await response.json()).data.cues, cases.valid[0].cues);
  assert.equal((await request(id, 'PUT', { lrc, revision: 0 })).status, 409);
  assert.equal((await request(pub, 'PUT', { lrc, revision: 0 }, token('user_b'))).status, 403);
  assert.equal((await request(id, 'PUT', { lrc, revision: 1 }, token('user_b'))).status, 404);
  for (const bad of [{ lrc: 'untimed', revision: 1 }, { lrc, revision: -1 }, { lrc, revision: 1, owner: 'user_b' }, { lrc }]) {
    response = await request(id, 'PUT', bad); assert.equal(response.status, 400);
    const data = await response.json(); assert.ok(data.error.requestId); assert.ok(!JSON.stringify(data).includes(lrc));
  }
  assert.equal((await request("bad-id' OR 1=1 --")).status, 400);
  await request(pub, 'PUT', { lrc, revision: 0 });
  response = await request(pub, 'GET', undefined, token('user_b'));
  assert.equal(response.status, 200); assert.equal((await response.json()).data.canEdit, false);
  await db.query("UPDATE private_tracks SET visibility='private' WHERE id=$1", [pub]);
  assert.equal((await request(pub, 'GET', undefined, token('user_b'))).status, 404);
  await db.query("UPDATE private_tracks SET visibility='public' WHERE id=$1", [pub]);
  await db.exec("UPDATE users SET profile_status='hidden' WHERE clerk_user_id='user_a'");
  assert.equal((await request(pub, 'GET', undefined, token('user_b'))).status, 404);
  await db.exec("UPDATE users SET profile_status='active' WHERE clerk_user_id='user_a'");
  const writes = await Promise.all([request(id, 'PUT', { lrc, revision: 1 }), request(id, 'PUT', { lrc, revision: 1 })]);
  assert.deepEqual(writes.map(r => r.status).sort(), [200, 409]);
  response = await request(id, 'DELETE', { revision: 2 }); assert.equal(response.status, 200);
  assert.equal((await response.json()).data.lrc, null);
  assert.equal((await request(id, 'PUT', { lrc, revision: 2 })).status, 409);
  assert.equal((await request(id, 'PUT', { lrc, revision: 3 })).status, 200);
  await db.query("UPDATE private_tracks SET status='deleted' WHERE id=$1", [pub]);
  assert.equal((await request(pub)).status, 404);
  assert.equal((await request(pub, 'DELETE', { revision: 1 })).status, 404);
  const createRepository = createTrackRepository(pool);
  const input = { audioAssetId: await asset(), title: 'Atomic fixture', artist: 'Owner', genre: 'Indie', description: '', lyricsLrc: parseLrc(lrc).source };
  const created = await createRepository.create('user_a', input);
  assert.equal((await repository.read('user_a', created.row.id)).lrc, input.lyricsLrc);
  assert.equal((await createRepository.create('user_a', input)).created, false);
  await assert.rejects(() => createRepository.create('user_a', { ...input, lyricsLrc: '[00:00]Changed' }), e => e.code === 'TRACK_ALREADY_EXISTS');
  const rollbackAsset = await asset();
  await assert.rejects(() => createRepository.create('user_a', { ...input, audioAssetId: rollbackAsset, lyricsLrc: '' }));
  assert.equal((await db.query('SELECT id FROM private_tracks WHERE audio_asset_id=$1', [rollbackAsset])).rows.length, 0);
  const failed = createLyricsService({ read: async () => { throw Error('private-db-sentinel'); } });
  await assert.rejects(() => failed.read('user_a', id), e => e.code === 'LYRICS_UNAVAILABLE' && !e.message.includes('sentinel'));
  let called = false;
  const createService = createTrackService({ repository: { ensureUser: async () => { called = true; } } });
  await assert.rejects(() => createService.create('user_a', { lyricsLrc: 'bad' }), e => e.code === 'INVALID_LRC');
  assert.equal(called, false);
});
