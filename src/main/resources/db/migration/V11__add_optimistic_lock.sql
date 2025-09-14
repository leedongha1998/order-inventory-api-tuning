-- 1) 버전 컬럼 추가 (낙관적 락용)
ALTER TABLE inventory       ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE orders          ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE order_item ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE coupon          ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

-- 2) 제품당 1행 보장을 "제약" 대신 "유니크 인덱스"로 안전하게 처리
--    (인덱스는 IF NOT EXISTS 지원. 트랜잭션 내 생성 가능)
CREATE UNIQUE INDEX IF NOT EXISTS uq_inventory_product_idx ON inventory(product_id);

-- 3) 기존에 동일 목적의 제약이 있다면(이름이 다를 수도 있음) 유지.
--    제약으로 강제하고 싶다면 아래 DO 블록 사용. 필요 시에만 주석 해제.
-- DO $$
-- BEGIN
--   IF NOT EXISTS (
--     SELECT 1
--     FROM   pg_constraint c
--     JOIN   pg_class t   ON t.oid = c.conrelid
--     WHERE  t.relname = 'inventory'
--     AND    c.conname = 'uq_inventory_product'
--   ) THEN
--     ALTER TABLE inventory
--       ADD CONSTRAINT uq_inventory_product UNIQUE (product_id);
--   END IF;
-- END $$;
