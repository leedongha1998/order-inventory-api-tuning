\set member_id random(1,500000)
\set total random(1000,200000)
BEGIN;
INSERT INTO bench.orders_np(member_id,status,created_at,total)
VALUES (:member_id, 'PAID', clock_timestamp(), :total);
COMMIT;
