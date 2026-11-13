package com.truereport;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CorsPreflightIT extends IntegrationTestBase {

    private static final String ORIGIN = "http://localhost:3000";

    @Test
    void publicLoginPreflightAllowsXRequestId() throws Exception {
        var result = mockMvc.perform(options("/api/v1/auth/login")
                        .header(HttpHeaders.ORIGIN, ORIGIN)
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS,
                                "x-request-id, authorization, content-type"))
                .andExpect(status().is2xxSuccessful())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN))
                .andReturn();
        String allowHeaders = result.getResponse()
                .getHeader(HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS);
        assertThat(allowHeaders).isNotNull();
        assertThat(allowHeaders.toLowerCase(java.util.Locale.ROOT)).contains("x-request-id");
    }

    @Test
    void authenticatedLanguagePathPreflightSucceedsWithoutToken() throws Exception {
        var result = mockMvc.perform(options("/api/v1/platform/i18n/languages")
                        .header(HttpHeaders.ORIGIN, ORIGIN)
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "x-request-id"))
                .andExpect(status().is2xxSuccessful())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN))
                .andReturn();
        String allowHeaders = result.getResponse()
                .getHeader(HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS);
        assertThat(allowHeaders).isNotNull();
        assertThat(allowHeaders.toLowerCase(java.util.Locale.ROOT)).contains("x-request-id");
    }

    @Test
    void publicBundlePreflightAndGetSucceedWithoutToken() throws Exception {
        mockMvc.perform(options("/api/v1/i18n/ui-messages/bundle")
                        .header(HttpHeaders.ORIGIN, ORIGIN)
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "x-request-id"))
                .andExpect(status().is2xxSuccessful())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN));

        mockMvc.perform(get("/api/v1/i18n/ui-messages/bundle?lang=en")
                        .header(HttpHeaders.ORIGIN, ORIGIN))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, ORIGIN));
    }

    @Test
    void unknownOriginIsRejectedOnPreflight() throws Exception {
        mockMvc.perform(options("/api/v1/i18n/ui-messages/bundle")
                        .header(HttpHeaders.ORIGIN, "https://evil.example")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET"))
                .andExpect(status().isForbidden());
    }

    @Test
    void authenticatedPathsStillEnforceAuthentication() throws Exception {
        int listStatus = mockMvc.perform(get("/api/v1/platform/i18n/languages"))
                .andReturn().getResponse().getStatus();
        assertThat(listStatus).isIn(401, 403);

        int createStatus = mockMvc.perform(post("/api/v1/platform/i18n/languages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andReturn().getResponse().getStatus();
        assertThat(createStatus).isIn(401, 403);
    }
}
