package com.truereport.identity.api;

import java.util.List;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresInSeconds,
        UserDto user,
        List<MembershipDto> memberships,
        boolean requiresTwoFactor,
        String challengeToken
) {
    public static AuthResponse challenge(String challengeToken) {
        return new AuthResponse(null, null, null, 0, null, List.of(), true, challengeToken);
    }
}
