ALTER TABLE coupon_template
    ADD COLUMN discount_amount NUMERIC(19, 2) NOT NULL DEFAULT 0;
