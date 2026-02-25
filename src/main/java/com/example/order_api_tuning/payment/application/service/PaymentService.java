package com.example.order_api_tuning.payment.application.service;

import com.example.order_api_tuning.common.exception.BusinessException;
import com.example.order_api_tuning.common.exception.ErrorCode;
import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.member.domain.repository.MemberRepository;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.repository.OrderRepository;
import com.example.order_api_tuning.payment.domain.entity.Payment;
import com.example.order_api_tuning.payment.domain.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PaymentService {

  private final PaymentRepository paymentRepository;
  private final OrderRepository orderRepository;
  private final MemberRepository memberRepository;

  public void pay(Long orderId, Long memberId) {
    Order order = orderRepository.findById(orderId)
        .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));
    Member member = memberRepository.findById(memberId)
        .orElseThrow(() -> new BusinessException(ErrorCode.MEMBER_NOT_FOUND));
    paymentRepository.save(Payment.from(order,member));
  }

  public void refund(Long paymentId) {
    Payment payment = paymentRepository.findById(paymentId)
        .orElseThrow(() -> new BusinessException(ErrorCode.PAYMENT_NOT_FOUND));
    payment.refund();
    paymentRepository.save(payment);
  }
}
