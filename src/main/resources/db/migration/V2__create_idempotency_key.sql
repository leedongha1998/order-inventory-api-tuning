-- V1__create_idempotency_key.sql
CREATE TABLE idempotency_key (
                                 id BIGSERIAL PRIMARY KEY,
                                 key VARCHAR(64) NOT NULL,
                                 response_body TEXT,
                                 created_at TIMESTAMPTZ NOT NULL,
                                 CONSTRAINT uk_idempotency_key UNIQUE (key)
);

-- 추후 상태(Status) 컬럼이 필요하다면
-- ALTER TABLE idempotency_key ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'PENDING';

COMMENT ON TABLE idempotency_key IS 'Idempotency 키 저장소 (중복 요청 방지 및 응답 캐싱)';
COMMENT ON COLUMN idempotency_key.key IS 'Idempotency Key 값';
COMMENT ON COLUMN idempotency_key.response_body IS '이전에 반환된 응답 JSON';
COMMENT ON COLUMN idempotency_key.created_at IS '생성 시각';
