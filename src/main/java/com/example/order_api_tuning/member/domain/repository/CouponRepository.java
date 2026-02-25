package com.example.order_api_tuning.member.domain.repository;

import com.example.order_api_tuning.member.domain.entity.Coupon;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface CouponRepository {

  Optional<Coupon> findById(Long id);

  List<Coupon> findAllById(List<Long> couponIds);
}
