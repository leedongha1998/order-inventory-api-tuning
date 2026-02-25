package com.example.order_api_tuning.common.exception;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ErrorResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

  private final ApiMetaFactory apiMetaFactory;

  @ExceptionHandler(BusinessException.class)
  public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException e) {
    ErrorCode errorCode = e.getErrorCode();
    ErrorResponse body = ErrorResponse.of(errorCode, errorCode.getMessage(), null, apiMetaFactory.meta(null,null));
    return ResponseEntity.status(errorCode.getStatus()).body(body);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorResponse> handleMethodArgumentNotValidException(MethodArgumentNotValidException e) {
    List<ErrorResponse.FieldError> errors = e.getBindingResult().getFieldErrors().stream()
        .map(this::toErrorField)
        .toList();

    ErrorResponse body = ErrorResponse.of(
        ErrorCode.VALIDATION_ERROR,
        ErrorCode.VALIDATION_ERROR.getMessage(),
        errors,
        apiMetaFactory.meta(null, null)
    );
    return ResponseEntity.status(ErrorCode.VALIDATION_ERROR.getStatus()).body(body);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorResponse> handleException(Exception e) {
    ErrorCode errorCode = ErrorCode.INTERNAL_ERROR;
    ErrorResponse body = ErrorResponse.of(errorCode, errorCode.getMessage(), null, apiMetaFactory.meta(null, null));
    return ResponseEntity.status(errorCode.getStatus()).body(body);
  }

  private ErrorResponse.FieldError toErrorField(FieldError fieldError) {
    return ErrorResponse.FieldError.builder()
        .field(fieldError.getField())
        .reason(fieldError.getDefaultMessage())
        .rejectedValue(fieldError.getRejectedValue())
        .build();
  }
}
