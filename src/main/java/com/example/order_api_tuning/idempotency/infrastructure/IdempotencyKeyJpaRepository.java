package com.example.order_api_tuning.idempotency.infrastructure;

import com.example.order_api_tuning.idempotency.domain.IdempotencyKey;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IdempotencyKeyJpaRepository extends JpaRepository<IdempotencyKey, Long> {

  boolean existsByKey(String key);
}
