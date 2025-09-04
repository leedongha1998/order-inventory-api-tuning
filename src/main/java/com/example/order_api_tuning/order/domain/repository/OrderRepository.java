package com.example.order_api_tuning.order.domain.repository;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.order.domain.entity.Order;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface OrderRepository {

  void save(Order order);

  Optional<Order> findById(Long orderId);

  Page<Order> findAllByMemberId(Member member, Pageable pageable);
}
