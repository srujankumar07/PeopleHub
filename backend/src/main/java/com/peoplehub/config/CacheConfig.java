package com.peoplehub.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;

/**
 * Turns on @Cacheable / @CacheEvict. The cache store (Redis) and its TTL come from application.yml.
 * Cached values are serialized with Java serialization, so cached DTOs must implement Serializable.
 */
@Configuration
@EnableCaching
public class CacheConfig {
}
