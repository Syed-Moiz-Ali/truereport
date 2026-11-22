package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.audit.AuditEvent;
import com.truereport.audit.AuditEventRepository;
import com.truereport.identity.RefreshToken;
import com.truereport.identity.RefreshTokenRepository;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.identity.UserStatus;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.tenancy.WorkshopRole;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Production refresh-token behaviour, intentionally running without a test
 * transaction: reuse detection must commit the family revocation and its audit
 * row even though the refresh request returns 401.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)
class RefreshTokenRotationIT {

    private static final String PASSWORD = "Password123!";

    @Autowired
    MockMvc mockMvc;

    @Autowired
    com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    @Autowired
    UserRepository users;

    @Autowired
    WorkshopRepository workshops;

    @Autowired
    WorkshopMembershipRepository memberships;

    @Autowired
    RefreshTokenRepository refreshTokens;

    @Autowired
    AuditEventRepository auditEvents;

    @Autowired
    PasswordEncoder passwordEncoder;

    private UUID userId;
    private UUID workshopId;
    private String email;

    @BeforeEach
    void setUp() {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        email = "refresh." + suffix + "@test.local";
        Workshop workshop = workshops.save(new Workshop("Refresh Workshop " + suffix));
        workshopId = workshop.getId();
        User user = new User(email, passwordEncoder.encode(PASSWORD), "Refresh User");
        user.setStatus(UserStatus.ACTIVE);
        userId = users.save(user).getId();
        memberships.save(new WorkshopMembership(workshopId, userId,
                WorkshopRole.WORKSHOP_ADMIN, true));
    }

    @AfterEach
    void tearDown() {
        if (userId == null) {
            return;
        }
        refreshTokens.deleteAll(refreshTokens.findByUserId(userId));
        List<AuditEvent> events = auditEvents.findByActorUserId(userId);
        auditEvents.deleteAll(events);
        memberships.findByUserIdAndStatus(userId, "ACTIVE")
                .forEach(memberships::delete);
        users.deleteById(userId);
        workshops.deleteById(workshopId);
    }

    @Test
    void reuseRevokesTheWholeFamilyAndRotatedTokenInCommittedTransaction() throws Exception {
        Login first = login();
        UUID familyId = refreshTokens.findByUserId(userId).get(0).getFamilyId();

        JsonNode rotated = refresh(first.refreshToken(), 200);
        String rotatedRefresh = rotated.get("refreshToken").asText();
        assertThat(rotatedRefresh).isNotEqualTo(first.refreshToken());

        JsonNode reused = refresh(first.refreshToken(), 401);
        assertThat(reused.get("code").asText()).isEqualTo("AUTH_REFRESH_REUSED");

        // The rotated token must now be revoked; before the fix the 401 rolled
        // the family revocation back and this returned 200.
        JsonNode afterReuse = refresh(rotatedRefresh, 401);
        assertThat(afterReuse.get("code").asText()).isEqualTo("AUTH_REFRESH_REUSED");

        List<RefreshToken> family = refreshTokens.findByFamilyId(familyId);
        assertThat(family).hasSizeGreaterThanOrEqualTo(2);
        assertThat(family).allSatisfy(token ->
                assertThat(token.getRevokedAt()).as("token %s revoked", token.getId()).isNotNull());

        Integer audits = (int) auditEvents.countByAction("REFRESH_REUSE_DETECTED");
        assertThat(audits).isGreaterThanOrEqualTo(1);
    }

    @Test
    void expiredRefreshIsRejectedAndLogoutStillRevokes() throws Exception {
        Login expired = login();
        byte[] expiredHash = sha256(expired.refreshToken());
        RefreshToken token = refreshTokens.findByTokenHash(expiredHash).orElseThrow();
        int updated = refreshTokens.updateExpiresAt(token.getId(),
                LocalDateTime.now(ZoneOffset.UTC).minusHours(1));
        assertThat(updated).isEqualTo(1);
        RefreshToken expiredRow = refreshTokens.findByTokenHash(expiredHash).orElseThrow();
        assertThat(expiredRow.isActive(LocalDateTime.now(ZoneOffset.UTC))).isFalse();

        JsonNode expiredResponse = refresh(expired.refreshToken(), 401);
        assertThat(expiredResponse.get("code").asText()).isEqualTo("AUTH_TOKEN_EXPIRED");

        Login logout = login();
        mockMvc.perform(post("/api/v1/auth/logout")
                        .header("Authorization", "Bearer " + logout.accessToken()))
                .andExpect(status().isNoContent());
        RefreshToken revoked = refreshTokens.findByTokenHash(
                sha256(logout.refreshToken())).orElseThrow();
        assertThat(revoked.getRevokedAt()).isNotNull();
        refresh(logout.refreshToken(), 401);
    }

    // ------------------------------------------------------------------ helpers

    private Login login() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s"}
                                """.formatted(email, PASSWORD)))
                .andExpect(status().isOk()).andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return new Login(body.get("accessToken").asText(),
                body.get("refreshToken").asText());
    }

    private JsonNode refresh(String refreshToken, int expectedStatus) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refreshToken)))
                .andExpect(status().is(expectedStatus))
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private static byte[] sha256(String value) {
        try {
            return MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private record Login(String accessToken, String refreshToken) {
    }
}
