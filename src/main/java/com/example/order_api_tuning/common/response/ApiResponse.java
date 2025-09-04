package com.example.order_api_tuning.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

  private final boolean success;
  private final String message;
  private final String code;
  private final T data;
  private final Meta meta;

  @Getter
  @Builder
  public static class Meta {

    private String timestamp;
    private String traceId;
    private PageMeta page;
  }

  @Builder
  @Getter
  public static class PageMeta {

    private int number;
    private int size;
    private Long totalElements;
    private int totalPages;
  }

  public static <T> ApiResponse<T> ok(T data, Meta meta) {
    return ApiResponse
        .<T>builder()
        .success(true)
        .code("OK")
        .data(data)
        .meta(meta)
        .build();
  }

  public static ApiResponse<Void> ok(ApiResponse.Meta meta) {
    return ApiResponse.<Void>builder()
        .success(true)
        .code("OK")
        .meta(meta)
        .build();
  }
}
