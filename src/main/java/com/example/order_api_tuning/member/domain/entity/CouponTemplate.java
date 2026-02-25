package com.example.order_api_tuning.member.domain.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.math.BigDecimal;
import lombok.Getter;

@Entity
@Getter
public class CouponTemplate {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;
  private String name;
  private String description;
  @Enumerated(EnumType.STRING)
  private BenefitType type;
  private BigDecimal minAmount;
  private BigDecimal discountAmount;
}
