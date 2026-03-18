# 이력서 프로젝트 경력 기술

---

## 주문/재고 API 성능 튜닝 (order-inventory-api-tuning)

[Spring] 인덱스 최적화 – 조건절·정렬에 인덱스가 없으면 Full Scan이 발생해 부하 시 실패율이 급등한다는 가설을 검증하기 위해 복합 인덱스(status + created_at) 적용 → RPS 138→354, 실패율 12.8%→0.8%, p50 응답 4,215ms→16ms 개선
[Spring] DB 파티셔닝 – 데이터가 시간축으로 누적되는 주문 테이블 특성상 월 단위로 파티션을 분리하면 인덱스·락 경합이 분산되어 대량 Insert 안정성이 높아질 것이라 판단, Range 파티셔닝 적용 → 평균 응답 12.19ms→10.21ms(16% 감소), Dropped iteration 43건→0건 달성
[Spring] JPA ID 전략 비교 – IDENTITY 전략은 Insert 시마다 DB 왕복이 발생해 batch insert가 불가능하다는 점에 주목, SEQUENCE 전략으로 ID 블록 선할당 시 batch insert 가능 여부와 실제 latency 개선폭을 정량적으로 확인 → SEQUENCE에서 p95/p99 지연 25~29% 개선, 단 커넥션 풀 순간 포화 리스크 확인
[Spring] N+1 최적화 – 1:N 연관 조회 시 Fetch Join은 row 폭발로 오류가 증가한다는 문제를 인식하고, Fetch Join / EntityGraph+BatchSize 전략을 부하 조건에서 비교 → EntityGraph+BatchSize 조합이 tail latency 및 CPU 사용량 측면에서 최적임을 도출
[Spring] 커넥션/스레드 풀 튜닝 – 풀 크기를 무작정 늘리면 컨텍스트 스위칭·락 경합으로 오히려 성능이 저하될 것이라는 가설을 검증하기 위해 pool size(10/20/30)·thread(50/100/200) 매트릭스 실험 → pool=20·thread=100 조합이 RPS 811.9, 실패율 0.04%로 최적값임을 확인
[Spring] 낙관적 락 vs 비관적 락 – 재고 차감처럼 동시 쓰기 충돌이 발생하는 시나리오에서 락 선택이 처리량과 정합성에 미치는 영향을 파악하기 위해, 읽기/쓰기 비율별로 두 전략의 트레이드오프(충돌 재시도 비용 vs 데드락 위험) 실험 및 분석
[Spring] Cursor 기반 페이지네이션 구현 – 마이페이지 주문 목록처럼 page number가 깊어질수록 Offset skip 비용이 증가해 tail latency가 급등한다는 문제를 해결하기 위해 Keyset(cursor) 방식 실험용 API 설계 및 구현 (복합 커서: createdAt+id)
[Spring] Summary DTO Payload 최적화 – 목록 조회 응답에 불필요한 상세 필드(items 등)가 포함되어 직렬화·네트워크 비용이 지배적일 수 있다는 가설 하에, JPQL projection 기반 경량 DTO API를 구현해 Full DTO 대비 응답 크기·CPU 개선 여부 실험
[Spring] Redis 캐시 실험 – 반복 조회가 많은 요약 목록 경로에서 DB hit을 줄이면 Hikari pending과 tail latency를 동시에 낮출 수 있는지 확인하기 위해 cache-aside 패턴 적용, TTL(5s/30s/60s)별 hit ratio·latency 비교, Redis 장애 시 DB fallback 및 Micrometer 메트릭(hit/miss/fallback) 수집
[Spring] Covering Index 실험 – 정렬·필터 컬럼 외 조회 컬럼까지 인덱스에 포함하면 heap fetch 자체를 줄일 수 있다는 판단 하에 (member_id, created_at DESC, id DESC) INCLUDE (status, total_amount) 인덱스를 추가하고 EXPLAIN BUFFERS와 k6 지표로 p95/p99 개선 여부 관측
[Infra] 성능 관측 환경 구성 – 실험 조건별 수치 비교를 재현 가능한 형태로 남기기 위해 K6 부하 시나리오, Prometheus + Grafana 대시보드, Micrometer/Actuator 메트릭 수집 파이프라인 구성
[Docs] 운영 의사결정 Runbook 작성 – 실험 수치만으로는 현장 적용 판단이 어렵다는 점을 고려해, 실험 결과를 기반으로 각 튜닝 항목의 채택 기준·롤백 조건·표준 임계치를 Runbook으로 문서화
