package com.example.order_api_tuning.order.presentation.dto;

import java.util.List;

public record OrderReqDto(
    Long memberId,
    List<ItemSpec> items
) {

  public record ItemSpec(
      Long productId,
      Integer quantity
  ) {

  }
}
