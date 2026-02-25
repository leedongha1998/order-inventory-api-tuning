package com.example.order_api_tuning.product.presentation.dto;

import java.math.BigDecimal;

public record ProductSearchCondition(
    String keyword,
    BigDecimal minPrice,
    BigDecimal maxPrice
) {

}
