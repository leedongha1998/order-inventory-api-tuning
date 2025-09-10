package com.example.order_api_tuning.inventory.domain.repository;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.product.domain.entity.Product;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface InventoryRepository{
  Optional<Inventory> findByProductId(Long productId);

  void save(Inventory inventory);

  List<Inventory> findAllByProductIdInForUpdate(List<Long> productIds);
}
