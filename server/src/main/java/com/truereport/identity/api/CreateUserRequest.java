package com.truereport.identity.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateUserRequest(
        @Email @NotBlank String email,
        @NotBlank @Size(max = 200) String displayName,
        @NotBlank @Size(min = 8, max = 128) String temporaryPassword,
        @NotBlank String role,
        @NotNull UUID workshopId
) {
}
