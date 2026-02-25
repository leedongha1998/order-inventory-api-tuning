package com.example.order_api_tuning.inventory.presentation.dto;

import jakarta.validation.constraints.NotNull;

public record InventoryReqDto(
    @NotNull Integer quantity
) {

}
