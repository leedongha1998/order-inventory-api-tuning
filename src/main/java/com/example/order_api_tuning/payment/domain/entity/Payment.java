package com.example.order_api_tuning.payment.domain.entity;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.payment.application.service.PaymentService;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "payments")
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Payment {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Enumerated(EnumType.STRING)
  private PaymentStatus status;

  @ManyToOne(fetch = FetchType.LAZY)
  private Member member;

  @OneToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "order_id")
  private Order order;

  @Column(name = "created_at", columnDefinition = "timestamptz", nullable = false)
  private OffsetDateTime createdAt;

  @Column(name = "updated_at", columnDefinition = "timestamptz", nullable = false)
  private OffsetDateTime updatedAt;

  private Payment(PaymentStatus status, Member member, Order order, OffsetDateTime createdAt,
      OffsetDateTime updatedAt) {
    this.status = status;
    this.member = member;
    this.order = order;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  public static Payment from(Order order, Member member) {
    return new Payment(PaymentStatus.PENDING,member,order,OffsetDateTime.now(),OffsetDateTime.now());
  }

  public void refund() {
    this.status = PaymentStatus.CANCELLED;
  }
}
