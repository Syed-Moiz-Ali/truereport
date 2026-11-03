package com.truereport.identity.api;

import jakarta.validation.constraints.Pattern;

public record TwoFactorConfirmRequest(@Pattern(regexp = "\\d{6}") String code) {
}
