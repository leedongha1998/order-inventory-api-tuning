package com.example.order_api_tuning.order.infrastructure;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.repository.OrderRepository;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class OrderRepositoryImpl implements OrderRepository {

  private final JpaOrderRepository jpaOrderRepository;

  @Override
  public void save(Order order) {
    jpaOrderRepository.save(order);
  }

  @Override
  public Optional<Order> findById(Long orderId) {
    return jpaOrderRepository.findById(orderId);
  }

  @Override
  public Page<Order> findAllByMemberId(Member member, Pageable pageable) {
    return jpaOrderRepository.findAllByMember(member,pageable);
  }

  @Override
  public Optional<Order> findByIdFetchJoin(Long orderId) {
    return jpaOrderRepository.findByIdFetchJoin(orderId);
  }

  @Override
  public Page<Long> findOrderIdsByMemberId(Long memberId, Pageable pageable) {
    return jpaOrderRepository.findOrderIdsByMemberId(memberId, pageable);
  }

  @Override
  public List<Order> findWithItemsByIdIn(List<Long> ids) {
    return jpaOrderRepository.findWithItemsByIdIn(ids);
  }

  @Override
  public Page<Order> findMyOrdersWithEntityGraph(Long memberId, Pageable pageable) {
    return jpaOrderRepository.findMyOrdersWithEntityGraph(memberId,pageable);
  }
}
