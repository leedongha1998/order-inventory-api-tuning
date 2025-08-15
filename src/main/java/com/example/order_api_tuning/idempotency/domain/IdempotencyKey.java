package com.example.order_api_tuning.idempotency.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.OffsetDateTime;

@Entity
@Table(name = "idempotency_key", uniqueConstraints = {@UniqueConstraint(name = "uk_idempotency_key", columnNames = "key")})
public class IdempotencyKey {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "key", nullable = false, length = 64)
  private String key;

  @Lob
  @Column(name = "response_body")
  private String responseBody;

  @Column(name = "created_at", nullable = false)
  private OffsetDateTime createdAt;

  public enum Status{
    PENDING, COMPLETED, FAILED
  }
}
