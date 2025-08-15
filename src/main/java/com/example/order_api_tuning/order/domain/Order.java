package com.example.order_api_tuning.order.domain;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders", indexes = @Index(name = "idx_orders_status_created_at", columnList = "status, created_at DESC"))
public class Order {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id", nullable = false)
  private Long userId;

  @Enumerated(EnumType.STRING) @Column(length=20, nullable=false)
  private OrderStatus status;

  @Column(name="total_amount", precision=12, scale=2, nullable=false)
  private BigDecimal totalAmount;

  @Column(name="created_at", columnDefinition="timestamptz", nullable=false)
  private OffsetDateTime createdAt;

  @Column(name="updated_at", columnDefinition="timestamptz", nullable=false)
  private OffsetDateTime updatedAt;

  @OneToMany(mappedBy="order", cascade= CascadeType.ALL, orphanRemoval=true)
  private List<OrderItem> items = new ArrayList<>();
}
