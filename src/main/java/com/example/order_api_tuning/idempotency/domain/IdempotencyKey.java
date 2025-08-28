package com.example.order_api_tuning.idempotency.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.OffsetDateTime;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "idempotency_key", uniqueConstraints = {@UniqueConstraint(name = "uk_idempotency_key", columnNames = "key")})
public class IdempotencyKey {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "key", nullable = false, length = 64)
  private String key;

  @JdbcTypeCode(SqlTypes.LONGNVARCHAR)
  @Column(name = "response_body", columnDefinition = "text")
  private String responseBody;

  @Column(name = "created_at", nullable = false)
  private OffsetDateTime createdAt;

  public enum Status{
    PENDING, COMPLETED, FAILED
  }
}
