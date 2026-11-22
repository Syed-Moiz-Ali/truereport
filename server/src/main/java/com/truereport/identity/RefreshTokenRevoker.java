package com.truereport.identity;

import com.truereport.audit.AuditService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.UUID;

/**
 * Refresh-token family revocation in its own transaction.
 *
 * <p>{@link AuthService#refresh} detects reuse and must revoke the whole family
 * before throwing {@code AUTH_REFRESH_REUSED}. Because that exception rolls the
 * caller's transaction back, the revocation and its audit row must commit in a
 * separate transaction.</p>
 */
@Service
public class RefreshTokenRevoker {

    private final RefreshTokenRepository refreshTokens;
    private final AuditService auditService;

    public RefreshTokenRevoker(RefreshTokenRepository refreshTokens,
                               AuditService auditService) {
        this.refreshTokens = refreshTokens;
        this.auditService = auditService;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void revokeFamily(UUID familyId) {
        revokeAll(familyId);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void revokeFamilyAndAudit(UUID familyId, UUID userId) {
        revokeAll(familyId);
        auditService.recordAuth(userId, "REFRESH_REUSE_DETECTED", "ROTATED_TOKEN_REUSED");
    }

    private void revokeAll(UUID familyId) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        refreshTokens.findByFamilyId(familyId).stream()
                .filter(token -> token.getRevokedAt() == null)
                .forEach(token -> {
                    token.revoke(now, null);
                    refreshTokens.save(token);
                });
    }
}
