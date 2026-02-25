package com.example.order_api_tuning.order.presentation.experiment.dto;

import com.example.order_api_tuning.order.presentation.dto.OrderDetailDto;
import java.time.OffsetDateTime;
import java.util.List;

public record OrderCursorPageDto(
    List<OrderDetailDto> orders,
    OffsetDateTime nextCursorCreatedAt,
    Long nextCursorId,
    boolean hasNext
) {
}
