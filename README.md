# 1. 프로젝트 개요
전자상거래 도메인을 실험 환경으로 선정하여 Spring Boot + JPA 기반 애플리케이션에서 **DB 파티셔닝, ID 전략, N+1 최적화, 풀 튜닝**을 체계적으로 검증한 성능 최적화 프로젝트

---

# 2. 기술 스택
- **Backend**: Java, Spring Boot, JPA  
- **Database**: PostgreSQL, Flyway
- **Infra**: Docker
- **Performance Test & Monitoring**: K6, Prometheus, Grafana

---

# 3. 테스트 환경 구성
<img width="814" height="578" alt="image" src="https://github.com/user-attachments/assets/1cd361cb-4c0e-44d9-9a21-25b37225649a" />

# 4. ERD
<img width="967" height="755" alt="image" src="https://github.com/user-attachments/assets/89af7095-1388-4eaf-a7de-48167e0ab194" />


# 5. 실험과 결과 해석
## (1) 인덱스 적용 여부
- 인덱스 미적용: RPS 138.71, 실패율 12.8%, p50 응답 4,215ms  
- 인덱스 적용: RPS 354.03, 실패율 0.8%, p50 응답 16ms  
- **해석**: `status + created_at` 복합 인덱스로 조건절 필터링과 정렬을 동시에 해결 → 불필요한 I/O 제거

## (2) 파티셔닝
- 평균 응답시간 12.19ms → 10.21ms (16% 감소)  
- Dropped iteration 43건 → 0건  
- **해석**: 월 단위 파티션으로 인덱스·락 경합 분산, 대규모 insert 안정성 확보
- 상세 링크 : https://github.com/leedongha1998/order-inventory-api-tuning/wiki/db-%ED%8C%8C%ED%8B%B0%EC%85%98

## (3) JPA ID 전략
- IDENTITY: p95 3,985ms / p99 4,937ms  
- SEQUENCE: p95 2,850ms / p99 3,683ms  
- **해석**: SEQUENCE는 ID 블록 선할당으로 batch insert 가능, 지연 25~29% 개선. 단, 커넥션 풀 순간 포화 발생 가능
- 상세 링크 : https://github.com/leedongha1998/order-inventory-api-tuning/wiki/ID-%EC%83%9D%EC%84%B1-%EC%A0%84%EB%9E%B5-%EB%B9%84%EA%B5%90(Identity-vs-Sequence)

## (4) N+1 조회 최적화
- EntityGraph+BatchSize: p95·p99 가장 낮고 CPU 사용량 절감  
- Fetch Join: row 폭발로 오류 증가  
- **해석**: EntityGraph+BatchSize 전략이 tail latency 개선 및 효율적
- 상세 링크 : https://github.com/leedongha1998/order-inventory-api-tuning/wiki/N-1-%EB%AC%B8%EC%A0%9C(Fetch-Join-vs-Entity-Graph)
  
## (5) 커넥션 풀·스레드 풀
- Pool size=20 → p95 15.6ms, 오류율 최소  
- Thread=100 → RPS 811.9, 실패율 0.04%  
- **해석**: 풀 크기를 무작정 늘리면 컨텍스트 스위칭·락 경합으로 성능 저하 발생
- 상세 링크 : https://github.com/leedongha1998/order-inventory-api-tuning/wiki/%EC%BB%A4%EB%84%A5%EC%85%98-%ED%92%80-%EC%A6%9D%EA%B0%80%EC%97%90-%EB%94%B0%EB%A5%B8-%EC%84%B1%EB%8A%A5-%EB%B9%84%EA%B5%90-%EB%8D%B0%EC%9D%B4%ED%84%B0

## (6) 낙관적 락 vs 비관적 락
- **낙관적 락**: 버전 필드를 이용해 충돌 감지. 읽기 많은 환경에서 효율적이지만 충돌 시 재시도 비용 발생.  
- **비관적 락**: `SELECT ... FOR UPDATE` 구문으로 레코드 선점. 충돌은 방지되지만 동시성 떨어지고 데드락 위험 증가.  
- **결과 해석**:  
  - 읽기 비율이 높은 시나리오에서는 낙관적 락이 유리.  
  - 경쟁이 심한 시나리오에서는 비관적 락으로 데이터 정합성을 보장하는 편이 안정적.
- 상세 링크 : https://github.com/leedongha1998/order-inventory-api-tuning/wiki/%EB%82%99%EA%B4%80%EC%A0%81-%EB%9D%BD-vs-%EB%B9%84%EA%B4%80%EC%A0%81-%EB%9D%BD
---
