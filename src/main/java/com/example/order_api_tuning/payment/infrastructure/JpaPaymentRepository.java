package com.example.order_api_tuning.payment.infrastructure;

import com.example.order_api_tuning.payment.domain.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JpaPaymentRepository extends JpaRepository<Payment, Long> {

}
