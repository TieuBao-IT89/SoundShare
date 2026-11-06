import assert from "node:assert/strict";
import test from "node:test";
import {
  rankRecommendations,
  recommendationContext,
} from "../src/services/recommendation.service.js";

const candidate = (signals = {}) => ({
  id: "fixture-song",
  uploader_id: "fixture-creator",
  genre: "Lo-fi",
  created_at: "2026-11-01T00:00:00.000Z",
  ...signals,
});
const reasonFor = (signals) =>
  rankRecommendations([candidate(signals)], { daypart: "night" }).items[0]
    .recommendation_reason;

test("negligible time evidence does not replace the strongest recommendation explanation", () => {
  assert.deepEqual(
    reasonFor({ history_affinity: 1, like_affinity: 1, time_affinity: 0.00001 }),
    { code: "listening-history", genre: "Lo-fi" },
  );
  assert.deepEqual(
    reasonFor({ followed: true, time_affinity: 0.00001 }),
    { code: "following" },
  );
});

test("time-of-day explanations require a meaningful weighted contribution", () => {
  assert.deepEqual(
    reasonFor({ history_affinity: 1, time_affinity: 0.74 }),
    { code: "listening-history", genre: "Lo-fi" },
  );
  assert.deepEqual(
    reasonFor({ history_affinity: 1, time_affinity: 0.75 }),
    { code: "listening-time", genre: "Lo-fi", daypart: "night" },
  );
});

test("listening context respects every local daypart boundary", () => {
  for (const [localTime, daypart] of [
    ["04:59:59", "night"],
    ["05:00:00", "morning"],
    ["11:59:59", "morning"],
    ["12:00:00", "afternoon"],
    ["17:59:59", "afternoon"],
    ["18:00:00", "evening"],
    ["21:59:59", "evening"],
    ["22:00:00", "night"],
  ]) {
    assert.deepEqual(
      recommendationContext(new Date(`2026-11-06T${localTime}+07:00`)),
      { daypart, utcOffsetMinutes: 420 },
      localTime,
    );
  }
});

test("listening context applies signed UTC offsets across calendar boundaries", () => {
  const at = new Date("2026-11-06T10:00:00.000Z");
  assert.deepEqual(recommendationContext(at, -720), {
    daypart: "night",
    utcOffsetMinutes: -720,
  });
  assert.deepEqual(recommendationContext(at, 840), {
    daypart: "night",
    utcOffsetMinutes: 840,
  });
  assert.deepEqual(recommendationContext(at, 0), {
    daypart: "morning",
    utcOffsetMinutes: 0,
  });
});
