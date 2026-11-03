package com.truereport.identity.api;

import java.util.UUID;

public record UserDto(UUID id, String email, String displayName, boolean platformAdmin, boolean totpEnabled) {
}
