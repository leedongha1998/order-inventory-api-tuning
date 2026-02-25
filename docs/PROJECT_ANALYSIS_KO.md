# 프로젝트 분석 리포트 (order-inventory-api-tuning)

## 1) 한 줄 요약
이 프로젝트는 **주문/재고 도메인**을 대상으로, Spring Boot + JPA + PostgreSQL 기반에서 **인덱스, 파티셔닝, ID 전략, N+1 완화, 풀 튜닝**을 실험하고 성능을 비교·관찰하는 목적의 실험형 API 서버입니다.

## 2) 현재 구조 요약
- 도메인별 패키지 분리: `order`, `product`, `inventory`, `payment`, `member`, `idempotency`.
- 계층 분리: `presentation`(Controller/DTO), `application`(Service), `domain`(Entity/Repository 인터페이스), `infrastructure`(JPA 구현체).
- 성능 관측/실험 도구: K6 시나리오, Prometheus/Grafana 설정, Flyway 마이그레이션.

## 3) 기술적 강점
1. **실험 주제가 명확**
   - README에 실험 항목/수치/해석이 구조적으로 정리되어 있어 재현 및 비교 관점이 뚜렷합니다.
2. **인덱스/파티셔닝 실험 경로 확보**
   - Flyway SQL과 별도 스크립트가 정리되어 있어 DB 측면 튜닝 실험 반복에 유리합니다.
3. **N+1 비교 전략이 코드 레벨에 노출**
   - 기본 조회/Fetch Join/EntityGraph 경로를 서비스 코드에서 전환해 비교할 수 있도록 구성되어 있습니다.
4. **운영 관찰성 고려**
   - Micrometer/Actuator/Prometheus 설정으로 API·DB 메트릭 수집 기반이 마련되어 있습니다.

## 4) 주요 리스크/개선 포인트
1. **EntityGraph 이름 불일치 가능성(런타임 위험)**
   - `JpaOrderRepository`는 `Order.withMember` 그래프를 참조하지만, `Order` 엔티티의 해당 `@NamedEntityGraph` 선언이 주석 처리되어 있습니다.
   - 환경/부트 시점에 따라 `IllegalArgumentException: Unable to locate EntityGraph` 계열 오류 가능성이 있습니다.
2. **주문 상태 enum/DDL 값 불일치 가능성**
   - 코드 enum은 `CANCELED`를 사용하지만, 마이그레이션 체크 제약은 `CANCELLED`(L 2개)로 정의되어 있습니다.
   - 취소 주문 저장 시 DB 제약 위반 리스크가 있습니다.
3. **주문 생성 응답 멱등성 미적용**
   - `idempotency_key` 테이블/엔티티는 있으나, 주문 생성 API에 멱등 키 처리 흐름이 연결되어 있지 않습니다.
   - 재시도/네트워크 타임아웃 환경에서 중복 주문 생성 가능성이 남아 있습니다.
4. **예외 처리 일관성 부족**
   - 서비스에서 다수 `orElseThrow()` 기본 예외를 사용해 도메인 오류 코드 매핑이 약해질 수 있습니다.
5. **검증(Validation) 적용 여지**
   - Controller 요청 DTO에 Bean Validation 적용이 제한적이며, 잘못된 요청을 조기에 차단하는 장치가 더 필요합니다.
6. **실험 산출물 메타데이터 혼선**
   - `pt.md` 파일 제목이 `np`로 표기되어 결과 해석 시 혼동 여지가 있습니다.

## 5) 우선순위별 개선 제안 (실행 난이도 대비)
### P0 (즉시)
- `Order.withMember` EntityGraph 선언 복구 또는 Repository `@EntityGraph` 참조 변경.
- 주문 취소 상태 값(`CANCELED` vs `CANCELLED`) 코드/DDL 중 하나로 통일.

### P1 (단기)
- 주문 생성 API에 Idempotency-Key 기반 중복 방지 플로우 도입.
- Service 계층 `orElseThrow()`를 `BusinessException(ErrorCode)`로 통일해 API 오류 계약 안정화.
- 요청 DTO에 `@Valid` + 필드 제약 추가.

### P2 (중기)
- QueryDSL 기반 조회 쿼리(정렬/페이징/조인)로 성능 튜닝 포인트를 코드화.
- 성능 리포트 자동 생성 템플릿 표준화(파일명, 실험조건, 비교표 통일).

## 6) 분석 결론
- 현재 저장소는 “기능 개발”보다 “성능 실험/튜닝”에 최적화된 구조를 갖추고 있습니다.
- 다만 **런타임 안정성에 직결되는 불일치(엔티티 그래프, 상태값 표기)**가 보여, 이를 먼저 정리하면 실험 결과의 신뢰성과 재현성이 크게 높아질 것으로 보입니다.

## 7) 질문 답변: 그래서 지금 무엇을 보완하면 좋나?
네. 아래 5가지는 “효과 대비 투자비용” 기준으로 우선 보완을 추천합니다.

1. **JPA 그래프 참조 안정화 (가장 먼저)**
   - `Order.withMember` 그래프를 실제 엔티티에 복구하거나, Repository에서 참조하는 그래프명을 현재 선언과 맞춰 통일하세요.
   - 이 항목은 기능 이상보다 **런타임 시작/조회 실패 가능성**에 직접 영향이 큽니다.

2. **주문 상태 문자열 단일화**
   - `CANCELED`/`CANCELLED`를 코드·DDL·테스트 데이터 전 구간에서 한 값으로 통일하세요.
   - 사소해 보여도 운영 중 insert/update 실패를 유발할 수 있어 조기 정리가 좋습니다.

3. **주문 생성 멱등성 실제 연결**
   - 이미 존재하는 `idempotency_key` 저장소를 주문 생성 엔드포인트에 연결하고, 재시도 시 동일 응답 반환 정책을 확정하세요.
   - 부하/네트워크 불안정 구간에서 중복 주문을 막는 안전장치가 됩니다.

4. **도메인 예외 표준화 + 요청 검증 강화**
   - `orElseThrow()` 기본 예외를 비즈니스 예외로 치환하고, DTO에 Validation을 추가해 에러 응답 스키마를 안정화하세요.
   - 클라이언트/모니터링 입장에서 원인 분류가 쉬워집니다.

5. **실험 산출물 정합성 정리**
   - 결과 파일명/제목(`np`/`pt`)과 실험 조건 메타데이터를 일관화하세요.
   - 성능 개선폭이 실제인지, 측정 실수인지 검증 가능한 상태가 됩니다.

### 빠른 실행 체크리스트 (1~2일)
- [ ] EntityGraph 이름/선언 통일
- [ ] 주문 상태값 상수(코드+DDL) 통일
- [ ] Order 생성 API에 Idempotency-Key 헤더 처리 추가
- [ ] 주문/결제/재고 주요 시나리오 통합 테스트 보강
- [ ] k6 결과 리포트 템플릿(실험조건/버전/커밋 SHA) 고정
