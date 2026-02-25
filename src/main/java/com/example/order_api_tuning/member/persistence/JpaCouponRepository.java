package com.example.order_api_tuning.member.persistence;

import com.example.order_api_tuning.member.domain.entity.Coupon;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JpaCouponRepository extends JpaRepository<Coupon, Long> {

}
