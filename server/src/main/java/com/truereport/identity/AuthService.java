package com.truereport.identity;

import com.truereport.audit.AuditService;
import com.truereport.identity.api.AuthResponse;
import com.truereport.identity.api.MembershipDto;
import com.truereport.identity.api.RecoveryCodesResponse;
import com.truereport.identity.api.TotpEnrollmentResponse;
import com.truereport.identity.api.UserDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.JwtProperties;
import com.truereport.shared.security.JwtService;
import com.truereport.shared.security.SecretCipher;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final TotpRecoveryCodeRepository recoveryCodes;
    private final WorkshopMembershipRepository memberships;
    private final WorkshopRepository workshops;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;
    private final TotpService totpService;
    private final SecretCipher secretCipher;
    private final AuditService auditService;
    private final boolean adminTotpRequired;
    private final SecureRandom random = new SecureRandom();

    public AuthService(UserRepository users,
                       RefreshTokenRepository refreshTokens,
                       TotpRecoveryCodeRepository recoveryCodes,
                       WorkshopMembershipRepository memberships,
                       WorkshopRepository workshops,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       JwtProperties jwtProperties,
                       TotpService totpService,
                       SecretCipher secretCipher,
                       AuditService auditService,
                       @org.springframework.beans.factory.annotation.Value(
                               "${truereport.auth.admin-totp.required:false}")
                       boolean adminTotpRequired) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.recoveryCodes = recoveryCodes;
        this.memberships = memberships;
        this.workshops = workshops;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
        this.totpService = totpService;
        this.secretCipher = secretCipher;
        this.auditService = auditService;
        this.adminTotpRequired = adminTotpRequired;
    }

    @Transactional
    public AuthResponse login(String email, String password) {
        User user = users.findByEmailNormalized(User.normalizeEmail(email))
                .orElseThrow(() -> ApiException.unauthorized("AUTH_INVALID_CREDENTIALS", "Invalid credentials"));
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        if (user.isLocked(now)) {
            auditService.recordAuth(user.getId(), "LOGIN_LOCKED", "LOCKED");
            throw ApiException.unauthorized("AUTH_INVALID_CREDENTIALS", "Invalid credentials");
        }
        if (user.getStatus() != UserStatus.ACTIVE || !passwordEncoder.matches(password, user.getPasswordHash())) {
            user.recordLoginFailure(now);
            users.save(user);
            auditService.recordAuth(user.getId(), "LOGIN_FAILED", "INVALID_CREDENTIALS");
            throw ApiException.unauthorized("AUTH_INVALID_CREDENTIALS", "Invalid credentials");
        }
        user.clearLoginFailures();
        users.save(user);
        if (adminTotpRequired && user.isTotpEnabled()) {
            auditService.recordAuth(user.getId(), "LOGIN_2FA_REQUIRED", null);
            return AuthResponse.challenge(jwtService.issueChallenge(user.getId()));
        }
        return completeLogin(user);
    }

    @Transactional
    public AuthResponse verifyTwoFactor(String challengeToken, String code) {
        Jwt jwt;
        try {
            jwt = jwtService.decode(challengeToken);
        } catch (RuntimeException e) {
            throw ApiException.unauthorized("AUTH_2FA_INVALID", "Invalid or expired challenge");
        }
        if (!"2fa".equals(jwt.getClaimAsString("purpose")) || !adminTotpRequired) {
            throw ApiException.unauthorized("AUTH_2FA_INVALID", "Invalid challenge");
        }
        UUID userId = UUID.fromString(jwt.getClaimAsString("uid"));
        User user = users.findById(userId).orElseThrow(() -> ApiException.unauthorized("AUTH_2FA_INVALID", "Invalid challenge"));
        requireActive(user);
        if (!user.isTotpEnabled() || user.getTotpSecretEnc() == null) {
            throw ApiException.unauthorized("AUTH_2FA_INVALID", "Two-factor authentication is not enabled");
        }
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        if (user.isLocked(now)) {
            auditService.recordAuth(user.getId(), "TOTP_LOCKED", "LOCKED");
            throw ApiException.unauthorized("AUTH_2FA_INVALID", "Invalid authentication code");
        }
        String secret = secretCipher.decrypt(user.getTotpSecretEnc());
        long step = code.matches("\\d{6}")
                ? totpService.verify(secret, code, Instant.now(), user.getTotpLastStep())
                : -1;
        if (step >= 0) {
            user.setTotpLastStep(step);
            user.clearTotpFailures();
            users.save(user);
            auditService.recordAuth(user.getId(), "TOTP_SUCCEEDED", null);
            return completeLogin(user);
        }
        if (consumeRecoveryCode(user.getId(), code, now)) {
            user.clearTotpFailures();
            users.save(user);
            auditService.recordAuth(user.getId(), "TOTP_RECOVERY_SUCCEEDED", null);
            return completeLogin(user);
        }
        user.recordTotpFailure(now);
        users.save(user);
        auditService.recordAuth(user.getId(), "TOTP_FAILED", "INVALID_CODE");
        throw ApiException.unauthorized("AUTH_2FA_INVALID", "Invalid authentication code");
    }

    @Transactional
    public AuthResponse refresh(String rawRefreshToken) {
        byte[] hash = hash(rawRefreshToken);
        RefreshToken stored = refreshTokens.findByTokenHash(hash)
                .orElseThrow(() -> ApiException.unauthorized("AUTH_TOKEN_INVALID", "Invalid refresh token"));
        if (stored.getRevokedAt() != null) {
            revokeFamily(stored.getFamilyId());
            auditService.recordAuth(stored.getUserId(), "REFRESH_REUSE_DETECTED", "ROTATED_TOKEN_REUSED");
            throw ApiException.unauthorized("AUTH_REFRESH_REUSED", "Refresh token reuse detected");
        }
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        if (!stored.isActive(now)) {
            throw ApiException.unauthorized("AUTH_TOKEN_EXPIRED", "Refresh token expired");
        }
        User user = users.findById(stored.getUserId())
                .orElseThrow(() -> ApiException.unauthorized("AUTH_TOKEN_INVALID", "Invalid refresh token"));
        requireActive(user);
        TokenRole resolved = resolveRole(user);
        IssuedRefreshToken next = newRefreshToken(user, stored.getFamilyId());
        stored.revoke(now, next.token().getId());
        refreshTokens.save(stored);
        String access = jwtService.issueAccess(user.getId(), user.getEmail(), resolved.role(), resolved.workshopId(), next.token().getId());
        return new AuthResponse(access, next.rawToken(), "Bearer",
                jwtProperties.accessTtl().toSeconds(), toDto(user), memberships(user.getId()), false, null);
    }

    @Transactional
    public void logout(UUID userId, UUID sessionId) {
        if (sessionId == null) {
            return;
        }
        refreshTokens.findById(sessionId).ifPresent(token -> {
            if (token.getUserId().equals(userId) && token.getRevokedAt() == null) {
                token.revoke(LocalDateTime.now(ZoneOffset.UTC), null);
                refreshTokens.save(token);
                auditService.recordAuth(userId, "LOGOUT", null);
            }
        });
    }

    @Transactional
    public void logoutAll(UUID userId) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        refreshTokens.findByUserIdAndRevokedAtIsNull(userId)
                .forEach(token -> {
                    token.revoke(now, null);
                    refreshTokens.save(token);
                });
        auditService.recordAuth(userId, "LOGOUT_ALL", null);
    }

    @Transactional(readOnly = true)
    public UserDto me(UUID userId) {
        return users.findById(userId).map(this::toDto)
                .orElseThrow(() -> ApiException.unauthorized("AUTH_TOKEN_INVALID", "User not found"));
    }

    @Transactional(readOnly = true)
    public List<MembershipDto> memberships(UUID userId) {
        return memberships.findByUserIdAndStatus(userId, "ACTIVE").stream()
                .map(membership -> {
                    String workshopName = workshops.findById(membership.getWorkshopId())
                            .map(Workshop::getName).orElse("Unknown workshop");
                    return new MembershipDto(membership.getWorkshopId(), workshopName, membership.getRole().name());
                })
                .toList();
    }

    @Transactional
    public TotpEnrollmentResponse enrollTotp(UUID userId) {
        requireTotpEnabled();
        User user = users.findById(userId).orElseThrow(ApiException::notFound);
        if (!user.isPlatformAdmin() && !hasRole(userId, "WORKSHOP_ADMIN")) {
            throw ApiException.forbidden();
        }
        if (user.isTotpEnabled()) {
            throw ApiException.conflict("TOTP_ALREADY_ENABLED", "Two-factor authentication is already enabled");
        }
        String secret = totpService.generateSecret();
        user.setTotpSecretEnc(secretCipher.encrypt(secret));
        users.save(user);
        auditService.recordAuth(userId, "TOTP_ENROLLMENT_STARTED", null);
        return new TotpEnrollmentResponse(secret,
                totpService.otpauthUri("TrueReport", user.getEmail(), secret));
    }

    @Transactional
    public RecoveryCodesResponse confirmTotp(UUID userId, String code) {
        requireTotpEnabled();
        User user = users.findById(userId).orElseThrow(ApiException::notFound);
        if (user.getTotpSecretEnc() == null) {
            throw ApiException.conflict("TOTP_NOT_ENROLLED", "Start enrollment first");
        }
        String secret = secretCipher.decrypt(user.getTotpSecretEnc());
        long step = totpService.verify(secret, code, Instant.now(), null);
        if (step < 0) {
            auditService.recordAuth(userId, "TOTP_CONFIRM_FAILED", "INVALID_CODE");
            throw ApiException.unauthorized("AUTH_2FA_INVALID", "Invalid authentication code");
        }
        user.setTotpEnabled(true);
        user.setTotpLastStep(step);
        user.clearLoginFailures();
        user.clearTotpFailures();
        users.save(user);
        RecoveryCodesResponse codes = regenerateRecoveryCodes(userId);
        auditService.recordAuth(userId, "TOTP_ENABLED", null);
        return codes;
    }

    @Transactional
    public RecoveryCodesResponse regenerateRecoveryCodes(UUID userId) {
        requireTotpEnabled();
        User user = users.findById(userId).orElseThrow(ApiException::notFound);
        if (!user.isTotpEnabled()) {
            throw ApiException.conflict("TOTP_NOT_ENABLED", "Enable two-factor authentication first");
        }
        recoveryCodes.deleteByUserId(userId);
        List<String> plaintext = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        for (int i = 0; i < 10; i++) {
            String code = recoveryCode();
            plaintext.add(code);
            recoveryCodes.save(new TotpRecoveryCode(userId, hash(code), now));
        }
        auditService.recordAuth(userId, "TOTP_RECOVERY_CODES_REGENERATED", null);
        return new RecoveryCodesResponse(List.copyOf(plaintext));
    }

    private boolean consumeRecoveryCode(UUID userId, String code, LocalDateTime now) {
        if (code == null || code.isBlank()) {
            return false;
        }
        return recoveryCodes.findByUserIdAndCodeHashAndUsedAtIsNull(userId, hash(code.trim().toUpperCase()))
                .map(found -> {
                    found.markUsed(now);
                    recoveryCodes.save(found);
                    return true;
                })
                .orElse(false);
    }

    private String recoveryCode() {
        String alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder value = new StringBuilder(11);
        for (int i = 0; i < 10; i++) {
            if (i == 5) {
                value.append('-');
            }
            value.append(alphabet.charAt(random.nextInt(alphabet.length())));
        }
        return value.toString();
    }

    private void requireTotpEnabled() {
        if (!adminTotpRequired) {
            throw ApiException.conflict("TOTP_DISABLED",
                    "Admin TOTP is disabled by configuration");
        }
    }

    private AuthResponse completeLogin(User user) {
        TokenRole resolved = resolveRole(user);
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        IssuedRefreshToken refresh = newRefreshToken(user, UuidV7.generate());
        String access = jwtService.issueAccess(user.getId(), user.getEmail(), resolved.role(),
                resolved.workshopId(), refresh.token().getId());
        auditService.record(resolved.workshopId(), user.getId(), resolved.role(),
                "LOGIN_SUCCEEDED", "USER", user.getId(), null, null);
        return new AuthResponse(access, refresh.rawToken(), "Bearer",
                jwtProperties.accessTtl().toSeconds(), toDto(user), memberships(user.getId()), false, null);
    }

    private IssuedRefreshToken newRefreshToken(User user, UUID familyId) {
        String raw = randomToken();
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        RefreshToken token = new RefreshToken(user.getId(), familyId, hash(raw), now,
                now.plus(jwtProperties.refreshTtl()));
        RefreshToken saved = refreshTokens.save(token);
        return new IssuedRefreshToken(saved, raw);
    }

    private TokenRole resolveRole(User user) {
        if (user.isPlatformAdmin()) {
            return new TokenRole("PLATFORM_ADMIN", null);
        }
        WorkshopMembership membership = memberships
                .findFirstByUserIdAndStatusAndPrimaryTrue(user.getId(), "ACTIVE")
                .or(() -> memberships.findByUserIdAndStatus(user.getId(), "ACTIVE").stream().findFirst())
                .orElseThrow(() -> new ApiException(HttpStatus.FORBIDDEN, "NO_WORKSHOP_MEMBERSHIP",
                        "error.noMembership", "No active workshop membership"));
        return new TokenRole(membership.getRole().name(), membership.getWorkshopId());
    }

    private boolean hasRole(UUID userId, String role) {
        return memberships.findByUserIdAndStatus(userId, "ACTIVE").stream()
                .anyMatch(m -> m.getRole().name().equals(role));
    }

    private void revokeFamily(UUID familyId) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        refreshTokens.findByFamilyId(familyId).stream()
                .filter(token -> token.getRevokedAt() == null)
                .forEach(token -> {
                    token.revoke(now, null);
                    refreshTokens.save(token);
                });
    }

    private void requireActive(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw ApiException.unauthorized("ACCOUNT_DISABLED", "Account is not active");
        }
    }

    private UserDto toDto(User user) {
        return new UserDto(user.getId(), user.getEmail(), user.getDisplayName(),
                user.isPlatformAdmin(), user.isTotpEnabled());
    }

    private String randomToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private byte[] hash(String raw) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(raw.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    private record TokenRole(String role, UUID workshopId) {
    }

    private record IssuedRefreshToken(RefreshToken token, String rawToken) {
    }
}
