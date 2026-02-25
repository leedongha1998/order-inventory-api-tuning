# 실험 코드 패키지 분리 가이드

요청하신 내용처럼, 실험 목적 코드를 일반 주문 API 코드와 분리해 가독성과 운영 안전성을 높였습니다.

## 1) 패키지 분리 원칙
- **일반 운영 API**: `order.presentation`
- **성능 실험 API**: `order.presentation.experiment`
- **실험 전용 DTO**: `order.presentation.experiment.dto`

즉, 운영 경로와 실험 경로를 URL/패키지 모두에서 분리했습니다.

---

## 2) 분리된 엔드포인트

### 운영 API (기존)
- `POST /api/v1/orders`
- `GET /api/v1/orders/{orderId}`
- `PATCH /api/v1/orders/{orderId}`
- `GET /api/v1/orders/me/{memberId}`

### 실험 API (신규 분리)
- `POST /api/v1/experiments/orders/partition/np`
- `POST /api/v1/experiments/orders/partition/pt`
- `GET /api/v1/experiments/orders/{memberId}/me/cursor`
- `GET /api/v1/experiments/orders/{memberId}/me/summary`

---

## 3) 실험 목적별 매핑

### A. 파티셔닝 write 성능 실험
- 패키지: `order.presentation.experiment`
- DTO: `PartitionWriteReqDto`
- 엔드포인트: `/partition/np`, `/partition/pt`
- 목적: non-partition vs partition write latency 비교

### B. 페이징 전략 실험 (Offset vs Keyset)
- 패키지: `order.presentation.experiment`
- DTO: `OrderCursorPageDto`
- 엔드포인트: `/me/cursor`
- 목적: deep page에서 tail latency 개선 검증

### C. 응답 payload 경량화 실험
- 패키지: `order.presentation.experiment`
- DTO: `OrderSummaryDto`
- 엔드포인트: `/me/summary`
- 목적: full DTO 대비 CPU/응답시간 절감 검증

---

## 4) 운영 상 이점
- 일반 API와 실험 API의 경계가 명확해져 릴리스/모니터링/롤백 범위를 분리하기 쉬움
- Swagger 및 코드 탐색 시 실험 코드가 한곳에 모여 온보딩 비용 감소
- 실험 종료 후 패키지 단위 제거/비활성화 가능
