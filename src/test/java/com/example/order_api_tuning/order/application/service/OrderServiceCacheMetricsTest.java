package com.example.order_api_tuning.order.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.order_api_tuning.idempotency.infrastructure.IdempotencyKeyJpaRepository;
import com.example.order_api_tuning.inventory.domain.repository.InventoryRepository;
import com.example.order_api_tuning.member.domain.repository.CouponRepository;
import com.example.order_api_tuning.member.domain.repository.MemberRepository;
import com.example.order_api_tuning.order.domain.repository.OrderRepository;
import com.example.order_api_tuning.order.domain.repository.OrderWriteRepo;
import com.example.order_api_tuning.order.presentation.experiment.dto.OrderSummaryDto;
import com.example.order_api_tuning.order.presentation.mapper.OrderDetailMapper;
import com.example.order_api_tuning.payment.domain.repository.PaymentRepository;
import com.example.order_api_tuning.product.domain.repository.ProductRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.OffsetDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.test.util.ReflectionTestUtils;

class OrderServiceCacheMetricsTest {

  private final OrderRepository orderRepository = mock(OrderRepository.class);
  private final MemberRepository memberRepository = mock(MemberRepository.class);
  private final ProductRepository productRepository = mock(ProductRepository.class);
  private final InventoryRepository inventoryRepository = mock(InventoryRepository.class);
  private final OrderDetailMapper orderDetailMapper = mock(OrderDetailMapper.class);
  private final PaymentRepository paymentRepository = mock(PaymentRepository.class);
  private final CouponRepository couponRepository = mock(CouponRepository.class);
  private final OrderWriteRepo orderWriteRepo = mock(OrderWriteRepo.class);
  private final IdempotencyKeyJpaRepository idempotencyKeyJpaRepository = mock(IdempotencyKeyJpaRepository.class);
  private final StringRedisTemplate stringRedisTemplate = mock(StringRedisTemplate.class);
  private final ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
  private final MeterRegistry meterRegistry = mock(MeterRegistry.class);
  private final Counter counter = mock(Counter.class);

  private OrderService orderService;

  @BeforeEach
  void setUp() {
    when(stringRedisTemplate.opsForValue()).thenReturn(valueOperations);
    when(meterRegistry.counter(any(String.class), any(String.class), any(String.class))).thenReturn(counter);

    orderService = new OrderService(
        orderRepository,
        memberRepository,
        productRepository,
        inventoryRepository,
        orderDetailMapper,
        paymentRepository,
        couponRepository,
        orderWriteRepo,
        idempotencyKeyJpaRepository,
        stringRedisTemplate,
        new ObjectMapper(),
        meterRegistry
    );
    ReflectionTestUtils.setField(orderService, "defaultSummaryCacheTtlSeconds", 30L);
  }

  @Test
  void cacheMiss_shouldIncrementMissMetric() {
    Long memberId = 1L;
    var pageable = PageRequest.of(0, 20);
    var data = new OrderSummaryDto(10L, null, null, OffsetDateTime.now());
    Page<OrderSummaryDto> page = new PageImpl<>(List.of(data), pageable, 1);

    when(valueOperations.get(any())).thenReturn(null);
    when(orderRepository.findOrderSummariesByMemberId(memberId, pageable)).thenReturn(page);

    OrderService.SummaryPageCacheResult result = orderService.getMyOrderSummariesWithCache(memberId,
        pageable, 10L);

    assertThat(result.cacheHit()).isFalse();
    assertThat(result.page().getTotalElements()).isEqualTo(1);
    verify(meterRegistry).counter("order.summary.cache.result", "result", "miss");
    verify(counter).increment();
  }

  @Test
  void redisReadFailure_shouldFallbackAndIncrementMetric() {
    Long memberId = 2L;
    var pageable = PageRequest.of(0, 20);
    Page<OrderSummaryDto> emptyPage = Page.empty(pageable);

    when(valueOperations.get(any())).thenThrow(new RedisConnectionFailureException("redis down"));
    when(orderRepository.findOrderSummariesByMemberId(memberId, pageable)).thenReturn(emptyPage);

    OrderService.SummaryPageCacheResult result = orderService.getMyOrderSummariesWithCache(memberId,
        pageable, null);

    assertThat(result.cacheHit()).isFalse();
    verify(meterRegistry).counter("order.summary.cache.result", "result", "fallback_read_error");
    verify(meterRegistry).counter("order.summary.cache.result", "result", "miss");
  }
}
