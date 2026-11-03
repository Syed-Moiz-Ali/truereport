package com.truereport.shared.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(prefix = "truereport.jwt")
public record JwtProperties(
        String issuer,
        String audience,
        String secret,
        Duration accessTtl,
        Duration refreshTtl,
        Duration challengeTtl
) {
}
