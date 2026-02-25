package com.example.order_api_tuning.order.presentation.experiment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PartitionWriteReqDto(
    @NotNull Long memberId,
    @NotNull @Min(0) Integer price,
    @NotBlank String createdAt
) {
}
