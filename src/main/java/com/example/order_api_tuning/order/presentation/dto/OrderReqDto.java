package com.example.order_api_tuning.order.presentation.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record OrderReqDto(
    @NotNull Long memberId,
    @NotEmpty List<@Valid ItemSpec> items
) {

  public record ItemSpec(
      @NotNull Long productId,
      @NotNull @Min(1) Integer quantity,
      Long couponId
  ) {

  }
}
