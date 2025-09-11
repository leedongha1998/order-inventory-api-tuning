package com.example.order_api_tuning.inventory.domain.entity;

import com.example.order_api_tuning.inventory.presentation.dto.InventoryReqDto;
import com.example.order_api_tuning.product.domain.entity.Product;
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
import lombok.Getter;

@Entity
@Table(uniqueConstraints = @UniqueConstraint(name = "uq_inventory_product_id", columnNames = "product_id"))
@Getter
public class Inventory {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "product_id", nullable = false,
      foreignKey = @ForeignKey(name = "inventory_product_id_fkey"))
  private Product product;

  @Column(name = "quantity", nullable = false)
  private Integer quantity;

  @Column(name = "updated_at", nullable = false, columnDefinition = "timestamptz")
  private OffsetDateTime updatedAt;

  public void updateQuantity(Integer quantity) {
    this.quantity -= quantity;
  }

  public Long getProductId(){
    return product != null ? product.getId() : null;
  }
}
