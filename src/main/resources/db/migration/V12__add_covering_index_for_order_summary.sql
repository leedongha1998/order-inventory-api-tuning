-- B-1) Covering index (INCLUDE) for order summary pagination queries
CREATE INDEX IF NOT EXISTS idx_orders_member_created_at_covering
    ON orders (member_id, created_at DESC, id DESC)
    INCLUDE (status, total_amount);
