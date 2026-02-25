-- unify order status spelling between application enum and DB constraint
UPDATE orders
SET status = 'CANCELED'
WHERE status = 'CANCELLED';

ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE orders
    ADD CONSTRAINT orders_status_check
        CHECK (status IN ('PENDING', 'PAID', 'CANCELED'));
