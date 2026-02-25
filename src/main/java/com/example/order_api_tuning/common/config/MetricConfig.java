package com.example.order_api_tuning.common.config;

import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.autoconfigure.metrics.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MetricConfig {

  @Bean
  MeterRegistryCustomizer<MeterRegistry> metricsCommonTags(
      @Value("${spring.datasource.hikari.maximum-pool-size}") String pool) {
    return r -> r.config().commonTags("exp", "hikari", "pool", pool);
  }
}
