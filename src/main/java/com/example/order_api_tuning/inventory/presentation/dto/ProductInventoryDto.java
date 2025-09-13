package com.example.order_api_tuning.inventory.presentation.dto;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import java.math.BigDecimal;

public record ProductInventoryDto(
    Long productId,
    String productName,
    BigDecimal price,
    Integer quantity
) {

  public static ProductInventoryDto from(Inventory inventory) {
    return new ProductInventoryDto(inventory.getProductId(),inventory.getProduct().getName(),inventory.getProduct().getPrice(),inventory.getQuantity());
  }
}
