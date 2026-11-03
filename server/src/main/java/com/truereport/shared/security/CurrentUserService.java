package com.truereport.shared.security;

import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CurrentUserService {

    public CurrentUser require(JwtAuthenticationToken authentication) {
        Jwt jwt = authentication.getToken();
        String uid = jwt.getClaimAsString("uid");
        String role = jwt.getClaimAsString("role");
        String wid = jwt.getClaimAsString("wid");
        String sid = jwt.getClaimAsString("sid");
        if (uid == null || role == null) {
            throw new IllegalStateException("Access token is missing uid or role");
        }
        return new CurrentUser(
                UUID.fromString(uid),
                jwt.getSubject(),
                role,
                wid == null ? null : UUID.fromString(wid),
                sid == null ? null : UUID.fromString(sid)
        );
    }
}
