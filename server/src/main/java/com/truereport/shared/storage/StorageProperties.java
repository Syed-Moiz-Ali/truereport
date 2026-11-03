package com.truereport.shared.storage;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "truereport.storage")
public record StorageProperties(String localRoot) {
}
