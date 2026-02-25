BEGIN;

-- 1) updated_at 자동 갱신 트리거 함수 (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'set_updated_at_timestamp'
  ) THEN
    CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
    RETURNS TRIGGER AS $f$
BEGIN
      NEW.updated_at := now();
RETURN NEW;
END;
    $f$ LANGUAGE plpgsql;
END IF;
END$$;

-- 2) payments 테이블 생성
CREATE TABLE IF NOT EXISTS payments
(
    id         BIGSERIAL PRIMARY KEY,
    status     VARCHAR(32)     NOT NULL,            -- Enum 문자열(@Enumerated.STRING). CHECK는 추후 확정 후 추가 권장
    member_id  BIGINT          NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    order_id   BIGINT          NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ     NOT NULL DEFAULT now()
    );

-- 3) 조회 최적화를 위한 인덱스 (상태/회원)
CREATE INDEX IF NOT EXISTS idx_payments_member_id ON payments(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_status    ON payments(status);

-- 4) payments.updated_at 자동 갱신 트리거
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_trigger
    WHERE  tgname = 'trg_payments_set_updated_at'
  ) THEN
CREATE TRIGGER trg_payments_set_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at_timestamp();
END IF;
END$$;

COMMIT;