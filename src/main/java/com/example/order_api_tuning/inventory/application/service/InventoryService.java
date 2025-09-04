package com.example.order_api_tuning.inventory.application.service;

import com.example.order_api_tuning.inventory.presentation.dto.InventoryReqDto;
import com.example.order_api_tuning.inventory.presentation.dto.InventoryResDto;
import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.inventory.domain.repository.InventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class InventoryService {

  private final InventoryRepository inventoryRepository;

  @Transactional(readOnly = true)
  public InventoryResDto getInventoryByProductId(Long productId) {
    Inventory inventory = inventoryRepository.findByProductId(productId).orElseThrow();
    return InventoryResDto.from(inventory);
  }

  @Transactional
  public void updateInventory(Long productId, InventoryReqDto request) {
    Inventory inventory = inventoryRepository.findByProductId(productId).orElseThrow();
    inventory.updateQuantity(request);
    inventoryRepository.save(inventory);
  }
}
