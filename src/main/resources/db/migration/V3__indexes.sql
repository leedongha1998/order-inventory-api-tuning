-- product
CREATE INDEX IF NOT EXISTS idx_product_status         ON product(status);
-- 활성 상품만 자주 조회하면 부분 인덱스
CREATE INDEX IF NOT EXISTS idx_product_active_partial ON product(id) WHERE status='ACTIVE';

-- orders
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at ON orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_member_created_at   ON orders(member_id, created_at DESC);

-- order_item
CREATE INDEX IF NOT EXISTS idx_order_item_order_id    ON order_item(order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_product_id  ON order_item(product_id);

-- inventory_log
CREATE INDEX IF NOT EXISTS idx_inventory_log_prod_created ON inventory_log(product_id, created_at DESC);

-- idempotency_key
CREATE INDEX IF NOT EXISTS idx_idem_created_at ON idempotency_key(created_at);
