package com.truereport.identity.api;

import java.util.UUID;

public record InvitationResponse(
        UUID invitationId,
        UUID userId,
        UUID workshopId,
        String email,
        String role,
        String status,
        String expiresAt,
        String invitationToken
) {
}
