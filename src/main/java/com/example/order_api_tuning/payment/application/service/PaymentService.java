package com.example.order_api_tuning.payment.application.service;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.member.domain.repository.MemberRepository;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.repository.OrderRepository;
import com.example.order_api_tuning.payment.domain.entity.Payment;
import com.example.order_api_tuning.payment.domain.repository.PaymentRepository;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PaymentService {

  private final PaymentRepository paymentRepository;
  private final OrderRepository orderRepository;
  private final MemberRepository memberRepository;

  public void pay(Long orderId, Long memberId) {
    Order order = orderRepository.findById(orderId).orElseThrow();
    Member member = memberRepository.findById(memberId).orElseThrow();
    paymentRepository.save(Payment.from(order,member));
  }

  public void refund(Long paymentId) {
    Payment payment = paymentRepository.findById(paymentId).orElseThrow();
    payment.refund();
    paymentRepository.save(payment);
  }
}
