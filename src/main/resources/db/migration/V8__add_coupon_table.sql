CREATE TABLE IF NOT EXISTS coupon_template (
                                               id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                               name         VARCHAR(255) NOT NULL,
    description  TEXT,
    type         VARCHAR(16)  NOT NULL,     -- PCT / FIX
    min_amount   NUMERIC(19,2)
    );

-- 2) 쿠폰
CREATE TABLE IF NOT EXISTS coupon (
                                      id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                      member_id    BIGINT       NOT NULL,
                                      template_id  BIGINT       NOT NULL,
                                      status       VARCHAR(16)  NOT NULL,     -- ISSUED / RESERVED / EXPIRED
    expiry_date  DATE,
    issued_date  TIMESTAMP
    );

-- 3) FK(참조 테이블명이 members 임에 주의)
DO $$
BEGIN
  -- coupon → members(id)
  IF NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conname = 'fk_coupon_member'
  ) THEN
ALTER TABLE coupon
    ADD CONSTRAINT fk_coupon_member
        FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE;
END IF;

  -- coupon → coupon_template(id)
  IF NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conname = 'fk_coupon_template'
  ) THEN
ALTER TABLE coupon
    ADD CONSTRAINT fk_coupon_template
        FOREIGN KEY (template_id) REFERENCES coupon_template(id) ON DELETE CASCADE;
END IF;
END $$;