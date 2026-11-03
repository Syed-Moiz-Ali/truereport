package com.truereport.shared.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "truereport.encryption")
public record EncryptionProperties(String key) {
}
