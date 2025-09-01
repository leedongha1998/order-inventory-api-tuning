CREATE TABLE member (
                        id           BIGSERIAL PRIMARY KEY,
                        email        TEXT UNIQUE,
                        name         TEXT,
                        status       TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
                        created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                        updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);