-- 공통: updated_at 자동 갱신 트리거
CREATE
OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at
:= now();
RETURN NEW;
END
$$
LANGUAGE plpgsql;