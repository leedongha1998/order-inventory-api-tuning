package com.example.order_api_tuning;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertSame;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.entity.OrderStatus;
import jakarta.persistence.EntityManager;
import jakarta.persistence.FlushModeType;
import java.math.BigDecimal;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
public class first_cahce_test {

  @Autowired
  EntityManager em;
  @Autowired
  PlatformTransactionManager txm;

  private TransactionTemplate tx;
  private Statistics stats;

  @Container
  static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16")
      .withReuse(true);

  @DynamicPropertySource
  static void dbProps(DynamicPropertyRegistry r) {
    r.add("spring.datasource.url", pg::getJdbcUrl);
    r.add("spring.datasource.username", pg::getUsername);
    r.add("spring.datasource.password", pg::getPassword);
    // Flyway는 기본적으로 동일 DataSource 사용. 별도 설정 불필요.
  }

  @BeforeEach
  void setUp() {
    tx = new TransactionTemplate(txm);

    var emf = em.getEntityManagerFactory();
    // 1) 우선 표준 인터페이스로
    org.hibernate.SessionFactory sf = emf.unwrap(org.hibernate.SessionFactory.class);
    org.hibernate.stat.Statistics s = sf.getStatistics();

    // 2) 실패 시(드문 케이스) 구현체로 재시도
    if (s == null) {
      org.hibernate.engine.spi.SessionFactoryImplementor sfi =
          emf.unwrap(org.hibernate.engine.spi.SessionFactoryImplementor.class);
      s = sfi.getStatistics();
    }

    this.stats = s;
    this.stats.clear();

    seedIfNeeded();
    this.stats.clear();
    em.clear();

  }

  // ===== 유틸 =====
  private long ps() { return stats.getPrepareStatementCount(); }
  private long updates() { return stats.getEntityUpdateCount(); }
  private long inserts() { return stats.getEntityInsertCount(); }
  private long flushes() { return stats.getFlushCount(); }

  private void seedIfNeeded() {
    // 테스트 데이터 보장: id=1L 존재하도록
    tx.execute(status -> {
      if (em.find(Order.class, 1L) == null) {
        Order o = Order.initMember(new Member());
        o.completeOrder();
        em.persist(o);
        em.flush();
      }
      return null;
    });
  }

  // 1) Identity Map 적중: 같은 트랜잭션에서 같은 PK는 동일 인스턴스, SELECT 1회
  @Test
  @Transactional
  void t1_identityMap_hit() {
    em.clear(); // 이전 테스트 결과 제거
    long ps0 = ps();
    Order o1 = em.find(Order.class, 1L);           // SELECT +1
    Order o2 = em.find(Order.class, 1L);           // SELECT +0 (1차 캐시)
    long ps1 = ps();

    assertSame(o1, o2); // 둘이 같은 객체임을 확인
    assertThat(ps1 - ps0).isEqualTo(1L); // 쿼리가 1개만 나갔음을 확인
  }

  // 2) 트랜잭션 경계가 바뀌면 캐시 초기화 → 각 트랜잭션에서 SELECT 발생
  @Test
  void t2_tx_boundary_resets_L1() {
    stats.clear();
    tx.execute(s -> {
      em.clear(); stats.clear();
      em.find(Order.class, 1L); // DB 1회
      assertEquals(1L, stats.getEntityLoadCount());
      return null;
    });

    tx.execute(s -> {
      em.clear(); stats.clear(); // 새 Tx, 새 PC
      em.find(Order.class, 1L); // 다시 DB 1회
      assertEquals(1L, stats.getEntityLoadCount());
      return null;
    });
  }


  // 3) JPQL은 항상 DB를 친다. 단, 반환 객체는 L1 인스턴스에 바인딩된다.
  @Test
  @Transactional
  void t3_jpql_always_hits_db() {
    em.find(Order.class, 1L);                      // SELECT +1
    long ps0 = ps();

    Order fromJpql = em.createQuery(
            "select o from Order o where o.id = :id", Order.class)
        .setParameter("id", 1L)
        .getSingleResult();                        // SELECT +1
    long ps1 = ps();

    Order fromFind = em.find(Order.class, 1L);     // SELECT +0
    assertSame(fromFind, fromJpql);
    assertThat(ps1 - ps0).isEqualTo(1L);
  }

