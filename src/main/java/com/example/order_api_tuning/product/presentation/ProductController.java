package com.example.order_api_tuning.product.presentation;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ApiResponse;
import com.example.order_api_tuning.product.application.service.ProductService;
import com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto;
import com.example.order_api_tuning.product.presentation.dto.ProductSearchCondition;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/products")
public class ProductController {

  private final ProductService productService;
  private final ApiMetaFactory apiMetaFactory;

  @GetMapping()
  public ResponseEntity<ApiResponse<List<ProductInventoryDto>>> getAllProducts(
      @PageableDefault(size = 10, sort = "quantity", direction = Direction.DESC) Pageable pageable
  ){
    Page<ProductInventoryDto> page = productService.getAllProducts(pageable);
    return ResponseEntity.ok(ApiResponse.ok(page.getContent(),apiMetaFactory.meta(pageable,page)));
  }

  @GetMapping("/search")
  public ResponseEntity<ApiResponse<List<ProductInventoryDto>>> searchProducts(
      ProductSearchCondition condition,
      @PageableDefault(size = 10, sort = "createdAt", direction = Direction.DESC) Pageable pageable
  ){
    Page<ProductInventoryDto> page = productService.searchProducts(condition,pageable);
    return ResponseEntity.ok(ApiResponse.ok(page.getContent(),apiMetaFactory.meta(pageable,page)));
  }
}
