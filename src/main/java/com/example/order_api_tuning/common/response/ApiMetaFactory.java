package com.example.order_api_tuning.common.response;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.slf4j.MDC;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

@Component
public class ApiMetaFactory {

  public ApiResponse.Meta meta(Pageable pageable, Page<?> page) {
    String traceId = MDC.get("traceId");

    ApiResponse.Meta.MetaBuilder builder = ApiResponse.Meta.builder()
        .timestamp(OffsetDateTime.now(ZoneOffset.UTC).toString())
        .traceId(traceId);

    if (page != null) {
      builder.page(ApiResponse.PageMeta.builder()
          .number(page.getNumber())
          .size(page.getSize())
          .totalElements(page.getTotalElements())
          .totalPages(page.getTotalPages())
          .build());
    } else if (pageable != null) {
      builder.page(ApiResponse.PageMeta.builder()
          .number(pageable.getPageNumber())
          .size(pageable.getPageSize())
          .build());
    }

    return builder.build();
  }
}
