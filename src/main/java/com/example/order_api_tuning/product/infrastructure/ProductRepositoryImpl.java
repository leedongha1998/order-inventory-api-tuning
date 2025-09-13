package com.example.order_api_tuning.product.infrastructure;

import static com.example.order_api_tuning.product.domain.entity.QProduct.product;

import com.example.order_api_tuning.product.domain.entity.Product;
import com.example.order_api_tuning.product.domain.entity.QProduct;
import com.example.order_api_tuning.product.domain.repository.ProductRepository;
import com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto;
import com.example.order_api_tuning.product.presentation.dto.ProductSearchCondition;
import com.querydsl.core.BooleanBuilder;
import com.querydsl.core.types.OrderSpecifier;
import com.querydsl.core.types.Projections;
import com.querydsl.jpa.impl.JPAQueryFactory;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class ProductRepositoryImpl implements ProductRepository {

  private final JpaProductRepository jpaProductRepository;
  private final JPAQueryFactory queryFactory;

  @Override
  public Optional<Product> findById(Long id) {
    return jpaProductRepository.findById(id);
  }

  @Override
  public List<Product> findAllById(List<Long> list) {
    return jpaProductRepository.findAllById(list);
  }

  @Override
  public Page<Product> findAll(Pageable pageable) {
    return jpaProductRepository.findAll(pageable);
  }

  @Override
  public Page<ProductInventoryDto> searchProducts(ProductSearchCondition c, Pageable pageable) {
    QProduct p = product;

    // 0) 경계값 정리: 가격 역전 스왑
    BigDecimal min = c.minPrice();
    BigDecimal max = c.maxPrice();
    if (min != null && max != null && min.compareTo(max) > 0) {
      BigDecimal tmp = min; min = max; max = tmp;
    }

    // 1) 동적 where
    BooleanBuilder where = new BooleanBuilder();
    if (hasText(c.keyword())) where.and(p.name.containsIgnoreCase(c.keyword()));
    if (min != null)          where.and(p.price.goe(min));
    if (max != null)          where.and(p.price.loe(max));

    // 2) 정렬 매핑(화이트리스트)
    OrderSpecifier<?>[] orders = toOrderSpecifiers(pageable.getSort(), p);

    // 3) content (필요한 컬럼만 DTO로)
    List<ProductInventoryDto> content = queryFactory
        .select(Projections.constructor(ProductInventoryDto.class,
            p.id, p.name, p.price))
        .from(p)
        .where(where)
        .orderBy(orders)
        .offset(pageable.getOffset())
        .limit(pageable.getPageSize())
        .fetch();

    // 4) count (가벼운 형태)
    Long total = queryFactory.select(p.count()).from(p).where(where).fetchOne();

    return new PageImpl<>(content, pageable, total == null ? 0 : total);
  }

  private boolean hasText(String s) { return s != null && !s.isBlank(); }

  /** Spring Sort → Querydsl OrderSpecifier (허용 필드만) */
  private OrderSpecifier<?>[] toOrderSpecifiers(Sort sort, QProduct p) {
    List<OrderSpecifier<?>> list = new ArrayList<>();
    for (Sort.Order o : sort) {
      com.querydsl.core.types.Order dir = o.isAscending()
          ? com.querydsl.core.types.Order.ASC : com.querydsl.core.types.Order.DESC;

      switch (o.getProperty()) {
        case "id"        -> list.add(new OrderSpecifier<>(dir, p.id));
        case "name"      -> list.add(new OrderSpecifier<>(dir, p.name));
        case "price"     -> list.add(new OrderSpecifier<>(dir, p.price));
        case "createdAt" -> list.add(new OrderSpecifier<>(dir, p.createdAt));
        default -> { /* 무시: 허용하지 않은 정렬 필드 */ }
      }
    }
    if (list.isEmpty()) { // 기본 정렬 보강 (동률 방지)
      list.add(new OrderSpecifier<>(com.querydsl.core.types.Order.DESC, p.createdAt));
      list.add(new OrderSpecifier<>(com.querydsl.core.types.Order.DESC, p.id));
    }
    return list.toArray(OrderSpecifier[]::new);
  }
}
