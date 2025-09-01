-- V5__seed_bulk.sql
-- 대량 테스트 데이터를 결정적으로 생성
-- 실행 후 반드시 ANALYZE 필요

----------------------------
-- 1) Product (2만 개)
----------------------------
INSERT INTO product(name, price, currency, status, created_at, updated_at)
SELECT
    'Product-' || g,
    ((g % 5000) + 100)::numeric(12,2), -- 가격 분포 100 ~ 5100
        'USD',
    CASE WHEN g % 10 = 0 THEN 'INACTIVE' ELSE 'ACTIVE' END,
    now() - (g % 1000 || ' minutes')::interval,
        now()
FROM generate_series(1,20000) g;

----------------------------
-- 2) Orders (100만 개)
----------------------------
INSERT INTO orders(user_id, status, total_amount, created_at, updated_at)
SELECT
    (g % 100000) + 1,  -- 10만 명 사용자
    CASE WHEN g % 10 < 7 THEN 'PAID'
         WHEN g % 10 < 9 THEN 'PENDING'
         ELSE 'CANCELLED' END,
    ((g % 50000) + 1000)::numeric(12,2),
        now() - (g % 365 || ' days')::interval,
        now()
FROM generate_series(1,1000000) g;

----------------------------
-- 3) Order Item (300만 개)
----------------------------
INSERT INTO order_item(order_id, product_id, unit_price, quantity, created_at)
SELECT
    (g % 1000000) + 1,
    (g % 20000) + 1,
    ((g % 5000) + 100)::numeric(12,2),
        (g % 5) + 1,
    now() - (g % 1000 || ' seconds')::interval
FROM generate_series(1,3000000) g;

----------------------------
-- 4) Inventory (각 상품별 1개)
----------------------------
INSERT INTO inventory(product_id, quantity, updated_at)
SELECT
    id,
    (id % 500),
    now()
FROM product;

----------------------------
-- 5) Inventory Log (10만 개)
----------------------------
INSERT INTO inventory_log(product_id, change_qty, reason, created_at)
SELECT
    (g % 20000) + 1,
    CASE WHEN g % 2 = 0 THEN 5 ELSE -3 END,
    CASE WHEN g % 2 = 0 THEN 'RESTOCK' ELSE 'SALE' END,
    now() - (g % 100 || ' hours')::interval
FROM generate_series(1,100000) g;

----------------------------
-- 6) Idempotency Key (소량, 1000개)
----------------------------
INSERT INTO idempotency_key(key, response_body, created_at)
SELECT
    md5('idem-' || g),
    '{"ok":true}',
    now() - (g % 1000 || ' minutes')::interval
FROM generate_series(1,1000) g;

----------------------------
-- 7) 통계 수집
----------------------------
ANALYZE;
