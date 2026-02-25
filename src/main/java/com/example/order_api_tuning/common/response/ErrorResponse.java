package com.example.order_api_tuning.common.response;

import com.example.order_api_tuning.common.exception.ErrorCode;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {
  private final boolean success;
  private final String message;
  private final String code;
  private final List<FieldError> errors;
  private final ApiResponse.Meta meta;

  @Getter
  @Builder
  public static class FieldError {
    private String field;
    private String reason;
    private Object rejectedValue;
  }

  public static ErrorResponse of(ErrorCode errorCode,String msg, List<FieldError> errors, ApiResponse.Meta meta) {
    return ErrorResponse.builder()
        .success(false)
        .code(errorCode.name())
        .message(msg != null ? msg : errorCode.getMessage())
        .errors(errors)
        .meta(meta)
        .build();
  }
}
