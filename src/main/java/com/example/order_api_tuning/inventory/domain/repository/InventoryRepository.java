package com.example.order_api_tuning.inventory.domain.repository;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface InventoryRepository{
  Optional<Inventory> findByProductId(Long productId);

  void save(Inventory inventory);

  List<Inventory> findAllByProductIdInForUpdate(List<Long> productIds);

  Page<ProductInventoryDto> findAllProducts(Pageable pageable);
}
