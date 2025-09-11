package com.example.order_api_tuning.member.persistence;

import com.example.order_api_tuning.member.domain.entity.Coupon;
import com.example.order_api_tuning.member.domain.repository.CouponRepository;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class CouponRepositoryImpl implements CouponRepository {

  private final JpaCouponRepository jpaCouponRepository;

  @Override
  public Optional<Coupon> findById(Long id) {
    return jpaCouponRepository.findById(id);
  }

  @Override
  public List<Coupon> findAllById(List<Long> couponIds) {
    return jpaCouponRepository.findAllById(couponIds);
  }
}
