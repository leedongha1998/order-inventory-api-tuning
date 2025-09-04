package com.example.order_api_tuning.inventory.infrastructure;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JpaInventoryRepository extends JpaRepository<Inventory, Long> {

  Optional<Inventory> findByProductId(Long productId);
}
