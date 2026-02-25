package com.example.order_api_tuning.inventory.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;

@Entity
@Table(name = "inventory_log", indexes = @Index(name = "idx_inventory_log_product_id_created_at", columnList = "product_id, created_at DESC"))
public class InventoryLog {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  // 상품 ID (FK는 스키마에 없으므로 Long 타입으로 매핑)
  @Column(name = "product_id", nullable = false)
  private Long productId;

  @Column(name = "change_qty", nullable = false)
  private Integer changeQty;

  @Column(name = "reason", length = 100, nullable = false)
  private String reason;

  @Column(name = "created_at", nullable = false, columnDefinition = "timestamptz")
  private OffsetDateTime createdAt;
}
