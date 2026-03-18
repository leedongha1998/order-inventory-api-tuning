# 이력서 프로젝트 경력 기술

---

## 주문/재고 API 성능 튜닝 (order-inventory-api-tuning)

[Spring] 인덱스 최적화 – 복합 인덱스(status + created_at) 적용으로 RPS 138→354, 실패율 12.8%→0.8%, p50 응답 4,215ms→16ms 개선
[Spring] DB 파티셔닝 – 월 단위 Range 파티셔닝 적용으로 평균 응답 12.19ms→10.21ms(16% 감소), Dropped iteration 43건→0건 달성
[Spring] JPA ID 전략 비교 – IDENTITY vs SEQUENCE 전략 실험을 통해 SEQUENCE 전략에서 p95/p99 지연 25~29% 개선 확인
[Spring] N+1 최적화 – Fetch Join / EntityGraph+BatchSize 전략 비교 실험을 통해 EntityGraph+BatchSize 조합이 tail latency 및 CPU 사용량 측면에서 최적임을 도출
[Spring] 커넥션/스레드 풀 튜닝 – pool size(10/20/30)·thread(50/100/200) 매트릭스 실험으로 pool=20·thread=100 조합이 RPS 811.9, 실패율 0.04%로 최적값임을 확인
[Spring] 낙관적 락 vs 비관적 락 – 읽기/쓰기 비율별 시나리오로 락 전략 트레이드오프(충돌 재시도 vs 데드락 위험) 실험 및 분석
[Spring] Cursor 기반 페이지네이션 구현 – Offset 방식 대비 Keyset(cursor) 방식의 deep page 구간 tail latency 개선 실험용 API 설계 및 구현 (복합 커서: createdAt+id)
[Spring] Summary DTO Payload 최적화 – JPQL projection 기반 경량 DTO API 구현으로 직렬화 비용 및 응답 크기 감소 실험
[Spring] Redis 캐시 실험 – cache-aside 패턴 적용, TTL(5s/30s/60s) 별 hit ratio·latency 비교, Redis 장애 시 DB fallback 및 Micrometer 메트릭(hit/miss/fallback) 수집
[Spring] Covering Index 실험 – (member_id, created_at DESC, id DESC) INCLUDE (status, total_amount) 인덱스 추가 후 heap fetch 감소 및 p95/p99 개선 여부 관측
[Infra] 성능 관측 환경 구성 – K6 부하 시나리오, Prometheus + Grafana 대시보드, Micrometer/Actuator 메트릭 수집 파이프라인 구성
[Docs] 운영 의사결정 Runbook 작성 – 실험 결과를 기반으로 인덱스/파티셔닝/ID전략/N+1/풀 튜닝 각 항목의 채택 기준, 롤백 조건, 표준 임계치를 문서화
