package com.example.order_api_tuning.inventory.domain;

import com.example.order_api_tuning.product.domain.Product;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.OffsetDateTime;

@Entity
@Table(uniqueConstraints = @UniqueConstraint(name = "uq_inventory_product_id", columnNames = "product_id"))
public class Inventory {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  // 각 상품당 재고 1행 보장
  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "product_id", nullable = false,
      foreignKey = @ForeignKey(name = "inventory_product_id_fkey"))
  private Product product;

  @Column(name = "quantity", nullable = false)
  private Integer quantity;

  @Column(name = "updated_at", nullable = false, columnDefinition = "timestamptz")
  private OffsetDateTime updatedAt;
}
