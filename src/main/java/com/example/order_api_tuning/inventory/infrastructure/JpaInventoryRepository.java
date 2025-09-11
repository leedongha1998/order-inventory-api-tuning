package com.example.order_api_tuning.inventory.infrastructure;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.product.domain.entity.Product;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface JpaInventoryRepository extends JpaRepository<Inventory, Long> {

  @Query("select i from Inventory i where i.product.id = :productId")
  Optional<Inventory> findByProductId(Long productId);

  @Query("select i from Inventory i where i.product.id in :productIds")
  List<Inventory> findAllByProductIds(List<Long> productIds);
}
