package com.example.order_api_tuning.order.infrastructure;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.order.domain.entity.Order;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface JpaOrderRepository extends JpaRepository<Order,Long> {

  Page<Order> findAllByMember(Member member, Pageable pageable);

  @Query("""
  select distinct o
  from Order o
  left join fetch o.items oi
  left join fetch oi.product p
  where o.id = :orderId
""")
  Optional<Order> findByIdFetchJoin(Long orderId);
}
