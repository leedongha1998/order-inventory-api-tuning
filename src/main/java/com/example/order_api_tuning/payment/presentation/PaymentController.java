package com.example.order_api_tuning.payment.presentation;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ApiResponse;
import com.example.order_api_tuning.payment.application.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/payments")
public class PaymentController {

  private final PaymentService paymentService;
  private final ApiMetaFactory apiMetaFactory;

  @PostMapping("/{orderId}/member/{memberId}")
  public ResponseEntity<ApiResponse<Void>> pay(@PathVariable Long orderId, @PathVariable Long memberId) {
    paymentService.pay(orderId,memberId);
    return ResponseEntity.ok(ApiResponse.ok(apiMetaFactory.meta(null,null)));
  }

  @PatchMapping("/{paymentId}")
  public ResponseEntity<ApiResponse<Void>> pay(@PathVariable Long paymentId) {
    paymentService.refund(paymentId);
    return ResponseEntity.ok(ApiResponse.ok(apiMetaFactory.meta(null,null)));
  }
}
