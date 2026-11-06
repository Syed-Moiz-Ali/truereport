package com.truereport;

import jakarta.annotation.security.DenyAll;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.security.access.annotation.Secured;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class SecurityEndpointInventoryIT extends IntegrationTestBase {

    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    RequestMappingHandlerMapping handlerMapping;

    private static final Set<String> PUBLIC_PREFIXES = Set.of(
            "/api/v1/auth/login", "/api/v1/auth/refresh", "/api/v1/auth/2fa/verify",
            "/api/v1/auth/password/",
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
    void everyHandlerHasExplicitAuthz() {
        List<String> missing = new ArrayList<>();
        int checked = 0;
        for (var entry : handlerMapping.getHandlerMethods().entrySet()) {
            RequestMappingInfo info = entry.getKey();
            Method method = entry.getValue().getMethod();
            Class<?> beanType = entry.getValue().getBeanType();
            if (beanType == null || !beanType.getPackageName().startsWith("com.truereport")) {
                continue;
            }
            if (!beanType.isAnnotationPresent(RestController.class)
                    && !beanType.isAnnotationPresent(Controller.class)) {
                continue;
            }
            checked++;
            if (!hasExplicitAuthz(method) && !hasExplicitAuthz(beanType)) {
                missing.add(beanType.getSimpleName() + "#" + method.getName() + " " + info);
            }
        }
        assertThat(checked).isGreaterThan(50);
        assertThat(missing).as("controller methods without explicit authz annotation").isEmpty();
    }

    private static boolean hasExplicitAuthz(java.lang.reflect.AnnotatedElement element) {
        return element.isAnnotationPresent(PreAuthorize.class)
                || element.isAnnotationPresent(Secured.class)
                || element.isAnnotationPresent(RolesAllowed.class)
                || element.isAnnotationPresent(PermitAll.class)
                || element.isAnnotationPresent(DenyAll.class);
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