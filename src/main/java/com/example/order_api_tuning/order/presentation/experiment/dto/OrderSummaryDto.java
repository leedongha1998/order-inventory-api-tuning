package com.example.order_api_tuning.order.presentation.experiment.dto;

import com.example.order_api_tuning.order.domain.entity.OrderStatus;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record OrderSummaryDto(
    Long orderId,
    OrderStatus orderStatus,
    BigDecimal totalAmount,
    OffsetDateTime createdAt
) {
}
