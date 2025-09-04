package com.example.order_api_tuning.order.presentation.dto;

import com.example.order_api_tuning.order.domain.entity.OrderStatus;
import java.math.BigDecimal;
import java.util.List;

public record OrderDetailDto(
    Long orderId,
    List<ItemDetail> items,
    OrderStatus orderStatus,
    BigDecimal totalAmount
) {
}
