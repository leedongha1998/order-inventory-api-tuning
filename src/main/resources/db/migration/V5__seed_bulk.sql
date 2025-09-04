-- 개발용: 필요 시 전체 초기화 (주의! 모든 데이터 삭제)
-- 기존 데이터 정리 (외래키 순서 고려)
TRUNCATE TABLE order_item, orders, inventory_log, inventory, product, members, idempotency_key
  RESTART IDENTITY CASCADE;

----------------------------
-- 1) Members (1만 명) - 먼저 생성
----------------------------
INSERT INTO members(email, name, status, created_at, updated_at)
SELECT
    'user' || g || '@example.com',
    'User-' || g,
    CASE WHEN g % 10 = 0 THEN 'INACTIVE' ELSE 'ACTIVE' END,
    now() - (g % 1000 || ' minutes')::interval,
        now() - (g % 500  || ' minutes')::interval
FROM generate_series(1,10000) g;

-- Members 삽입 확인
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM members) < 10000 THEN
        RAISE EXCEPTION 'Members 테이블에 충분한 데이터가 없습니다. 현재 개수: %', (SELECT COUNT(*) FROM members);
END IF;
END $$;

----------------------------
-- 2) Product (2만 개)
----------------------------
INSERT INTO product(name, price, status, created_at)
SELECT
    'Product-' || g,
    ((g % 5000) + 100)::numeric(12,2), -- 100 ~ 5100
        CASE WHEN g % 10 = 0 THEN 'INACTIVE' ELSE 'ACTIVE' END,
    now() - (g % 1000 || ' minutes')::interval
FROM generate_series(1,20000) g;

-- Product 삽입 확인
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM product) < 20000 THEN
        RAISE EXCEPTION 'Product 테이블에 충분한 데이터가 없습니다. 현재 개수: %', (SELECT COUNT(*) FROM product);
END IF;
END $$;

----------------------------
-- 3) Orders (100만 건)
----------------------------
INSERT INTO orders(member_id, status, total_amount, created_at, updated_at)
SELECT
    (g % 10000) + 1,                         -- 항상 존재하는 members.id (1..10000)
    CASE WHEN g % 10 < 7 THEN 'PAID'
         WHEN g % 10 < 9 THEN 'PENDING'
         ELSE 'CANCELLED' END,
    ((g % 50000) + 1000)::numeric(12,2),     -- 대략적인 합계(참고용)
        now() - (g % 365 || ' days')::interval,
        now()
FROM generate_series(1,1000000) g;

----------------------------
-- 4) OrderItem (주문 당 1~3개, 총 ~300만 건)
--    ※ orders와 product를 조합해서 "실존 id"만 참조
----------------------------
INSERT INTO order_item(order_id, product_id, unit_price, quantity, created_at)
SELECT
    o.id AS order_id,
    p.id AS product_id,
    p.price AS unit_price,
    1 + ((o.id + s.n) % 5) AS quantity,                    -- 1~5
    o.created_at + ((o.id + s.n) % 1000 || ' seconds')::interval
FROM orders o
    JOIN LATERAL generate_series(1, 1 + (o.id % 3)) s(n) ON TRUE   -- 주문당 1~3개
    JOIN product p ON p.id = ((o.id + s.n) % 20000) + 1;           -- 항상 1..20000

----------------------------
-- 5) Inventory (각 상품별 1행)
----------------------------
INSERT INTO inventory(product_id, quantity, updated_at)
SELECT
    p.id,
    (p.id % 500),
    now()
FROM product p;

----------------------------
-- 6) Inventory Log (10만 건)
----------------------------
INSERT INTO inventory_log(product_id, change_qty, reason, created_at)
SELECT
    (g % 20000) + 1,                                     -- 항상 1..20000
    CASE WHEN g % 2 = 0 THEN 5 ELSE -3 END,
    CASE WHEN g % 2 = 0 THEN 'RESTOCK' ELSE 'SALE' END,
    now() - (g % 100 || ' hours')::interval
FROM generate_series(1,100000) g;

----------------------------
-- 7) Idempotency Key (1000개)
----------------------------
INSERT INTO idempotency_key(key, response_body, created_at)
SELECT
    md5('idem-' || g),
    '{"ok":true}',
    now() - (g % 1000 || ' minutes')::interval
FROM generate_series(1,1000) g;

----------------------------
-- 8) 통계(플래너) 갱신
----------------------------
ANALYZE;