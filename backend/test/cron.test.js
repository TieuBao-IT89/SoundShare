import assert from "node:assert/strict";
import test from "node:test";
import { createKeepAliveJob } from "../src/config/cron.js";

const production = {
  NODE_ENV: "production",
  KEEP_ALIVE_ENABLED: "true",
  API_URL: "https://soundshare.example.test",
};
const settle = () => new Promise(resolve => setImmediate(resolve));
const fixture = (options = {}) => {
  const calls = [], messages = [], delays = [], removed = [];
  let callback, unreferenced = false;
  const job = createKeepAliveJob({
    env: production,
    fetchImpl: async (...args) => { calls.push(args); return { status: 200 }; },
    schedule: (fn, delay) => {
      callback = fn;
      delays.push(delay);
      return { unref: () => { unreferenced = true; } };
    },
    unschedule: timer => removed.push(timer),
    logger: {
      log: value => messages.push(JSON.parse(value)),
      warn: value => messages.push(JSON.parse(value)),
    },
    ...options,
  });
  return { job, calls, messages, delays, removed,
    tick: () => callback(), isUnreferenced: () => unreferenced };
};

test("keep-alive requires both production and an explicit opt-in", () => {
  for (const env of [
    {}, { ...production, NODE_ENV: "development" },
    { ...production, NODE_ENV: "test" },
    { ...production, KEEP_ALIVE_ENABLED: "false" },
    { NODE_ENV: "production", API_URL: production.API_URL },
  ]) {
    const f = fixture({ env });
    assert.equal(f.job.start(), false);
    assert.equal(f.calls.length, 0);
    assert.equal(f.delays.length, 0);
    assert.equal(f.messages.length, 0);
    f.job.stop();
  }
});

test("invalid origins disable only the job and never expose configuration", () => {
  for (const API_URL of [
    "", "not-a-url", "http://soundshare.example.test",
    "https://user:secret-sentinel@soundshare.example.test",
    "https://soundshare.example.test/api",
    "https://soundshare.example.test/?token=secret-sentinel",
    "https://soundshare.example.test/#secret-sentinel",
  ]) {
    const f = fixture({ env: { ...production, API_URL } });
    assert.equal(f.job.start(), false);
    assert.equal(f.calls.length, 0);
    assert.deepEqual(f.messages, [{ code: "KEEP_ALIVE_CONFIG_INVALID" }]);
  }
});

test("pings the versioned endpoint immediately and every 14 minutes with one unreferenced schedule", async () => {
  let released = 0;
  const f = fixture();
  assert.equal(f.job.start(), true);
  assert.equal(f.job.start(), false);
  await settle();
  assert.deepEqual(f.delays, [14 * 60 * 1000]);
  assert.equal(f.isUnreferenced(), true);
  assert.equal(f.calls[0][0], "https://soundshare.example.test/api/v1/health");
  assert.equal(f.calls[0][1].method, "GET");
  assert.equal(f.calls[0][1].redirect, "error");
  assert.equal(f.calls[0][1].signal.aborted, false);
  assert.deepEqual(f.messages, [{ code: "KEEP_ALIVE_OK", status: 200 }]);
  await f.tick();
  assert.equal(f.calls.length, 2);
  f.job.stop(); f.job.stop();
  assert.equal(f.removed.length, 1);
  await f.tick();
  assert.equal(f.calls.length, 2);

  const body = fixture({ fetchImpl: async () => ({ status: 200, body: {
    cancel: async () => { released++; },
  } }) });
  body.job.start(); await settle(); body.job.stop();
  assert.equal(released, 1);
});

test("a slow response cannot cause overlapping requests; HTTP and network errors remain safe", async () => {
  let complete, count = 0;
  const f = fixture({ fetchImpl: () => {
    count++;
    if (count > 1) throw new Error("private-provider-secret-sentinel");
    return new Promise(resolve => { complete = resolve; });
  } });
  f.job.start();
  await f.tick();
  assert.equal(count, 1);
  complete({ status: 503 }); await settle();
  assert.deepEqual(f.messages, [{ code: "KEEP_ALIVE_HTTP_ERROR", status: 503 }]);
  await f.tick();
  assert.deepEqual(f.messages[1], { code: "KEEP_ALIVE_REQUEST_FAILED" });
  assert.ok(!JSON.stringify(f.messages).includes("sentinel"));
  f.job.stop();
});

test("a stalled request is aborted on timeout and the next ping can recover", async () => {
  let signal, count = 0;
  const f = fixture({ requestTimeoutMs: 5, fetchImpl: async (_, options) => {
    count++;
    if (count > 1) return { status: 200 };
    signal = options.signal;
    return new Promise((_, reject) => signal.addEventListener("abort", () => reject(Error("timeout")), { once: true }));
  } });
  f.job.start();
  await new Promise(resolve => setTimeout(resolve, 20));
  assert.equal(signal.aborted, true);
  assert.deepEqual(f.messages, [{ code: "KEEP_ALIVE_REQUEST_FAILED" }]);
  await f.tick();
  assert.deepEqual(f.messages[1], { code: "KEEP_ALIVE_OK", status: 200 });
  f.job.stop();
});

test("stopping aborts pending work without logging a shutdown failure", async () => {
  let signal;
  const f = fixture({ fetchImpl: async (_, options) => {
    signal = options.signal;
    return new Promise((_, reject) => signal.addEventListener("abort", () => reject(Error("stopped")), { once: true }));
  } });
  f.job.start(); f.job.stop();
  await settle();
  assert.equal(signal.aborted, true);
  assert.deepEqual(f.messages, []);
  assert.equal(f.removed.length, 1);
});
