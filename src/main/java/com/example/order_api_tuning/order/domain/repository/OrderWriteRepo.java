package com.example.order_api_tuning.order.domain.repository;

import jakarta.persistence.EntityManager;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
@RequiredArgsConstructor
public class OrderWriteRepo {
  private final EntityManager em;

  @Transactional
  public void insertNp(long m, BigDecimal t, LocalDateTime createdAt) {
    em.createNativeQuery("""
      insert into bench.orders_np(member_id, status, created_at, total)
      values (?1, 'PAID', ?2, ?3)
    """).setParameter(1, m)
        .setParameter(2, createdAt)
        .setParameter(3, t)
        .executeUpdate();
  }

  @Transactional
  public void insertPt(long m, BigDecimal t, LocalDateTime createdAt) {
    em.createNativeQuery("""
      insert into bench.orders_pt(member_id, status, created_at, total)
      values (?1, 'PAID', ?2, ?3)
    """).setParameter(1, m)
        .setParameter(2, createdAt)
        .setParameter(3, t)
        .executeUpdate();
  }
}