  // 4) 더티체킹 + flush: 변경 후 flush 시 UPDATE 1회
  @Test
  void t4_dirty_checking_and_flush() {
    em.clear(); stats.clear();

    Order o = em.find(Order.class, 1L);
    long u0 = stats.getEntityUpdateCount();

    // 상태 대신 안전한 숫자 컬럼만 수정
    o.setTotalAmount(o.getTotalAmount().add(new BigDecimal("1.00")));

    em.flush(); // 여기서 UPDATE 1회
    long u1 = stats.getEntityUpdateCount();
    assertEquals(1L, u1 - u0);
  }


  // 5) FlushMode에 따른 JPQL 가시성/flush 트리거
  @Test
  void t5_flushmode_auto_vs_commit() {
    em.clear(); stats.clear();
    var session = em.unwrap(org.hibernate.Session.class);

    // (A) AUTO + 같은 엔티티 JPQL => auto-flush 발생
    session.setHibernateFlushMode(org.hibernate.FlushMode.AUTO);
    Order o1 = em.find(Order.class, 1L);
    o1.setTotalAmount(o1.getTotalAmount().add(new BigDecimal("2.00")));
    long u0 = stats.getEntityUpdateCount();

    em.createQuery("select count(o) from Order o", Long.class).getSingleResult(); // Order 를 만지므로 flush O
    long u1 = stats.getEntityUpdateCount();
    assertEquals(1L, u1 - u0);   // <-- 여기 기대값을 1로

    // (B) COMMIT + 다른 엔티티 JPQL => auto-flush 없음
    em.clear(); stats.clear();
    session.setHibernateFlushMode(org.hibernate.FlushMode.COMMIT);
    Order o2 = em.find(Order.class, 1L);
    o2.setTotalAmount(o2.getTotalAmount().add(new BigDecimal("3.00")));
    long u2 = stats.getEntityUpdateCount();

    em.createQuery("select count(m) from Member m", Long.class).getSingleResult(); // Order 영향 X
    long u3 = stats.getEntityUpdateCount();
    assertEquals(0L, u3 - u2);   // flush 안 됨

    em.flush(); // 여기서야 반영
    long u4 = stats.getEntityUpdateCount();
    assertEquals(1L, u4 - u3);
  }



  // 6) clear(detach all) 후에는 동일 PK라도 새 SELECT, 다른 인스턴스
  @Test
  @Transactional
  void t6_clear_effect() {
    Order o1 = em.find(Order.class, 1L);           // SELECT +1
    stats.clear();

    em.clear();                                    // 1차 캐시 비움
    Order o2 = em.find(Order.class, 1L);           // SELECT +1
    assertNotSame(o1, o2);
    assertThat(ps()).isEqualTo(1L);
  }

  // 7) 쓰기 지연(write-behind): persist 후 flush 전까지 INSERT 없음
  @Test
  void t7_write_behind_until_flush() throws Exception {
    em.clear(); stats.clear();

    Member m = em.getReference(Member.class, 1L);
    Order o = Order.initMember(m);
    o.setTotalAmount(new BigDecimal("10.00"));

    // 현재 매핑이 IDENTITY 인지 런타임에 판별
    boolean isIdentity =
        Order.class.getDeclaredField("id")
            .getAnnotation(jakarta.persistence.GeneratedValue.class)
            .strategy() == jakarta.persistence.GenerationType.IDENTITY;

    long before = stats.getEntityInsertCount();
    em.persist(o);
    long afterPersist = stats.getEntityInsertCount();

    if (isIdentity) {
      // IDENTITY: persist 시점에 이미 INSERT 1회
      assertEquals(1L, afterPersist - before);
    } else {
      // SEQUENCE: flush 전까지 0회
      assertEquals(0L, afterPersist - before);
    }

    em.flush();
    long afterFlush = stats.getEntityInsertCount();

    // flush 후 누적 INSERT 수는 두 전략 모두 1
    assertEquals(1L, afterFlush - before);
  }
}
