-- 인덱스
CREATE INDEX IF NOT EXISTS idx_coupon_member      ON coupon(member_id);
CREATE INDEX IF NOT EXISTS idx_coupon_template    ON coupon(template_id);
CREATE INDEX IF NOT EXISTS idx_coupon_status      ON coupon(status);