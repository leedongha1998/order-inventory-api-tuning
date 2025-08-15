package com.example.order_api_tuning.product.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "product", indexes = {
    @Index(name = "idx_product_status", columnList = "status"),
    @Index(name = "idx_product_name", columnList = "name")
})
public class Product {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(length = 200, nullable = false)
  private String name;

  @Column(precision = 12, scale = 2, nullable = false)
  private BigDecimal price;

  @Enumerated(EnumType.STRING)
  private ProductStatus status;

  @Column(name = "created_at", nullable = false)
  private OffsetDateTime createdAt;
}
