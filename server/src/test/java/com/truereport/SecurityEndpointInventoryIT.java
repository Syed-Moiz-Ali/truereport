package com.truereport;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class SecurityEndpointInventoryIT extends IntegrationTestBase {

    private static final Set<String> PUBLIC_PREFIXES = Set.of(
            "/api/v1/auth/login", "/api/v1/auth/refresh", "/api/v1/auth/2fa/verify",
            "/api/v1/auth/invitations/accept", "/api/v1/auth/password/",
            "/api/v1/delivery/webhooks/", "/actuator/", "/r/"
    );

    @Test
    void everyNonPublicApiEndpointRejectsAnonymousAccess() throws Exception {
        var result = mockMvc.perform(MockMvcRequestBuilders.get("/v3/api-docs"))
                .andExpect(status().isOk()).andReturn();
        var paths = objectMapper.readTree(result.getResponse().getContentAsString()).path("paths");
        assertThat(paths.size()).isGreaterThan(50);
        int tested = 0;
        var pathNames = paths.fieldNames();
        while (pathNames.hasNext()) {
            String path = pathNames.next();
            if (PUBLIC_PREFIXES.stream().anyMatch(path::startsWith)) {
                continue;
            }
            var methods = paths.path(path).fieldNames();
            while (methods.hasNext()) {
                String method = methods.next().toUpperCase();
                String concrete = path.replaceAll("\\{[^}]+}", UUID.randomUUID().toString());
                var request = MockMvcRequestBuilders.request(
                                org.springframework.http.HttpMethod.valueOf(method), concrete)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}");
                int status = mockMvc.perform(request).andReturn().getResponse().getStatus();
                assertThat(status).as(method + " " + path).isIn(401, 403);
                tested++;
            }
        }
        assertThat(tested).isGreaterThan(50);
    }

    @Test
    void rawStoragePathsAreNotExposed() throws Exception {
        Login admin = login("admin.a@test.local");
        for (String path : java.util.List.of(
                "/storage/evidence/anything",
                "/data/reports/report.pdf",
                "/files/private.txt")) {
            mockMvc.perform(MockMvcRequestBuilders.get(path)
                            .header("Authorization", "Bearer " + admin.accessToken()))
                    .andExpect(status().isNotFound());
        }
    }

    @Test
    void corsAllowsConfiguredOriginAndRejectsUnknownOrigin() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders.options("/api/v1/auth/me")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));
        mockMvc.perform(MockMvcRequestBuilders.options("/api/v1/auth/me")
                        .header("Origin", "https://evil.example")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden());
    }
}