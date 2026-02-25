-- scripts/pg_stat_check.sql (수정본)

-- 1) 누적 비용이 큰 TOP 10
SELECT queryid,
    left(regexp_replace(query, E'\\s+', ' ', 'g'), 120) AS qry,
    calls,
    round(total_exec_time::numeric, 2) AS total_ms,
    round(mean_exec_time::numeric, 2)  AS mean_ms,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
    LIMIT 10;

-- 2) 평균이 느린 TOP 10 (콜 수 50건 이상)
SELECT queryid,
    left(regexp_replace(query, E'\\s+', ' ', 'g'), 120) AS qry,
    calls,
    round(mean_exec_time::numeric, 2) AS mean_ms,
    rows
FROM pg_stat_statements
WHERE calls >= 50
ORDER BY mean_exec_time DESC
    LIMIT 10;

-- 3) 버퍼 히트/읽기 비율
SELECT queryid,
       calls,
       shared_blks_hit,
       shared_blks_read,
       round(
               (100.0 * shared_blks_hit::numeric)
                   / nullif(shared_blks_hit + shared_blks_read, 0), 2
       ) AS hit_pct
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
    LIMIT 10;

-- 4) 느린 쿼리 비율(간이 지표)
SELECT round(
               100.0 * SUM(CASE WHEN mean_exec_time > 200 THEN calls ELSE 0 END)::numeric
         / NULLIF(SUM(calls), 0), 3
       ) AS slow_rate_pct
FROM pg_stat_statements;
