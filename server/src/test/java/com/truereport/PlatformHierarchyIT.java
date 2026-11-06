package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformHierarchyIT extends IntegrationTestBase {

    private static final String STRONG_PASSWORD = "Str0ng!InitPass1";
    private static final String STRONG_PASSWORD_2 = "An0ther!InitPass2";
    private static final String WEAK_PASSWORD = "weakpassword12";

    @Test
    void platformAdminCreatesWorkshopAdminWithWorkshopAssignment() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode created = postJson(platform, "/api/v1/platform/users", """
                {"email":"new.wadmin@test.local","displayName":"New WAdmin",
                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                """.formatted(STRONG_PASSWORD, fixture.workshopA().getId()), "create-wadmin-1");
        assertThat(created.get("role").asText()).isEqualTo("WORKSHOP_ADMIN");
        assertThat(created.get("workshopId").asText()).isEqualTo(fixture.workshopA().getId().toString());
        assertThat(created.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(created.toString()).doesNotContain(STRONG_PASSWORD);

        Login createdLogin = login("new.wadmin@test.local", STRONG_PASSWORD);
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + createdLogin.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberships[0].workshopId")
                        .value(fixture.workshopA().getId().toString()));
    }

    @Test
    void platformCannotCreateTechniciansStrictChainA1() throws Exception {
        Login platform = login("platform@test.local");
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "a1-tech-attempt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"no.tech@test.local","displayName":"No Tech",
                                 "temporaryPassword":"%s","role":"TECHNICIAN","workshopId":"%s"}
                                """.formatted(STRONG_PASSWORD, fixture.workshopA().getId())))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ROLE_NOT_PERMITTED"));
    }

    @Test
    void workshopAdminCreatesTechnicianInOwnWorkshopOnly() throws Exception {
        Login adminA = login("admin.a@test.local");

        JsonNode created = postJson(adminA, "/api/v1/workshop/technicians", """
                {"email":"owned.tech@test.local","displayName":"Owned Tech",
                 "initialPassword":"%s"}
                """.formatted(STRONG_PASSWORD), "create-tech-own-1");
        UUID createdId = UUID.fromString(created.get("userId").asText());
        assertThat(created.get("role").asText()).isEqualTo("TECHNICIAN");
        assertThat(created.get("workshopId").asText()).isEqualTo(fixture.workshopA().getId().toString());
        assertThat(created.toString()).doesNotContain(STRONG_PASSWORD);

        Login techLogin = login("owned.tech@test.local", STRONG_PASSWORD);
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + techLogin.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberships[0].workshopId")
                        .value(fixture.workshopA().getId().toString()));

        // Cross-workshop admin must not see or touch this technician: neutral 404.
        Login adminB = login("admin.b@test.local");
        mockMvc.perform(post("/api/v1/workshop/technicians/" + createdId + "/password-reset")
                        .header("Authorization", "Bearer " + adminB.accessToken())
                        .header("Idempotency-Key", "cross-workshop-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newPassword":"%s"}
                                """.formatted(STRONG_PASSWORD_2)))
                .andExpect(status().isNotFound());
        String staffB = mockMvc.perform(get("/api/v1/workshop/staff")
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isOk()).andReturn()
                .getResponse().getContentAsString();
        assertThat(staffB).doesNotContain("owned.tech@test.local");
    }

    @Test
    void roleMatrixForAccountEndpoints() throws Exception {
        Login technician = login("tech.a@test.local");
        Login workshopAdmin = login("admin.a@test.local");
        Login platform = login("platform@test.local");
        UUID userId = fixture.techA().getId();

        // Technician is denied everywhere for account management.
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "tech-creates")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/workshop/technicians")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "tech-creates-tech")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/workshop/technicians/" + userId + "/password-reset")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "tech-resets")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"newPassword\":\"%s\"}".formatted(STRONG_PASSWORD)))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/platform/users/" + userId + "/password-reset")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "tech-resets-platform")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"newPassword\":\"%s\"}".formatted(STRONG_PASSWORD)))
                .andExpect(status().isForbidden());

        // Workshop Admin cannot use platform-scoped endpoints.
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken())
                        .header("Idempotency-Key", "wadmin-creates-platform")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/platform/users/" + userId + "/password-reset")
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken())
                        .header("Idempotency-Key", "wadmin-resets-platform")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"newPassword\":\"%s\"}".formatted(STRONG_PASSWORD)))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/platform/users/" + userId + "/transfer")
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"workshopId\":\"" + fixture.workshopB().getId() + "\",\"reason\":\"Hijack\"}"))
                .andExpect(status().isForbidden());

        // Platform Admin cannot use workshop-scoped endpoints.
        mockMvc.perform(post("/api/v1/workshop/technicians")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "platform-creates-tech")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/workshop/technicians/" + userId + "/password-reset")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "platform-resets-tech")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"newPassword\":\"%s\"}".formatted(STRONG_PASSWORD)))
                .andExpect(status().isForbidden());

        // Anonymous access is rejected.
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Idempotency-Key", "anon")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/v1/workshop/technicians")
                        .header("Idempotency-Key", "anon")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void passwordResetRevokesSessionsAndRequiresNewPassword() throws Exception {
        Login adminA = login("admin.a@test.local");
        JsonNode created = postJson(adminA, "/api/v1/workshop/technicians", """
                {"email":"reset.tech@test.local","displayName":"Reset Tech",
                 "initialPassword":"%s"}
                """.formatted(STRONG_PASSWORD), "reset-revoke-create");
        UUID createdId = UUID.fromString(created.get("userId").asText());
        Login before = login("reset.tech@test.local", STRONG_PASSWORD);

        mockMvc.perform(post("/api/v1/workshop/technicians/" + createdId + "/password-reset")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .header("Idempotency-Key", "reset-revoke-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newPassword":"%s"}
                                """.formatted(STRONG_PASSWORD_2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(createdId.toString()));

        // Old password no longer works; old refresh token is revoked.
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"reset.tech@test.local","password":"%s"}
                                """.formatted(STRONG_PASSWORD)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(before.refreshToken())))
                .andExpect(status().isUnauthorized());

        // New password works.
        Login after = login("reset.tech@test.local", STRONG_PASSWORD_2);
        assertThat(after.accessToken()).isNotBlank();
    }

    @Test
    void platformPasswordResetRevokesWorkshopAdminSessions() throws Exception {
        Login platform = login("platform@test.local");
        JsonNode created = postJson(platform, "/api/v1/platform/users", """
                {"email":"reset.wadmin@test.local","displayName":"Reset WAdmin",
                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                """.formatted(STRONG_PASSWORD, fixture.workshopA().getId()), "reset-wadmin-create");
        UUID createdId = UUID.fromString(created.get("userId").asText());
        Login before = login("reset.wadmin@test.local", STRONG_PASSWORD);

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/password-reset")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "reset-wadmin-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newPassword":"%s"}
                                """.formatted(STRONG_PASSWORD_2)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(before.refreshToken())))
                .andExpect(status().isUnauthorized());
        Login after = login("reset.wadmin@test.local", STRONG_PASSWORD_2);
        assertThat(after.accessToken()).isNotBlank();
    }

    @Test
    void createIsIdempotentOnSameKeyAndConflictsOnReuse() throws Exception {
        Login platform = login("platform@test.local");
        String body = """
                {"email":"idem.wadmin@test.local","displayName":"Idem WAdmin",
                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                """.formatted(STRONG_PASSWORD, fixture.workshopA().getId());
        JsonNode first = postJson(platform, "/api/v1/platform/users", body, "idem-key-1");
        JsonNode second = postJson(platform, "/api/v1/platform/users", body, "idem-key-1");
        assertThat(second.get("userId").asText()).isEqualTo(first.get("userId").asText());

        // Same key with a different payload is a conflict.
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "idem-key-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"other.wadmin@test.local","displayName":"Other",
                                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                                """.formatted(STRONG_PASSWORD, fixture.workshopA().getId())))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("IDEMPOTENCY_KEY_REUSED"));

        // Missing Idempotency-Key is rejected (Spring required-header handling -> 400).
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void duplicateEmailIsNeutralAndPolicyChecked() throws Exception {
        Login platform = login("platform@test.local");
        String existingBody = """
                {"email":"admin.a@test.local","displayName":"Clone",
                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                """.formatted(STRONG_PASSWORD, fixture.workshopA().getId());
        var duplicate = mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "dup-neutral-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(existingBody))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("EMAIL_EXISTS"))
                .andReturn();
        assertThat(duplicate.getResponse().getContentAsString()).doesNotContain("Admin A");

        // Weak initial password is rejected by the policy without echoing it.
        mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "weak-policy-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"weak.wadmin@test.local","displayName":"Weak",
                                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                                """.formatted(WEAK_PASSWORD, fixture.workshopA().getId())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("PASSWORD_POLICY_VIOLATION"))
                .andReturn();
        var weak = mockMvc.perform(post("/api/v1/platform/users")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "weak-policy-2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"weak2.wadmin@test.local","displayName":"Weak2",
                                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                                """.formatted(WEAK_PASSWORD, fixture.workshopA().getId())))
                .andExpect(status().isUnprocessableEntity())
                .andReturn();
        assertThat(weak.getResponse().getContentAsString()).doesNotContain(WEAK_PASSWORD);
    }

    @Test
    void lastAdminsCannotBeDisabled() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(post("/api/v1/platform/users/" + fixture.adminA().getId() + "/disable")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Test last admin guard"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LAST_WORKSHOP_ADMIN"));

        mockMvc.perform(post("/api/v1/platform/users/" + fixture.platform().getId() + "/disable")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Test last platform admin guard"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LAST_PLATFORM_ADMIN"));
    }

    @Test
    void oldInvitationEndpointsAreGone() throws Exception {
        Login platform = login("platform@test.local");

        // Removed platform invitation endpoint: no handler -> 404 for an authorized caller.
        mockMvc.perform(post("/api/v1/platform/invitations")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"ghost@test.local","displayName":"Ghost",
                                 "role":"TECHNICIAN","workshopId":"%s"}
                                """.formatted(fixture.workshopA().getId())))
                .andExpect(status().isNotFound());

        // Removed public acceptance endpoint: no handler -> 401 anonymously (no longer public), 404 when authenticated.
        mockMvc.perform(post("/api/v1/auth/invitations/accept")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"anything","password":"%s"}
                                """.formatted(STRONG_PASSWORD)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/v1/auth/invitations/accept")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"anything","password":"%s"}
                                """.formatted(STRONG_PASSWORD)))
                .andExpect(status().isNotFound());
    }

    @Test
    void hierarchyHasNoPendingStatusOrInvitations() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(get("/api/v1/platform/hierarchy")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.workshops[*].pendingInvitations").doesNotExist());

        mockMvc.perform(get("/api/v1/platform/hierarchy")
                        .param("status", "PENDING")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_FILTER"));
    }

    @Test
    void accountLifecycleDisableReactivateTransferAndAuditWithoutPasswords() throws Exception {
        Login platform = login("platform@test.local");
        String secret = "SecRet!Lifecycle99";

        JsonNode created = postJson(platform, "/api/v1/platform/users", """
                {"email":"lifecycle@test.local","displayName":"Lifecycle",
                 "temporaryPassword":"%s","role":"WORKSHOP_ADMIN","workshopId":"%s"}
                """.formatted(secret, fixture.workshopA().getId()), "lifecycle-create");
        UUID createdId = UUID.fromString(created.get("userId").asText());

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/disable")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Left the workshop"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DISABLED"));

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/reactivate")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Returned to the workshop"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/transfer")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"workshopId":"%s","reason":"Moved to Workshop B"}
                                """.formatted(fixture.workshopB().getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.workshopId").value(fixture.workshopB().getId().toString()));

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/password-reset")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .header("Idempotency-Key", "lifecycle-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newPassword":"%s"}
                                """.formatted(STRONG_PASSWORD_2)))
                .andExpect(status().isOk());

        var audit = mockMvc.perform(get("/api/v1/platform/audit-events")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_CREATED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_DISABLED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_REACTIVATED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_TRANSFERRED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_PASSWORD_RESET')]").exists())
                .andReturn();
        String auditBody = audit.getResponse().getContentAsString();
        assertThat(auditBody).doesNotContain(secret);
        assertThat(auditBody).doesNotContain(STRONG_PASSWORD_2);
        assertThat(auditBody).doesNotContain("ACCOUNT_INVITED");
    }

    @Test
    void technicianAndWorkshopAdminCannotUsePlatformHierarchyEndpoints() throws Exception {
        Login technician = login("tech.a@test.local");
        Login workshopAdmin = login("admin.a@test.local");
        UUID workshop = fixture.workshopA().getId();
        List<String> endpoints = List.of(
                "/api/v1/platform/hierarchy",
                "/api/v1/platform/workshops/" + workshop + "/hierarchy",
                "/api/v1/platform/users",
                "/api/v1/platform/users/" + UUID.randomUUID() + "/password-reset",
                "/api/v1/platform/users/" + UUID.randomUUID() + "/disable",
                "/api/v1/platform/users/" + UUID.randomUUID() + "/reactivate",
                "/api/v1/platform/users/" + UUID.randomUUID() + "/transfer",
                "/api/v1/platform/audit-events",
                "/api/v1/platform/master/categories",
                "/api/v1/platform/master/items",
                "/api/v1/platform/master/reasons",
                "/api/v1/platform/master/equipment",
                "/api/v1/platform/master/dropdowns",
                "/api/v1/platform/master/guide-images"
        );
        for (String endpoint : endpoints) {
            mockMvc.perform(get(endpoint)
                            .header("Authorization", "Bearer " + technician.accessToken()))
                    .andExpect(status().isForbidden());
            mockMvc.perform(get(endpoint)
                            .header("Authorization", "Bearer " + workshopAdmin.accessToken()))
                    .andExpect(status().isForbidden());
        }
    }

    private JsonNode postJson(Login login, String path, String body, String idempotencyKey) throws Exception {
        var result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .header("Idempotency-Key", idempotencyKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private Login login(String email, String password) throws Exception {
        var result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s"}
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return new Login(body.get("accessToken").asText(), body.get("refreshToken").asText());
    }
}
