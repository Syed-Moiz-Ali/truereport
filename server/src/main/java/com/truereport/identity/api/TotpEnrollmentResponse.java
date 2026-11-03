package com.truereport.identity.api;

public record TotpEnrollmentResponse(String secret, String otpauthUri) {
}
