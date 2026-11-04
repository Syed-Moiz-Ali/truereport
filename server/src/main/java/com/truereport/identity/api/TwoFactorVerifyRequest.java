package com.truereport.identity.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TwoFactorVerifyRequest(
        @NotBlank String challengeToken,
        @Size(max = 40) String code
) {
}
