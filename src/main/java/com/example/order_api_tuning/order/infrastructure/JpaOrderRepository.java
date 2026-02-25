package com.example.order_api_tuning.order.infrastructure;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.presentation.experiment.dto.OrderSummaryDto;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface JpaOrderRepository extends JpaRepository<Order, Long> {

  Page<Order> findAllByMember(Member member, Pageable pageable);

  @Query("""
        select distinct o
        from Order o
        left join fetch o.items oi
        left join fetch oi.product p
        where o.id = :orderId
      """)
  Optional<Order> findByIdFetchJoin(Long orderId);

  @Query(value = """
      select o.id
      from Order o
      where o.member.id = :memberId
      order by o.createdAt desc
      """,
      countQuery = "select count(o) from Order o where o.member.id = :memberId")
  Page<Long> findOrderIdsByMemberId(Long memberId, Pageable pageable);

  @Query("""
      select distinct o
      from Order o
      join fetch o.member m
      left join fetch o.items i
      left join fetch i.product p
      where o.id in :ids
      """)
  List<Order> findWithItemsByIdIn(List<Long> ids);

  @EntityGraph(value = "Order.withMemberAndItems", type = EntityGraph.EntityGraphType.LOAD)
  @Query(value = """
      select o
      from Order o
      where o.member.id = :memberId
      order by o.createdAt desc
      """,
      countQuery = """
      select count(o)
      from Order o
      where o.member.id = :memberId
      """)
  Page<Order> findMyOrdersWithEntityGraph(Long memberId, Pageable pageable);

  @EntityGraph(value = "Order.withMemberAndItems", type = EntityGraph.EntityGraphType.LOAD)
  @Query("""
      select o
      from Order o
      where o.member.id = :memberId
        and (
          :cursorCreatedAt is null
          or o.createdAt < :cursorCreatedAt
          or (o.createdAt = :cursorCreatedAt and o.id < :cursorId)
        )
      order by o.createdAt desc, o.id desc
      """)
  List<Order> findMyOrdersWithEntityGraphByCursor(Long memberId, OffsetDateTime cursorCreatedAt,
      Long cursorId, Pageable pageable);

  @Query(value = """
      select new com.example.order_api_tuning.order.presentation.experiment.dto.OrderSummaryDto(
        o.id, o.status, o.totalAmount, o.createdAt
      )
      from Order o
      where o.member.id = :memberId
      order by o.createdAt desc
      """,
      countQuery = """
      select count(o)
      from Order o
      where o.member.id = :memberId
      """)
  Page<OrderSummaryDto> findOrderSummariesByMemberId(Long memberId, Pageable pageable);
}
