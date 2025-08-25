package com.example.order_api_tuning.common.exception;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ErrorResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

  private final ApiMetaFactory apiMetaFactory;

  @ExceptionHandler(BusinessException.class)
  public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException e) {
    ErrorCode errorCode = e.getErrorCode();
    ErrorResponse body = ErrorResponse.of(errorCode, errorCode.getMessage(),null,apiMetaFactory.meta(null,null));
    return ResponseEntity.status(errorCode.getStatus()).body(body);
  }
}
