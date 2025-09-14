package com.example.order_api_tuning.payment.infrastructure;

import com.example.order_api_tuning.payment.domain.entity.Payment;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface JpaPaymentRepository extends JpaRepository<Payment, Long> {

  @Query("select p from Payment p where p.order.id = :orderId")
  Optional<Payment> findByOrderId(Long orderId);
}
