# 추가 성능 실험 주제 제안 (운영 적용 우선순위 포함)

이 문서는 현재 저장소의 실험 축(인덱스/파티셔닝/ID전략/N+1/풀 튜닝) 다음 단계로, **실제 운영 의사결정에 영향이 큰 추가 실험 주제**를 정리한 제안서입니다.

## 0. 왜 이 주제들이 필요한가?
현재 프로젝트는 이미 DB/ORM/동시성 핵심 축을 실험했지만, 운영에서 자주 만나는 병목은 다음 3가지가 남습니다.
- API 경계(직렬화/압축/페이징 정책) 병목
- PostgreSQL 내부 파라미터/쿼리계획 변동 병목
- JVM/GC/커넥션 타임아웃 같은 런타임 병목

---

## 1. 우선순위 A (바로 효과를 보기 쉬운 주제)

### A-1) Pagination 전략: Offset vs Keyset
- **질문**: `orders/me` 구간에서 offset paging이 깊어질수록 p95/p99가 얼마나 나빠지는가?
- **가설**: page number가 커질수록 offset skip 비용이 커져 tail latency 급등.
- **실험 설계**
  - 고정 부하(RPS)에서 page=1, 10, 100, 500 비교
  - 동일 쿼리를 keyset 방식으로 재구현 후 동일 부하 재측정
- **채택 기준**
  - deep page 구간 p95 30% 이상 개선 + 오류율 동일/감소 시 keyset 채택.

### A-2) 응답 Payload 최적화: DTO 필드 수/JSON 크기 영향
- **질문**: 주문 상세/마이페이지 응답 필드 축소가 API latency와 CPU에 주는 효과는?
- **가설**: DB보다 직렬화/네트워크 비용이 지배하는 구간에서 의미 있는 개선 발생.
- **실험 설계**
  - Full DTO vs Slim DTO(A/B) 비교
  - gzip on/off 비교
- **채택 기준**
  - p95 10% 이상 개선 또는 spring-app CPU p95 10% 이상 절감.

### A-3) Cache 계층 실험: Redis read-through / cache-aside
- **질문**: `orders/me`, 상품 조회에 짧은 TTL 캐시를 적용하면 tail latency가 안정화되는가?
- **가설**: 반복 조회 시 DB CPU와 Hikari pending을 낮출 수 있음.
- **실험 설계**
  - 캐시 미적용 vs TTL(5s/30s/60s) 비교
  - hit ratio와 stale read 허용 범위 동시 측정
- **채택 기준**
  - hit ratio 60% 이상 + p99 개선 + 데이터 정합 요구 충족.

---

## 2. 우선순위 B (DB 내부 최적화 심화 주제)

### B-1) Covering Index (INCLUDE) 실험
- **질문**: 정렬/필터 컬럼 외 조회 컬럼까지 포함한 covering index가 random I/O를 줄이는가?
- **가설**: heap fetch 감소로 p95/p99 개선.
- **실험 설계**
  - 기존 복합 인덱스 vs INCLUDE 인덱스
  - `EXPLAIN (ANALYZE, BUFFERS)`와 k6 지표 동시 비교
- **채택 기준**
  - shared/local hit 개선 + p95 10% 이상 개선.

### B-2) Partition Pruning 검증
- **질문**: 파티션 키 조건이 쿼리 조건에 항상 포함되는가? 누락 시 성능 페널티는?
- **가설**: pruning 실패 시 파티셔닝 이점이 급감.
- **실험 설계**
  - pruning 성공/실패 쿼리 각각 테스트
  - scan 대상 partition 수와 latency 상관관계 측정
- **채택 기준**
  - 운영 경로의 95% 이상이 pruning 성공하도록 쿼리 템플릿 표준화.

### B-3) VACUUM/Autovacuum 민감도 실험
- **질문**: write-heavy 구간에서 bloat 누적이 tail latency에 주는 영향은?
- **가설**: 장시간 트래픽 후 p99 악화는 autovacuum 지연과 연관 가능.
- **실험 설계**
  - 장시간 soak test(1~3시간)
  - dead tuples, bloat, checkpoint 지표 수집
- **채택 기준**
  - 장시간 테스트에서 p99 드리프트가 임계치 초과 시 autovacuum 파라미터 조정.

---

## 3. 우선순위 C (JVM/애플리케이션 런타임 주제)

### C-1) GC 전략/힙 사이즈 A/B
- **질문**: 현재 부하에서 heap 크기와 GC pause가 tail latency에 미치는 영향은?
- **가설**: 힙 과소/과대 모두 p99 악화 가능.
- **실험 설계**
  - heap 1g/2g/4g + 기본 GC 설정 비교
  - GC pause(ms/s), allocation rate, p99 동시 관찰
- **채택 기준**
  - p99 최소 + GC pause 안정 구간 채택.

### C-2) Tomcat/Netty 큐 파라미터 (accept-count, keep-alive)
- **질문**: thread 수만이 아니라 accept queue, keep-alive가 burst traffic에서 어떤 영향을 주는가?
- **가설**: thread 고정 상태에서도 큐 파라미터 조정으로 오류율/대기 완화 가능.
- **실험 설계**
  - thread 고정 후 accept-count, keep-alive 매트릭스 테스트
- **채택 기준**
  - 오류율과 p99 동시 개선.

### C-3) DB Connection timeout / transaction timeout
- **질문**: 타임아웃 정책이 장애 전파(cascading failure)를 줄이는가?
- **가설**: 과도한 대기로 스레드 점유 시 전체 SLA 붕괴.
- **실험 설계**
  - timeout 단축/기본/완화 3그룹 테스트
  - 실패율 증가와 복구 속도 trade-off 비교
- **채택 기준**
  - 장애 상황에서 시스템 보호(빠른 실패 + 빠른 회복)가 되는 값 채택.

---

## 4. 실험 메타데이터 표준 (강력 권장)
모든 신규 실험 md에 아래를 고정 기입하세요.
- commit SHA
- DB row count / 데이터 분포
- profile (`idx-on/off`, pool/thread)
- 시나리오 스크립트 파일명
- warm-up 시간, 본측정 시간
- SLO 판정(통과/실패)

이 표준이 있어야 결과 재현성과 전문가 검증 가능성이 올라갑니다.

---

## 5. 시작 순서 (실전 권장)
1) Pagination (Offset vs Keyset)
2) Cache(짧은 TTL)
3) Covering index + EXPLAIN BUFFERS
4) GC/heap A/B
5) Soak test + autovacuum 검증

> 위 순서는 “투자 대비 성능 개선 + 운영 리스크 감소” 관점에서 추천한 순서입니다.
