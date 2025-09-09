-- V7__reseed_orders_no_404.sql

-- 0) members 존재 확인
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM members) = 0 THEN
    RAISE EXCEPTION 'No members found. Seed members first.';
END IF;
END $$;

-- 1) 비우고 시퀀스 초기화(일단 1부터)
TRUNCATE TABLE order_item RESTART IDENTITY CASCADE;
TRUNCATE TABLE orders RESTART IDENTITY CASCADE;

-- 2) orders: 1..10000 생성
WITH member_pool AS (
    SELECT array_agg(id ORDER BY id) AS ids, COUNT(*) AS cnt FROM members
),
     order_src AS (
         SELECT gs AS order_id,
                (SELECT ids[((gs-1) % cnt) + 1] FROM member_pool) AS member_id
FROM generate_series(1, 10000) AS gs
    )
INSERT INTO orders (id, member_id, status, total_amount, created_at, updated_at)
SELECT order_id, member_id, 'PAID', 0, now(), now()
FROM order_src;

-- 3) 주문당 3개 아이템 생성
WITH items AS (
    SELECT o.id AS order_id,
           ((o.id * 7 + k) % 20000) + 1 AS product_id,             -- 1..20000
    ((o.id + k) % 5 + 1)        AS quantity,                -- 1..5
    (((o.id + k) % 9000) + 1000)::numeric(12,2) AS unit_price
FROM orders o
    CROSS JOIN generate_series(0, 2) AS k
    )
INSERT INTO order_item(order_id, product_id, unit_price, quantity)
SELECT order_id, product_id, unit_price, quantity
FROM items;

-- 4) 합계 업데이트
UPDATE orders o
SET total_amount = s.sum_amount,
    updated_at   = now()
    FROM (
  SELECT order_id, SUM(unit_price * quantity) AS sum_amount
  FROM order_item
  GROUP BY order_id
) s
WHERE o.id = s.order_id;

-- 5) 시퀀스 동기화
-- orders는 다음 신규 주문을 10001부터 시작
ALTER TABLE orders ALTER COLUMN id RESTART WITH 10001;

-- order_item은 현재 MAX(id)+1로 맞춤 (IDENTITY도 내부적으로 시퀀스를 사용)
SELECT setval(
               pg_get_serial_sequence('order_item','id'),
               COALESCE((SELECT MAX(id) FROM order_item), 0) + 1,
               false
       );
