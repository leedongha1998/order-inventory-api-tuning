package com.example.order_api_tuning.inventory.presentation.dto;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record InventoryResDto(
    Long productId,
    String productName,
    BigDecimal productPrice,
    String productStatus,
    Integer quantity,
    OffsetDateTime updatedAt
) {

  public static InventoryResDto from(Inventory inventory) {
    return new InventoryResDto(inventory.getProduct().getId(), inventory.getProduct().getName(),
        inventory.getProduct().getPrice(), inventory.getProduct().getStatus().toString(),
        inventory.getQuantity(), inventory.getUpdatedAt());
  }
}
