package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthTenancyIT extends IntegrationTestBase {

    @Test
    void technicianCannotCallWorkshopAdminEndpoints() throws Exception {
        Login tech = login("tech.a@test.local");

        mockMvc.perform(get("/api/v1/workshop/staff")
                        .header("Authorization", "Bearer " + tech.accessToken()))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/platform/workshops")
                        .header("Authorization", "Bearer " + tech.accessToken()))
                .andExpect(status().isForbidden());
    }

    @Test
    void workshopAdminCannotAccessAnotherWorkshop() throws Exception {
        Login adminA = login("admin.a@test.local");

        mockMvc.perform(get("/api/v1/workshops/" + fixture.workshopB().getId())
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/v1/workshop/staff")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[?(@.emailMasked == 'a***@test.local')]").exists());

        mockMvc.perform(get("/api/v1/platform/workshops")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isForbidden());
    }

    @Test
    void platformAdminCanListWorkshopsAndReadAnyWorkshop() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(get("/api/v1/platform/workshops")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        mockMvc.perform(get("/api/v1/workshops/" + fixture.workshopB().getId())
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(fixture.workshopB().getId().toString()));
    }

    @Test
    void technicianCannotReadAWorkshopSummary() throws Exception {
        Login tech = login("tech.a@test.local");

        mockMvc.perform(get("/api/v1/workshops/" + fixture.workshopA().getId())
                        .header("Authorization", "Bearer " + tech.accessToken()))
                .andExpect(status().isNotFound());
    }

    @Test
    void workshopAdminCannotUsePlatformWorkshopDetail() throws Exception {
        Login adminA = login("admin.a@test.local");

        mockMvc.perform(get("/api/v1/platform/workshops/" + fixture.workshopB().getId())
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/workshops/" + fixture.workshopA().getId())
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(fixture.workshopA().getId().toString()));
    }

    @Test
    void refreshTokenRotationAndReuseIsRejected() throws Exception {
        Login login = login("tech.a@test.local");

        var refreshResult = mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(login.refreshToken())))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode refreshed = objectMapper.readTree(refreshResult.getResponse().getContentAsString());
        assertThat(refreshed.get("refreshToken").asText()).isNotEqualTo(login.refreshToken());

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(login.refreshToken())))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH_REFRESH_REUSED"));

        // Reuse detection revokes the whole family, including the rotated token.
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refreshed.get("refreshToken").asText())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void meReturnsOnlyTheCallersMemberships() throws Exception {
        Login adminA = login("admin.a@test.local");

        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.email").value("admin.a@test.local"))
                .andExpect(jsonPath("$.memberships.length()").value(1))
                .andExpect(jsonPath("$.memberships[0].workshopId").value(fixture.workshopA().getId().toString()));
    }
}
