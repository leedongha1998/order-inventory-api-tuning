package com.example.order_api_tuning.inventory.infrastructure;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.inventory.domain.repository.InventoryRepository;
import com.example.order_api_tuning.product.domain.entity.Product;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class InventoryRepositoryImpl implements InventoryRepository {

  private final JpaInventoryRepository jpaInventoryRepository;

  @Override
  public Optional<Inventory> findByProductId(Long productId) {
    return jpaInventoryRepository.findByProductId(productId);
  }

  @Override
  public List<Inventory> findAllByProductIdInForUpdate(List<Long> productIds) {
    return jpaInventoryRepository.findAllByProductIds(productIds);
  }

  @Override
  public void save(Inventory inventory) {
    jpaInventoryRepository.save(inventory);
  }
}
