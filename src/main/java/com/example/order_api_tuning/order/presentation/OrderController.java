package com.example.order_api_tuning.order.presentation;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ApiResponse;
import com.example.order_api_tuning.order.presentation.dto.OrderDetailDto;
import com.example.order_api_tuning.order.presentation.dto.OrderReqDto;
import com.example.order_api_tuning.order.application.service.OrderService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {
  private final OrderService orderService;
  private final ApiMetaFactory metaFactory;

  @PostMapping()
  public ResponseEntity<ApiResponse<Void>> createOrder(@RequestBody OrderReqDto request) {
    orderService.createOrder(request);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(meta));
  }

  @GetMapping("/{orderId}")
  public ResponseEntity<ApiResponse<OrderDetailDto>> getOrder(@PathVariable Long orderId){
    OrderDetailDto result = orderService.getOrder(orderId);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(result,meta));
  }

  @PatchMapping("/{orderId}")
  public ResponseEntity<ApiResponse<Void>> cancelOrder(@PathVariable Long orderId){
    orderService.cancelOrder(orderId);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(meta));
  }

  @GetMapping("/me/{memberId}")
  public ResponseEntity<ApiResponse<List<OrderDetailDto>>> getMyOrders(
      @PathVariable Long memberId,
      @PageableDefault(size = 10, sort = "createdAt", direction = Direction.DESC) Pageable pageable
  ) {
    Page<OrderDetailDto> page = orderService.getMyOrders(memberId, pageable);
    ApiResponse.Meta meta = metaFactory.meta(pageable, page);
    return ResponseEntity.ok(ApiResponse.ok(page.getContent(), meta));
  }
}
