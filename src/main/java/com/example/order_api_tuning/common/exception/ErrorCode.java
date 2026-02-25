package com.example.order_api_tuning.common.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.http.HttpStatus;
@Getter
@AllArgsConstructor
public enum ErrorCode {
  BAD_REQUEST(HttpStatus.BAD_REQUEST, "잘못된 요청입니다."),
  VALIDATION_ERROR(HttpStatus.BAD_REQUEST, "요청 값이 올바르지 않습니다."),
  ORDER_NOT_FOUND(HttpStatus.NOT_FOUND, "주문이 존재하지 않습니다."),
  INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "서버 오류가 발생했습니다."),
  NOT_EXIST_PRODUCT(HttpStatus.NOT_FOUND,"해당 제품이 없습니다." ),
  COUPON_ERROR(HttpStatus.BAD_REQUEST,"쿠폰을 사용할 수 없습니다."), NOT_ENOUGH_QUANTITY(HttpStatus.BAD_REQUEST, "재고가 없습니다.");

  private final HttpStatus status;
  private final String message;
}
