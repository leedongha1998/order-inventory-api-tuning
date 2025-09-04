package com.example.order_api_tuning.product.infrastructure;

import com.example.order_api_tuning.product.domain.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JpaProductRepository extends JpaRepository<Product,Long> {
}
