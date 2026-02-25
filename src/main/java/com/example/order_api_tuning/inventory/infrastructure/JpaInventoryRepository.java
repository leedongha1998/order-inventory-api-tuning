package com.example.order_api_tuning.inventory.infrastructure;

import com.example.order_api_tuning.inventory.domain.entity.Inventory;
import com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto;
import com.example.order_api_tuning.product.domain.entity.Product;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface JpaInventoryRepository extends JpaRepository<Inventory, Long> {

  @Query("select i from Inventory i where i.product.id = :productId")
  Optional<Inventory> findByProductId(Long productId);

  @Query("select i from Inventory i where i.product.id in :productIds")
  List<Inventory> findAllByProductIds(List<Long> productIds);

  // 현재는 간단한 테스트 위해 레파지토리 분리 안하고 dto 반환 로직을 여기에 두었다.
  @Query(value = """
        select new com.example.order_api_tuning.inventory.presentation.dto.ProductInventoryDto(
            p.id,
            p.name,
            p.price,
            i.quantity
        )
        from Inventory i
        join i.product p
        """,
      countQuery = "select count(i) from Inventory i")
  Page<ProductInventoryDto> findAllProductsJpql(Pageable pageable);


  @Query(value = """
        select 
            p.id as productId,
            p.name as productName,
            p.unit_price as unitPrice,
            i.quantity as quantity
        from inventory i
        join product p on i.product_id = p.id
        """,
      countQuery = "select count(*) from inventory i",
      nativeQuery = true)
  Page<ProductInventoryDto> findAllProductsNative(Pageable pageable);
}
