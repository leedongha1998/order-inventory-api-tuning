package com.example.order_api_tuning.order.presentation.dto;

import java.math.BigDecimal;

public record ItemDetail(
    Long productId,
    String productName,
    Integer quantity,
    BigDecimal unitPrice
) {
}
