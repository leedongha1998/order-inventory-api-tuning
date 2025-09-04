package com.example.order_api_tuning.product.application.service;

import com.example.order_api_tuning.product.domain.entity.Product;
import com.example.order_api_tuning.product.domain.repository.ProductRepository;
import com.example.order_api_tuning.product.presentation.dto.ProductListDto;
import com.example.order_api_tuning.product.presentation.dto.ProductSearchCondition;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ProductService {

  private final ProductRepository productRepository;

  public Page<ProductListDto> getAllProducts(Pageable pageable) {
    Page<Product> page = productRepository.findAll(pageable);

    return page.map(ProductListDto::from);
  }

  public Page<ProductListDto> searchProducts(ProductSearchCondition condition, Pageable pageable) {
    return productRepository.searchProducts(condition,pageable);
  }
}
