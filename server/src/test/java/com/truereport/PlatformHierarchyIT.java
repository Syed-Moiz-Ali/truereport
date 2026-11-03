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

    @Test
    void platformAdminCanSearchAndFilterTheHierarchy() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(get("/api/v1/platform/hierarchy")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalWorkshops").value(2));

        mockMvc.perform(get("/api/v1/platform/hierarchy")
                        .param("search", "Workshop A")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.workshops.length()").value(1))
                .andExpect(jsonPath("$.workshops[0].name").value("Workshop A"));

        mockMvc.perform(get("/api/v1/platform/workshops/" + fixture.workshopB().getId() + "/hierarchy")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Workshop B"));
    }

    @Test
    void accountLifecycleCreateInviteDisableReactivateTransferAndAudit() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode created = postJson(platform, "/api/v1/platform/users", """
                {"email":"new.tech@test.local","displayName":"New Tech","temporaryPassword":"Password123!",
                 "role":"TECHNICIAN","workshopId":"%s"}
                """.formatted(fixture.workshopA().getId()));
        UUID createdId = UUID.fromString(created.get("userId").asText());
        assertThat(created.get("role").asText()).isEqualTo("TECHNICIAN");

        Login createdLogin = login("new.tech@test.local");
        var me = mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + createdLogin.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberships[0].workshopId").value(fixture.workshopA().getId().toString()));

        JsonNode invitation = postJson(platform, "/api/v1/platform/invitations", """
                {"email":"invited.tech@test.local","displayName":"Invited Tech",
                 "role":"TECHNICIAN","workshopId":"%s"}
                """.formatted(fixture.workshopA().getId()));
        String invitationToken = invitation.get("invitationToken").asText();
        assertThat(invitationToken).isNotBlank();

        mockMvc.perform(post("/api/v1/auth/invitations/accept")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"%s","password":"Password123!"}
                                """.formatted(invitationToken)))
                .andExpect(status().isNoContent());
        Login invitedLogin = login("invited.tech@test.local");
        assertThat(invitedLogin.accessToken()).isNotBlank();

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/disable")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Left the workshop"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DISABLED"));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"new.tech@test.local","password":"Password123!"}
                                """))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/reactivate")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Returned to the workshop"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        Login reactivated = login("new.tech@test.local");

        mockMvc.perform(post("/api/v1/platform/users/" + createdId + "/transfer")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"workshopId":"%s","reason":"Moved to Workshop B"}
                                """.formatted(fixture.workshopB().getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.workshopId").value(fixture.workshopB().getId().toString()));

        Login transferred = login("new.tech@test.local");
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + transferred.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberships[0].workshopId").value(fixture.workshopB().getId().toString()));

        mockMvc.perform(get("/api/v1/platform/audit-events")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_CREATED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_INVITED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_DISABLED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_REACTIVATED')]").exists())
                .andExpect(jsonPath("$[?(@.action == 'ACCOUNT_TRANSFERRED')]").exists());
    }

    @Test
    void lastWorkshopAdminCannotBeDisabled() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(post("/api/v1/platform/users/" + fixture.adminA().getId() + "/disable")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Test last admin guard"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LAST_WORKSHOP_ADMIN"));
    }

    @Test
    void technicianAndWorkshopAdminCannotUsePlatformHierarchyOrContentEndpoints() throws Exception {
        Login technician = login("tech.a@test.local");
        Login workshopAdmin = login("admin.a@test.local");
        UUID workshop = fixture.workshopA().getId();
        List<String> endpoints = List.of(
                "/api/v1/platform/hierarchy",
                "/api/v1/platform/workshops/" + workshop + "/hierarchy",
                "/api/v1/platform/users",
                "/api/v1/platform/invitations",
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

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
