package com.example.order_api_tuning.product.application.service;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.inventory.domain.repository.InventoryRepository;
import com.example.order_api_tuning.product.domain.repository.ProductRepository;
import com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto;
import com.example.order_api_tuning.product.presentation.dto.ProductSearchCondition;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProductService {

  private final ProductRepository productRepository;
  private final InventoryRepository inventoryRepository;

  @Transactional(readOnly = true)
  public Page<ProductInventoryDto> getAllProducts(Pageable pageable) {
//    Page<Product> page = productRepository.findAll(pageable);
    return inventoryRepository.findAllProducts(pageable);
  }

  @Transactional(readOnly = true)
  public Page<ProductInventoryDto> searchProducts(ProductSearchCondition condition, Pageable pageable) {
    return productRepository.searchProducts(condition,pageable);
  }
}
