package com.example.order_api_tuning.product.domain.repository;

import com.example.order_api_tuning.product.domain.entity.Product;
import com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto;
import com.example.order_api_tuning.product.presentation.dto.ProductSearchCondition;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ProductRepository {

  Optional<Product> findById(Long aLong);

  List<Product> findAllById(List<Long> list);

  Page<Product> findAll(Pageable pageable);

  Page<ProductInventoryDto> searchProducts(ProductSearchCondition condition, Pageable pageable);
}
