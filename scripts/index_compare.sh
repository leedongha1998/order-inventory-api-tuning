#!/usr/bin/env bash
set -euo pipefail

# ===== 사용자 설정 =====
CONTAINER="my-postgres"                 # Docker 컨테이너 이름
DB_USER="dongha"                        # DB 사용자
ITER=5                                  # 반복 횟수
#QUERY='SELECT * FROM orders WHERE id=1;'
#QUERY='SELECT o.id, o.user_id, o.created_at, oi.product_id, oi.quantity, oi.unit_price
#       FROM orders o
#       JOIN order_item oi ON oi.order_id = o.id
#       WHERE o.id = 1;'
#QUERY='SELECT o.id, o.user_id, o.created_at
#      FROM orders o
#      ORDER BY o.created_at DESC
#      OFFSET 100000 LIMIT 50';
QUERY="SELECT id, user_id, created_at, status
FROM orders
WHERE status = 'PAID'
ORDER BY created_at DESC
LIMIT 100;"
gu

CSV_OUT="./results/index_compare_result.csv"

# ===== 결과 디렉토리 생성 =====
mkdir -p "$(dirname "$CSV_OUT")"

# ===== 컨테이너 내부에 쿼리 파일 생성 (CRLF 제거) =====
docker exec -i "$CONTAINER" bash -lc "cat > /tmp/query.sql" <<'SQL'
__QUERY_PLACEHOLDER__
SQL
# 위 placeholder 치환
docker exec "$CONTAINER" bash -lc "sed -i 's/\r\$//' /tmp/query.sql" >/dev/null 2>&1 || true
docker exec "$CONTAINER" bash -lc "truncate -s 0 /tmp/query.sql && printf '%s\n' \"$(
  # 여기서 호스트의 QUERY 변수를 안전하게 주입
  printf "%s" "$QUERY"
)\" >> /tmp/query.sql"

# ===== CSV 헤더(덮어쓰기) =====
echo "db,mode,iter,planning_ms,execution_ms,shared_hit,shared_read" > "$CSV_OUT"

run_one() {
  local db="$1"   # bench_idx_on | bench_idx_off
  local mode="$2" # on | off
  local iter="$3"

  docker exec "$CONTAINER" bash -lc '
    set -euo pipefail
    db="'"$db"'"
    mode="'"$mode"'"
    iter="'"$iter"'"
    user="'"$DB_USER"'"

    # 인덱스 OFF 모드면 플래너 스위치 비활성화
    PREP=""
    if [ "$mode" = "off" ]; then
      PREP="SET enable_indexscan=off; SET enable_bitmapscan=off; SET enable_indexonlyscan=off;"
    fi

    # 쿼리 내용 읽어 EXPLAIN 문 구성
    Q_CONTENT="$(tr -d "\r" </tmp/query.sql)"
    [ -z "$Q_CONTENT" ] && { echo "empty /tmp/query.sql"; exit 1; }

    OUT="$(psql -U "$user" -d "$db" -v ON_ERROR_STOP=1 -At -c "$PREP EXPLAIN (ANALYZE, BUFFERS) $Q_CONTENT")"

    # ---- 파싱(모두 단일 인용부호 사용) ----
    planning_ms="$(printf "%s\n" "$OUT" | awk -F": " '"'"'/^Planning Time:/ {print $2}'"'"' | awk '"'"'{print $1}'"'"' | tail -n1)"
    execution_ms="$(printf "%s\n" "$OUT" | awk -F": " '"'"'/^Execution Time:/ {print $2}'"'"' | awk '"'"'{print $1}'"'"' | tail -n1)"

    # 첫 Buffers 라인 찾기
    bufline="$(printf "%s\n" "$OUT" | grep -m1 '"'"'^ *Buffers:'"'"' || true)"
    if [ -n "$bufline" ]; then
      shared_hit="$(printf "%s\n" "$bufline" | sed -n '"'"'s/.*shared hit=\([0-9]\+\).*/\1/p'"'"')"
      shared_read="$(printf "%s\n" "$bufline" | sed -n '"'"'s/.*read=\([0-9]\+\).*/\1/p'"'"')"
      [ -z "${shared_hit:-}" ] && shared_hit=0
      [ -z "${shared_read:-}" ] && shared_read=0
    else
      shared_hit=0
      shared_read=0
    fi

    printf "%s,%s,%s,%s,%s,%s,%s\n" "$db" "$mode" "$iter" "${planning_ms:-0}" "${execution_ms:-0}" "$shared_hit" "$shared_read"
  ' >> "$CSV_OUT"
}

# ===== 실행 루프 =====
for i in $(seq 1 "$ITER"); do
  run_one "bench_idx_on"  "on"  "$i"
  run_one "bench_idx_off" "off" "$i"
done

# ===== 보기 좋게 출력 =====
if command -v column >/dev/null 2>&1; then
  column -t -s, "$CSV_OUT"
else
  cat "$CSV_OUT"
fi

echo
echo "CSV saved to: $CSV_OUT"
