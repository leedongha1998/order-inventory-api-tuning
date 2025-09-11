package com.example.order_api_tuning.order.application.service;

import static java.util.stream.Collectors.toMap;

import com.example.order_api_tuning.common.exception.BusinessException;
import com.example.order_api_tuning.common.exception.ErrorCode;
import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.inventory.domain.repository.InventoryRepository;
import com.example.order_api_tuning.member.domain.entity.BenefitType;
import com.example.order_api_tuning.member.domain.entity.Coupon;
import com.example.order_api_tuning.member.domain.entity.CouponStatus;
import com.example.order_api_tuning.member.domain.entity.CouponTemplate;
import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.member.domain.repository.CouponRepository;
import com.example.order_api_tuning.member.domain.repository.MemberRepository;
import com.example.order_api_tuning.order.presentation.dto.OrderDetailDto;
import com.example.order_api_tuning.order.presentation.dto.OrderReqDto;
import com.example.order_api_tuning.order.presentation.dto.OrderReqDto.ItemSpec;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.entity.OrderItem;
import com.example.order_api_tuning.order.domain.repository.OrderRepository;
import com.example.order_api_tuning.order.presentation.mapper.OrderDetailMapper;
import com.example.order_api_tuning.payment.domain.entity.Payment;
import com.example.order_api_tuning.payment.domain.repository.PaymentRepository;
import com.example.order_api_tuning.product.domain.entity.Product;
import com.example.order_api_tuning.product.domain.repository.ProductRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OrderService {

  private final OrderRepository orderRepository;
  private final MemberRepository memberRepository;
  private final ProductRepository productRepository;
  private final InventoryRepository inventoryRepository;
  private final OrderDetailMapper orderDetailMapper;
  private final PaymentRepository paymentRepository;
  private final CouponRepository couponRepository;

  @Transactional
  public void createOrder(OrderReqDto request) {
    Member member = memberRepository.findById(request.memberId()).orElseThrow();

    // 상품 번호로 상품 조회하여 맵으로
    List<Long> productIds = request.items().stream().map(ItemSpec::productId).toList();
    Map<Long, Product> products = productRepository.findAllById(productIds).stream()
        .collect(toMap(Product::getId, Function.identity()));

    // 쿠폰 번호 조회해서 맵으로
    List<Long> couponIds = request.items().stream().map(ItemSpec::couponId).filter(Objects::nonNull)
        .toList();
    Map<Long,Coupon> coupons = couponIds.isEmpty() ? Map.of() : couponRepository.findAllById(couponIds).stream().collect(toMap(Coupon::getId, Function.identity()));

    Map<Long, Inventory> inventories = inventoryRepository.findAllByProductIdInForUpdate(productIds)
        .stream().collect(toMap(Inventory::getProductId, Function.identity()));

    for (ItemSpec item : request.items()) {
      Inventory inventory = inventories.get(item.productId());
      if(inventory.getQuantity() <= 0)
        throw new BusinessException(ErrorCode.NOT_ENOUGH_QUANTITY);
      inventory.updateQuantity(item.quantity());
    }

    // todo 재고 잠금 후 차감 처리

    Order order = Order.initMember(member);
    BigDecimal total = BigDecimal.ZERO;

    for (ItemSpec s : request.items()) {
      Product p = products.get(s.productId());
      OrderItem oi = OrderItem.create(p, s.quantity());
      order.addItem(oi);

      BigDecimal lineTotal = oi.getUnitPrice().multiply(BigDecimal.valueOf(s.quantity()));
      BigDecimal linePayable = lineTotal;

      Long cid = s.couponId();
      if (cid != null) {
        Coupon c = coupons.get(cid);
        validateOwnershipAndUsable(c, member, lineTotal); // 상태·만료·최소금액
        linePayable = applyDiscount(lineTotal, c.getTemplate());
        c.useCoupon();
      }
      total = total.add(linePayable);
    }

    order.setTotalAmount(total);
    orderRepository.save(order);

    paymentRepository.save(Payment.from(order, member));
    order.completeOrder();
  }

  private BigDecimal applyDiscount(BigDecimal lineTotal, CouponTemplate template) {
    if(template.getType().equals(BenefitType.PCT)){
        BigDecimal discount = lineTotal.multiply(template.getDiscountAmount());
        return lineTotal.subtract(discount).setScale(0, RoundingMode.DOWN);
    }

    return lineTotal.subtract(template.getDiscountAmount());
  }

  private void validateOwnershipAndUsable(Coupon coupon, Member member, BigDecimal lineTotal) {
    if(!coupon.getMember().equals(member) || coupon.getExpiryDate().isBefore(LocalDate.now()) || lineTotal.compareTo(BigDecimal.ZERO) < 0)
      throw new BusinessException(ErrorCode.COUPON_ERROR);
  }

  @Transactional(readOnly = true)
  public OrderDetailDto getOrder(Long orderId) {
//    Order order = orderRepository.findById(orderId).orElseThrow();
    Order order = orderRepository.findByIdFetchJoin(orderId).orElseThrow();
    return orderDetailMapper.toDto(order);
  }

  @Transactional
  public void cancelOrder(Long orderId) {
    Order order = orderRepository.findById(orderId).orElseThrow();
    order.cancelOrder();
    orderRepository.save(order);
  }

  @Transactional(readOnly = true)
  public Page<OrderDetailDto> getMyOrders(Long memberId, Pageable pageable) {
    Member member = memberRepository.findById(memberId).orElseThrow();
    Page<Order> page = orderRepository.findAllByMemberId(member, pageable);
    return page.map(orderDetailMapper::toDto);
  }

  @Transactional(readOnly = true)
  public Page<OrderDetailDto> getMyOrdersWithFetchJoin(Long memberId, Pageable pageable) {
    Page<Long> idPage = orderRepository.findOrderIdsByMemberId(memberId, pageable);
    if (idPage.isEmpty()) return Page.empty(pageable);

    List<Long> ids = idPage.getContent();
    List<Order> orders = orderRepository.findWithItemsByIdIn(ids);

    // ID 순서 유지
    Map<Long, Integer> orderIndex = new HashMap<>();
    for (int i = 0; i < ids.size(); i++) orderIndex.put(ids.get(i), i);
    orders.sort(Comparator.comparingInt(o -> orderIndex.getOrDefault(o.getId(), Integer.MAX_VALUE)));

    List<OrderDetailDto> dtos = orders.stream()
        .map(orderDetailMapper::toDto)
        .toList();

    return new PageImpl<>(dtos, pageable, idPage.getTotalElements());
  }

  @Transactional(readOnly = true)
  public Page<OrderDetailDto> getMyOrdersWithEntityGraph(Long memberId, Pageable pageable){
    Page<Order> page = orderRepository.findMyOrdersWithEntityGraph(memberId,pageable);

    if (page.isEmpty()) return Page.empty(pageable);

    List<OrderDetailDto> dtos = page.getContent().stream()
        // 여기서 order.getItems() 접근해도 추가 쿼리 없음(이미 적재/배치)
        .map(orderDetailMapper::toDto)
        .toList();

    return new PageImpl<>(dtos, pageable, page.getTotalElements());
  }
}
