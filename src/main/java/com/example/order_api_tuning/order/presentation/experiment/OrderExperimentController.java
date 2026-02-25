package com.example.order_api_tuning.order.presentation.experiment;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ApiResponse;
import com.example.order_api_tuning.order.application.service.OrderService;
import com.example.order_api_tuning.order.presentation.experiment.dto.OrderCursorPageDto;
import com.example.order_api_tuning.order.presentation.experiment.dto.OrderSummaryDto;
import com.example.order_api_tuning.order.presentation.experiment.dto.PartitionWriteReqDto;
import jakarta.validation.Valid;
import java.time.OffsetDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/experiments/orders")
public class OrderExperimentController {

  private final OrderService orderService;
  private final ApiMetaFactory metaFactory;

  @PostMapping("/partition/np")
  public ResponseEntity<ApiResponse<Void>> createOrderNotPartition(
      @RequestBody @Valid PartitionWriteReqDto dto) {
    orderService.createOrderNotPartition(dto);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(meta));
  }

  @PostMapping("/partition/pt")
  public ResponseEntity<ApiResponse<Void>> createOrderPartition(
      @RequestBody @Valid PartitionWriteReqDto dto) {
    orderService.createOrderPartition(dto);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(meta));
  }

  @GetMapping("/{memberId}/me/cursor")
  public ResponseEntity<ApiResponse<OrderCursorPageDto>> getMyOrdersByCursor(
      @PathVariable Long memberId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
      OffsetDateTime cursorCreatedAt,
      @RequestParam(required = false) Long cursorId,
      @RequestParam(defaultValue = "20") int size
  ) {
    OrderCursorPageDto result = orderService.getMyOrdersWithEntityGraphByCursor(memberId,
        cursorCreatedAt, cursorId, size);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(result, meta));
  }

  @GetMapping("/{memberId}/me/summary")
  public ResponseEntity<ApiResponse<List<OrderSummaryDto>>> getMyOrderSummaries(
      @PathVariable Long memberId,
      @PageableDefault(size = 20, sort = "createdAt", direction = Direction.DESC) Pageable pageable
  ) {
    Page<OrderSummaryDto> page = orderService.getMyOrderSummaries(memberId, pageable);
    ApiResponse.Meta meta = metaFactory.meta(pageable, page);
    return ResponseEntity.ok(ApiResponse.ok(page.getContent(), meta));
  }
}
