-- B-2) Partition pruning validation for bench.orders_pt
-- Usage:
--   psql -h localhost -U dongha -d api-tuning -f scripts/experiments/b2_partition_pruning_check.sql

\echo '=== Pruning expected (created_at bounded) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM bench.orders_pt
WHERE created_at >= TIMESTAMPTZ '2024-08-01 00:00:00+00'
  AND created_at < TIMESTAMPTZ '2024-09-01 00:00:00+00';

\echo '=== Pruning likely degraded (no partition key filter) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM bench.orders_pt
WHERE member_id BETWEEN 1 AND 1000;
