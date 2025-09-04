package com.example.order_api_tuning.order.application.service;

import static java.util.stream.Collectors.toMap;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.member.domain.repository.MemberRepository;
import com.example.order_api_tuning.order.presentation.dto.OrderDetailDto;
import com.example.order_api_tuning.order.presentation.dto.OrderReqDto;
import com.example.order_api_tuning.order.presentation.dto.OrderReqDto.ItemSpec;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.entity.OrderItem;
import com.example.order_api_tuning.order.domain.repository.OrderRepository;
import com.example.order_api_tuning.order.presentation.mapper.OrderDetailMapper;
import com.example.order_api_tuning.product.domain.entity.Product;
import com.example.order_api_tuning.product.domain.repository.ProductRepository;
import java.math.BigDecimal;
import java.util.Map;
import java.util.function.Function;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OrderService {

  private final OrderRepository orderRepository;
  private final MemberRepository memberRepository;
  private final ProductRepository productRepository;
  private final OrderDetailMapper orderDetailMapper;

  @Transactional
  public void createOrder(OrderReqDto request) {
    Member member = memberRepository.findById(request.memberId()).orElseThrow();

    Order order = Order.initMember(member);

    BigDecimal total = BigDecimal.ZERO;

    Map<Long, Product> productMap = productRepository.findAllById(
        request.items().stream().map(ItemSpec::productId).toList()
    ).stream().collect(toMap(Product::getId, Function.identity()));

    for (ItemSpec s : request.items()) {
      Product p = productMap.get(s.productId());
      OrderItem oi = OrderItem.create(p, s.quantity());
      order.addItem(oi);
      BigDecimal lineTotal = oi.getUnitPrice().multiply(BigDecimal.valueOf(s.quantity()));
      total = total.add(lineTotal);
    }

    order.setTotalAmount(total);

    orderRepository.save(order);
  }

  @Transactional(readOnly = true)
  public OrderDetailDto getOrder(Long orderId) {
    Order order = orderRepository.findById(orderId).orElseThrow();
    return orderDetailMapper.toDto(order);
  }

  @Transactional
  public void cancelOrder(Long orderId) {
    Order order = orderRepository.findById(orderId).orElseThrow();
    order.cancelOrder();
    orderRepository.save(order);
  }

  public Page<OrderDetailDto> getMyOrders(Long memberId, Pageable pageable) {
    Member member = memberRepository.findById(memberId).orElseThrow();
    Page<Order> page = orderRepository.findAllByMemberId(member, pageable);
    return page.map(orderDetailMapper::toDto);
  }
}
