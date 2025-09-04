package com.example.order_api_tuning.payment.infrastructure;

import com.example.order_api_tuning.payment.domain.entity.Payment;
import com.example.order_api_tuning.payment.domain.repository.PaymentRepository;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class PaymentRepositoryImpl implements PaymentRepository {

  private final JpaPaymentRepository jpaPaymentRepository;

  @Override
  public void save(Payment payment) {
    jpaPaymentRepository.save(payment);
  }

  @Override
  public Optional<Payment> findById(Long paymentId) {
    return jpaPaymentRepository.findById(paymentId);
  }
}
