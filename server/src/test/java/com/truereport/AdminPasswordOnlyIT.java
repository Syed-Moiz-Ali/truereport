package com.truereport;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminPasswordOnlyIT extends IntegrationTestBase {

    @Test
    void adminsSignInWithPasswordOnlyAndTotpEndpointsAreDormant() throws Exception {
        Login admin = login("admin.a@test.local");
        assertThat(admin.accessToken()).isNotBlank();
        mockMvc.perform(post("/api/v1/auth/2fa/enroll")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TOTP_DISABLED"));
        mockMvc.perform(post("/api/v1/auth/2fa/recovery-codes")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TOTP_DISABLED"));
    }
}
