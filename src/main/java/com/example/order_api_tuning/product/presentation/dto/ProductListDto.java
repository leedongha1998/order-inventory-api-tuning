package com.example.order_api_tuning.product.presentation.dto;

import com.example.order_api_tuning.product.domain.entity.Product;
import java.math.BigDecimal;

public record ProductListDto(
    Long productId,
    String productName,
    BigDecimal unitPrice
) {

  public static ProductListDto from(Product product) {
    return new ProductListDto(product.getId(), product.getName(),product.getPrice());
  }
}
