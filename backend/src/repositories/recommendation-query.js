// SQL fragments come only from the community repository's fixed visibility and
// DTO projections. All request/context values use parameters: owner, time,
// UTC offset and the server-derived daypart.
export const recommendationQuery = ({ TRACK, TRACK_FROM, PUBLIC, ACCESS }) => `
WITH me AS (
  SELECT id FROM users WHERE clerk_user_id=$1 AND profile_status='active'
), raw_history AS (
  SELECT e.track_id,e.created_at,lower(btrim(t.genre)) AS genre,
    ((ps.started_at AT TIME ZONE 'UTC') + $3::int * INTERVAL '1 minute')::date AS local_day,
    CASE
      WHEN extract(hour FROM (ps.started_at AT TIME ZONE 'UTC') + $3::int * INTERVAL '1 minute') < 5
        OR extract(hour FROM (ps.started_at AT TIME ZONE 'UTC') + $3::int * INTERVAL '1 minute') >= 22 THEN 'night'
      WHEN extract(hour FROM (ps.started_at AT TIME ZONE 'UTC') + $3::int * INTERVAL '1 minute') < 12 THEN 'morning'
      WHEN extract(hour FROM (ps.started_at AT TIME ZONE 'UTC') + $3::int * INTERVAL '1 minute') < 18 THEN 'afternoon'
      ELSE 'evening' END AS daypart
  FROM me JOIN valid_play_events e ON e.user_id=me.id
    JOIN playback_sessions ps ON ps.id=e.session_id AND ps.user_id=e.user_id AND ps.track_id=e.track_id
    JOIN private_tracks t ON t.id=e.track_id JOIN users u ON u.clerk_user_id=t.clerk_user_id
  WHERE e.created_at >= $2::timestamptz-INTERVAL '90 days' AND e.created_at <= $2::timestamptz
    AND ps.is_valid AND ps.credited_ms>=ps.threshold_ms AND ${ACCESS}
  ORDER BY e.created_at DESC,e.session_id DESC LIMIT 1000
), history AS (
  SELECT DISTINCT ON (track_id,local_day) * FROM raw_history
  ORDER BY track_id,local_day,created_at DESC
), context_history AS (
  SELECT DISTINCT ON (track_id,local_day,daypart) * FROM raw_history
  ORDER BY track_id,local_day,daypart,created_at DESC
), liked AS (
  SELECT lower(btrim(t.genre)) AS genre
  FROM me JOIN track_likes l ON l.user_id=me.id
    JOIN private_tracks t ON t.id=l.track_id JOIN users u ON u.clerk_user_id=t.clerk_user_id
  WHERE ${ACCESS} ORDER BY l.created_at DESC,t.id DESC LIMIT 500
), saved AS (
  SELECT lower(btrim(t.genre)) AS genre
  FROM me JOIN saved_tracks s ON s.user_id=me.id
    JOIN private_tracks t ON t.id=s.track_id JOIN users u ON u.clerk_user_id=t.clerk_user_id
  WHERE ${ACCESS} ORDER BY s.created_at DESC,t.id DESC LIMIT 500
), followed AS (
  SELECT u.id,u.clerk_user_id FROM me JOIN user_follows f ON f.follower_id=me.id
    JOIN users u ON u.id=f.following_id
  WHERE u.username IS NOT NULL AND u.profile_status='active'
  ORDER BY f.created_at DESC,u.id DESC LIMIT 100
), genre_evidence AS (
  SELECT genre,sum(exp(-ln(2)*extract(epoch FROM ($2::timestamptz-created_at))/2592000)) AS history_weight,
    0::float AS time_weight,
    0::float AS like_weight,0::float AS save_weight
  FROM history GROUP BY genre
  UNION ALL SELECT genre,0,
    sum(exp(-ln(2)*extract(epoch FROM ($2::timestamptz-created_at))/2592000)),0,0
    FROM context_history WHERE daypart=$4 GROUP BY genre
  UNION ALL SELECT genre,0,0,count(*)::float,0 FROM liked GROUP BY genre
  UNION ALL SELECT genre,0,0,0,count(*)::float FROM saved GROUP BY genre
), genre_totals AS (
  SELECT genre,sum(history_weight) AS history_weight,sum(time_weight) AS time_weight,
    sum(like_weight) AS like_weight,sum(save_weight) AS save_weight
  FROM genre_evidence GROUP BY genre
), preferences AS (
  SELECT genre,
    history_weight/GREATEST(max(history_weight) OVER (),0.0001) AS history_affinity,
    like_weight/GREATEST(max(like_weight) OVER (),1) AS like_affinity,
    save_weight/GREATEST(max(save_weight) OVER (),1) AS save_affinity,
    CASE WHEN (SELECT count(*) FROM context_history WHERE daypart=$4)>=2
      THEN time_weight/GREATEST(max(time_weight) OVER (),0.0001) ELSE 0 END AS time_affinity
  FROM genre_totals
), genre_seeds AS (
  SELECT genre FROM preferences
  ORDER BY (0.30*history_affinity+0.25*like_affinity+0.10*save_affinity+0.20*time_affinity) DESC,genre
  LIMIT 8
), candidate_ids AS (
  SELECT candidate.id FROM genre_seeds g CROSS JOIN LATERAL (
    SELECT t.id FROM private_tracks t JOIN users u ON u.clerk_user_id=t.clerk_user_id
    WHERE lower(btrim(t.genre))=g.genre AND ${PUBLIC}
    ORDER BY t.created_at DESC,t.id DESC LIMIT 24
  ) candidate
  UNION
  SELECT candidate.id FROM followed f CROSS JOIN LATERAL (
    SELECT t.id FROM private_tracks t JOIN users u ON u.clerk_user_id=t.clerk_user_id
    WHERE u.id=f.id AND ${PUBLIC}
    ORDER BY t.created_at DESC,t.id DESC LIMIT 3
  ) candidate
  UNION
  SELECT fresh.id FROM (
    SELECT t.id FROM private_tracks t JOIN users u ON u.clerk_user_id=t.clerk_user_id
    WHERE ${PUBLIC} ORDER BY t.created_at DESC,t.id DESC LIMIT 40
  ) fresh
)
SELECT ${TRACK},
  COALESCE(p.history_affinity,0) AS history_affinity,
  COALESCE(p.like_affinity,0) AS like_affinity,
  COALESCE(p.save_affinity,0) AS save_affinity,
  COALESCE(p.time_affinity,0) AS time_affinity,
  EXISTS(SELECT 1 FROM followed f WHERE f.id=u.id) AS followed,
  EXISTS(SELECT 1 FROM raw_history h WHERE h.track_id=t.id AND h.created_at>=$2::timestamptz-INTERVAL '24 hours') AS heard_recently,
  1/(1+GREATEST(extract(epoch FROM ($2::timestamptz-t.created_at))/86400,0)/14) AS freshness
${TRACK_FROM} JOIN candidate_ids c ON c.id=t.id
LEFT JOIN preferences p ON p.genre=lower(btrim(t.genre))
WHERE ${PUBLIC}
`;
