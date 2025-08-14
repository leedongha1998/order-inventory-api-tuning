-- PostgreSQL 기준 (UUID, 타임스탬프 포함)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 상품 테이블
CREATE TABLE product (
                         id              BIGSERIAL PRIMARY KEY,
                         name            VARCHAR(200) NOT NULL,
                         price           NUMERIC(12,2) NOT NULL,
                         currency        CHAR(3) NOT NULL DEFAULT 'USD',
                         status          VARCHAR(20) NOT NULL, -- ACTIVE | INACTIVE
                         created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
                         updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 상품 상태 인덱스 (조회 효율)
CREATE INDEX idx_product_status ON product(status);

-- 2. 주문 테이블
CREATE TABLE orders (
                        id              BIGSERIAL PRIMARY KEY,
                        user_id         BIGINT NOT NULL,
                        status          VARCHAR(20) NOT NULL, -- PENDING | PAID | CANCELLED
                        total_amount    NUMERIC(12,2) NOT NULL,
                        created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
                        updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 상태 + 생성일 커버링 인덱스 (목록 조회 최적화)
CREATE INDEX idx_orders_status_created_at
    ON orders(status, created_at DESC);

-- 3. 주문 아이템 테이블
CREATE TABLE order_item (
                            id              BIGSERIAL PRIMARY KEY,
                            order_id        BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
                            product_id      BIGINT NOT NULL REFERENCES product(id),
                            unit_price      NUMERIC(12,2) NOT NULL, -- 주문 시점 가격 스냅샷
                            quantity        INT NOT NULL,
                            created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- FK 대응 인덱스 (조인 성능 향상 & 락 경합 최소화)
CREATE INDEX idx_order_item_order_id ON order_item(order_id);
CREATE INDEX idx_order_item_product_id ON order_item(product_id);

-- 4. 재고 테이블
CREATE TABLE inventory (
                           id              BIGSERIAL PRIMARY KEY,
                           product_id      BIGINT NOT NULL REFERENCES product(id),
                           quantity        INT NOT NULL,
                           updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_inventory_product_id ON inventory(product_id);

-- 5. 재고 변경 로그 (관측성, 디버깅)
CREATE TABLE inventory_log (
                               id              BIGSERIAL PRIMARY KEY,
                               product_id      BIGINT NOT NULL,
                               change_qty      INT NOT NULL,
                               reason          VARCHAR(100) NOT NULL,
                               created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_inventory_log_product_id_created_at
    ON inventory_log(product_id, created_at DESC);
