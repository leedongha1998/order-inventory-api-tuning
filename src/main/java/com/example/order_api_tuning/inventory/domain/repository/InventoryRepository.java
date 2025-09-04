package com.example.order_api_tuning.inventory.domain.repository;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import java.util.Optional;

public interface InventoryRepository{
  Optional<Inventory> findByProductId(Long productId);

  void save(Inventory inventory);
}
