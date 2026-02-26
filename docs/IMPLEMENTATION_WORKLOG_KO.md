# 성능 실험 주제 기반 구현 작업 내역

## 1) 작업 목적
`ADDITIONAL_PERF_EXPERIMENT_TOPICS_KO.md`에서 제안한 항목 중,
운영에서 즉시 검증 가능한 주제를 코드로 구현해 **실험 가능한 API 경로**를 추가했습니다.

이번 구현은 다음 2가지 실험 주제에 직접 대응합니다.
- Pagination 전략 실험(Offset vs Keyset)
- 응답 Payload 최적화 실험(Full DTO vs Summary DTO)

또한 가독성과 운영 안전성을 위해 **실험 코드를 별도 패키지로 분리**했습니다.

---

## 2) 구현 내용 상세

### 2-1. Cursor 기반 페이지네이션 API 추가 (Keyset 실험용)
- 신규 엔드포인트:
  - `GET /api/v1/experiments/orders/{memberId}/me/cursor`
- 파라미터:
  - `cursorCreatedAt` (optional, ISO-8601)
  - `cursorId` (optional)
  - `size` (default: 20, max: 100)
- 반환:
  - `orders`
  - `nextCursorCreatedAt`
  - `nextCursorId`
  - `hasNext`

#### 구현 포인트
- `(createdAt desc, id desc)` 복합 커서 조건으로 안정적인 keyset 페이징 수행.
- `size+1` 조회 후 잘라내는 방식으로 `hasNext`를 안전하게 계산.
- 조회는 기존 EntityGraph 전략(`Order.withMemberAndItems`)을 재사용.

---

### 2-2. Summary API 추가 (Payload 실험용)
- 신규 엔드포인트:
  - `GET /api/v1/experiments/orders/{memberId}/me/summary`
- 목적:
  - 기존 상세 DTO(`items` 포함)와 비교해, 더 작은 payload가 p95/p99 및 CPU에 미치는 영향 측정.
- 구현 방식:
  - JPQL `select new ...OrderSummaryDto(...)` projection 사용.
  - 필요한 필드(`orderId`, `orderStatus`, `totalAmount`, `createdAt`)만 반환.

---

## 3) 패키지 분리 결과

### 운영 API 패키지
- `order.presentation.OrderController`
  - 주문 생성/단건조회/취소/기본 목록(운영 경로)

### 실험 API 패키지
- `order.presentation.experiment.OrderExperimentController`
  - 파티셔닝 쓰기 실험(`np`/`pt`)
  - keyset 실험(`cursor`)
  - payload 경량화 실험(`summary`)

### 실험 전용 DTO 패키지
- `order.presentation.experiment.dto.PartitionWriteReqDto`
- `order.presentation.experiment.dto.OrderCursorPageDto`
- `order.presentation.experiment.dto.OrderSummaryDto`

---

## 4) 변경 파일
- `src/main/java/com/example/order_api_tuning/order/presentation/OrderController.java`
- `src/main/java/com/example/order_api_tuning/order/presentation/experiment/OrderExperimentController.java`
- `src/main/java/com/example/order_api_tuning/order/application/service/OrderService.java`
- `src/main/java/com/example/order_api_tuning/order/domain/repository/OrderRepository.java`
- `src/main/java/com/example/order_api_tuning/order/infrastructure/JpaOrderRepository.java`
- `src/main/java/com/example/order_api_tuning/order/infrastructure/OrderRepositoryImpl.java`
- `src/main/java/com/example/order_api_tuning/order/presentation/experiment/dto/PartitionWriteReqDto.java`
- `src/main/java/com/example/order_api_tuning/order/presentation/experiment/dto/OrderCursorPageDto.java`
- `src/main/java/com/example/order_api_tuning/order/presentation/experiment/dto/OrderSummaryDto.java`

---

## 5) 실험 가이드 (바로 실행 가능)

### 5-1. Offset vs Keyset
1. 기존 API(Offset)
- `GET /api/v1/orders/me/{memberId}?page=0&size=20`
- `GET /api/v1/orders/me/{memberId}?page=100&size=20`

