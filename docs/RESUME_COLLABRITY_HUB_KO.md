# 이력서 프로젝트 경력 기술

---

## 주문/재고 API 성능 튜닝 (order-inventory-api-tuning)

[Spring] 복합 인덱스 적용 – Full Scan으로 인한 부하 시 실패율 급등 문제를 해결하기 위해 복합 인덱스(status + created_at) 적용
[Spring] DB 파티셔닝 – 누적 데이터 증가에 따른 Insert 성능 저하 방지를 위해 주문 테이블에 월 단위 Range 파티셔닝 적용
[Spring] JPA ID 전략 비교 – IDENTITY 전략의 batch insert 불가 문제를 해결하기 위해 SEQUENCE 전략으로 전환 및 latency 개선 효과 검증
[Spring] N+1 쿼리 최적화 – 1:N 연관 조회 시 Fetch Join의 row 폭발 문제를 해결하기 위해 EntityGraph + BatchSize 전략 도입
[Spring] 커넥션/스레드 풀 튜닝 – 풀 크기 과잉 확장 시 오히려 성능 저하가 발생함을 검증하기 위해 pool·thread 매트릭스 실험으로 최적 조합 도출
[Spring] 낙관적 락 vs 비관적 락 비교 – 재고 차감 동시성 제어 전략 선택을 위해 읽기/쓰기 비율별 락 트레이드오프 실험 및 분석
[Spring] Cursor 기반 페이지네이션 구현 – Offset 방식의 deep page 구간 tail latency 급등 문제를 해결하기 위해 Keyset(cursor) 방식 API 설계 및 구현
[Spring] Summary DTO 경량화 – 불필요한 필드 포함으로 인한 직렬화 비용 절감을 위해 JPQL projection 기반 경량 DTO API 구현
[Spring] Redis 캐시 적용 – 반복 조회 트래픽의 DB 부하 분산을 위해 cache-aside 패턴 적용 및 TTL별 hit ratio·latency 비교, 장애 시 fallback 처리 구현
[Spring] Covering Index 적용 – heap fetch 제거로 조회 성능 향상을 검증하기 위해 조회 컬럼 포함 복합 인덱스 추가 및 EXPLAIN BUFFERS 분석
[Infra] 성능 관측 환경 구성 – 실험 결과의 재현 가능한 비교를 위해 K6, Prometheus, Grafana, Micrometer 기반 모니터링 파이프라인 구성
[Docs] 운영 의사결정 Runbook 작성 – 실험 결과 기반으로 각 튜닝 항목의 채택 기준·롤백 조건·표준 임계치 문서화
