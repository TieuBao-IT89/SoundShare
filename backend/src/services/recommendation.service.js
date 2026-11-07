// Explainable content ranking. No external model or raw listening data leaves
// the backend. Keep the version and weights explicit for later evaluation.
export const RECOMMENDATION_VERSION = "taste-v1";
export const RECOMMENDATION_WEIGHTS = Object.freeze({
  history: 0.3,
  likes: 0.25,
  saves: 0.1,
  following: 0.15,
  time: 0.2,
});

export { recommendationContext } from "../utils/listening-context.js";

export const rankRecommendations = (candidates, context, limit = 8) => {
  const weighted = candidates.map((row) => {
    const signals = [
      [
        "listening-history",
        Number(row.history_affinity || 0) * RECOMMENDATION_WEIGHTS.history,
      ],
      ["liked-genre", Number(row.like_affinity || 0) * RECOMMENDATION_WEIGHTS.likes],
      ["saved-genre", Number(row.save_affinity || 0) * RECOMMENDATION_WEIGHTS.saves],
      ["following", row.followed ? RECOMMENDATION_WEIGHTS.following : 0],
      ["listening-time", Number(row.time_affinity || 0) * RECOMMENDATION_WEIGHTS.time],
    ];
    const affinity = signals.reduce((sum, [, value]) => sum + value, 0);
    const strongest = signals.reduce((best, value) =>
      value[1] > best[1] ? value : best,
    );
    const timeWeight = Number(row.time_affinity || 0) * RECOMMENDATION_WEIGHTS.time;
    const reason =
      timeWeight > 0 && timeWeight >= strongest[1] / 2
        ? "listening-time"
        : strongest[0];
    return {
      ...row,
      affinity,
      recommendation_score:
        (affinity + 0.01 * Number(row.freshness || 0)) *
        (row.heard_recently ? 0.65 : 1),
      recommendation_reason: {
        code: affinity > 0 ? reason : "new-release",
        ...(affinity > 0 && reason !== "following" ? { genre: row.genre } : {}),
        ...(affinity > 0 && reason === "listening-time"
          ? { daypart: context.daypart }
          : {}),
      },
    };
  });
  const personalized = weighted.some((row) => row.affinity > 0);
  const tieBreak = (a, b) =>
    new Date(b.created_at) - new Date(a.created_at) ||
    String(b.id).localeCompare(String(a.id));
  const selected = [];
  const creatorCounts = new Map();
  while (weighted.length && selected.length < limit) {
    const score = (row) =>
      row.recommendation_score /
      (1 + 0.35 * (creatorCounts.get(row.uploader_id) || 0));
    weighted.sort((a, b) =>
      (personalized ? score(b) - score(a) : 0) || tieBreak(a, b),
    );
    const next = weighted.shift();
    selected.push(next);
    creatorCounts.set(
      next.uploader_id,
      (creatorCounts.get(next.uploader_id) || 0) + 1,
    );
  }
  return {
    items: selected,
    metadata: {
      version: RECOMMENDATION_VERSION,
      strategy: personalized ? "personalized" : "new-releases",
      ...context,
      experimental: true,
    },
  };
};
