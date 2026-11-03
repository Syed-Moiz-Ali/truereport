package com.truereport.tenancy;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(prefix = "truereport.invitations")
public record InvitationProperties(Duration ttl) {
}
