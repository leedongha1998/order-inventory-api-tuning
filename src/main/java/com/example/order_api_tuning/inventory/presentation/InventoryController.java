package com.example.order_api_tuning.inventory.presentation;

import com.example.order_api_tuning.common.response.ApiMetaFactory;
import com.example.order_api_tuning.common.response.ApiResponse;
import com.example.order_api_tuning.inventory.presentation.dto.InventoryReqDto;
import com.example.order_api_tuning.inventory.presentation.dto.InventoryResDto;
import com.example.order_api_tuning.inventory.application.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
public class InventoryController {

  private final InventoryService inventoryService;
  private final ApiMetaFactory metaFactory;

  @GetMapping("/{productId}")
  public ResponseEntity<ApiResponse<InventoryResDto>> getInventoryByProductId(
      @PathVariable Long productId) {
    InventoryResDto result = inventoryService.getInventoryByProductId(productId);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(result, meta));
  }

  @PatchMapping("/{productId}")
  public ResponseEntity<ApiResponse<Void>> updateInventoryByProductId(@PathVariable Long productId, @RequestBody InventoryReqDto request){
    inventoryService.updateInventory(productId,request);
    ApiResponse.Meta meta = metaFactory.meta(null, null);
    return ResponseEntity.ok(ApiResponse.ok(meta));
  }
}
