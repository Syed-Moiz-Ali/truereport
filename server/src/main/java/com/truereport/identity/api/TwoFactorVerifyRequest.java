package com.truereport.identity.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record TwoFactorVerifyRequest(
        @NotBlank String challengeToken,
        @Pattern(regexp = "\\d{6}") String code
) {
}
