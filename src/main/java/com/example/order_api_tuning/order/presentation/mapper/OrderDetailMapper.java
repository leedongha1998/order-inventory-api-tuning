package com.example.order_api_tuning.order.presentation.mapper;

import com.example.order_api_tuning.order.domain.entity.Order;
import com.example.order_api_tuning.order.domain.entity.OrderItem;
import com.example.order_api_tuning.order.presentation.dto.ItemDetail;
import com.example.order_api_tuning.order.presentation.dto.OrderDetailDto;
import java.util.List;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface OrderDetailMapper {

  @Mapping(source = "id", target = "orderId")
  @Mapping(source = "items", target = "items")
  @Mapping(source = "status", target = "orderStatus")
  @Mapping(source = "totalAmount", target = "totalAmount")
  OrderDetailDto toDto(Order order);

  @Mapping(source = "product.id", target = "productId")
  @Mapping(source = "product.name", target = "productName")
  @Mapping(source = "quantity", target = "quantity")
  @Mapping(source = "unitPrice", target = "unitPrice")
  ItemDetail toItemDto(OrderItem item);

  List<ItemDetail> toItems(List<OrderItem> items);
}
