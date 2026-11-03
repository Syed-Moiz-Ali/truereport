package com.truereport.identity.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record InviteRequest(
        @Email @NotBlank String email,
        @NotBlank @Size(max = 200) String displayName,
        @NotBlank String role,
        @NotNull UUID workshopId
) {
}