2. 신규 API(Keyset)
- 첫 페이지:
  - `GET /api/v1/experiments/orders/{memberId}/me/cursor?size=20`
- 다음 페이지:
  - 이전 응답의 `nextCursorCreatedAt`, `nextCursorId` 사용
  - `GET /api/v1/experiments/orders/{memberId}/me/cursor?size=20&cursorCreatedAt=...&cursorId=...`

3. 비교 지표
- p95, p99, http_req_failed
- spring-app CPU p95
- Hikari pending

### 5-2. Full DTO vs Summary DTO
1. Full
- `GET /api/v1/orders/me/{memberId}?page=0&size=20`
2. Summary
- `GET /api/v1/experiments/orders/{memberId}/me/summary?page=0&size=20`
3. 비교 지표
- p95/p99
- 응답 바이트 크기
- app CPU 사용률

---

## 6) 의사결정 기준 (권장)
- Keyset 채택:
  - deep page 구간에서 p95 30% 이상 개선
- Summary 채택:
  - p95 10% 이상 개선 또는 app CPU p95 10% 이상 절감
- 둘 다 충족 시:
  - `orders/me` 기본 경로를 summary + keyset 중심으로 재설계 검토

---

## 7) 주의사항
- Keyset은 정렬 키(`createdAt`, `id`)의 안정성이 중요하므로, 정렬 조건 변경 시 커서 규칙을 함께 변경해야 합니다.
- Summary API는 상세 item 정보가 없으므로, UI/클라이언트 요구사항에 따라 상세 조회 API와 병행 운영이 필요합니다.

---

## 8) 추가 진행: 우선순위 3~6 구현 반영

`ADDITIONAL_PERF_EXPERIMENT_TOPICS_KO.md` 기준으로, 기존 1~2번(키셋/요약 DTO)에 이어 아래 항목을 추가 반영했습니다.

### 8-1. 우선순위 3) Cache(짧은 TTL)
- 신규 실험 엔드포인트:
  - `GET /api/v1/experiments/orders/{memberId}/me/summary/cached`
- 동작:
  - Redis cache-aside 패턴으로 summary 페이지를 캐싱
  - 응답 헤더 `X-Experiment-Cache-Hit`로 hit/miss 식별
  - `ttlSeconds` 쿼리 파라미터로 TTL 실험(5/30/60s 등)
  - Redis 연결 실패/직렬화 실패 시에도 DB fallback으로 API는 정상 응답(실험 안정성 강화)
  - Micrometer metric `order.summary.cache.result{result=...}`로 hit/miss/fallback 오류 관측 가능

### 8-2. 우선순위 4) Covering Index + EXPLAIN BUFFERS
- Flyway 마이그레이션 추가:
  - `V12__add_covering_index_for_order_summary.sql`
- 인덱스:
  - `(member_id, created_at DESC, id DESC) INCLUDE (status, total_amount)`
- 목적:
  - Summary 조회 시 heap fetch 감소 여부와 p95/p99 개선 관찰

### 8-3. 우선순위 5) Soak test + autovacuum 검증
- SQL 관측 스크립트 추가:
  - `scripts/experiments/b3_autovacuum_observe.sql`
- 확인 지표:
  - `pg_stat_user_tables` dead tuples / autovacuum 이력
  - `pg_stat_bgwriter` 체크포인트 지표

### 8-4. 우선순위 6) Partition pruning 검증
- SQL 검증 스크립트 추가:
  - `scripts/experiments/b2_partition_pruning_check.sql`
- 비교 방식:
  - 파티션 키(created_at) 조건 포함/미포함 쿼리의 `EXPLAIN (ANALYZE, BUFFERS)` 비교

### 8-5. 부하 테스트 스크립트
- 신규 k6 시나리오:
  - `perf/k6/scenarios/order-summary-cache.js`
- 목적:
  - 캐시 사용 여부(USE_CACHE)와 TTL 별 hit ratio 및 latency 비교
