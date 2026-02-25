package com.example.order_api_tuning.payment.domain.repository;

import com.example.order_api_tuning.payment.domain.entity.Payment;
import java.util.Optional;

public interface PaymentRepository {

  void save(Payment payment);

  Optional<Payment> findById(Long paymentId);
}
