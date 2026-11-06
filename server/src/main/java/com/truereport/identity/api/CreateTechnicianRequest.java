package com.truereport.identity.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateTechnicianRequest(
        @Email @NotBlank String email,
        @NotBlank @Size(max = 200) String displayName,
        @NotBlank @Size(min = 12, max = 128) String initialPassword
) {
}
