package com.example.order_api_tuning.order.presentation.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * @deprecated 실험 API 전용 DTO는 {@code order.presentation.experiment.dto.PartitionWriteReqDto} 사용 권장.
 *
 /
public record PartitionTestDto(
    @NotNull Long memberId,
    @NotNull @Min(0) Integer price,
    @NotBlank String createdAt
) {
}
