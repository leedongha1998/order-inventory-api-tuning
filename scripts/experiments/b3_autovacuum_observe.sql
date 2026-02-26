-- B-3) Autovacuum sensitivity observation queries
-- Run during/after soak test to observe p99 drift correlation.

\echo '=== Dead tuples / vacuum status ==='
SELECT relname,
       n_live_tup,
       n_dead_tup,
       last_vacuum,
       last_autovacuum,
       vacuum_count,
       autovacuum_count
FROM pg_stat_user_tables
WHERE schemaname='public'
ORDER BY n_dead_tup DESC
LIMIT 20;

\echo '=== WAL / checkpoint ==='
SELECT checkpoints_timed,
       checkpoints_req,
       checkpoint_write_time,
       checkpoint_sync_time,
       buffers_checkpoint,
       buffers_clean,
       maxwritten_clean
FROM pg_stat_bgwriter;
