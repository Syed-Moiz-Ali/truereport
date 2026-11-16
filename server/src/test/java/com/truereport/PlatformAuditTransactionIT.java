package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.identity.UserStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)
class PlatformAuditTransactionIT {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    UserRepository users;

    @Autowired
    PasswordEncoder passwordEncoder;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void auditEventsQueryWorksOutsideTransaction() throws Exception {
        String email = "audit.outside.tx." + UUID.randomUUID() + "@test.local";
        User user = new User(email, passwordEncoder.encode(TestDataFactory.PASSWORD),
                "Audit Outside Tx");
        user.setStatus(UserStatus.ACTIVE);
        user.setPlatformAdmin(true);
        user = users.save(user);
        String action = "AUDIT_OUTSIDE_TX_" + UUID.randomUUID();
        jdbc.update("""
                INSERT INTO platform_audit_events
                    (id, actor_user_id, actor_role, action_code, entity_type,
                     entity_id, reason, before_json, after_json, trace_id,
                     ip_address, occurred_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?, NULL, NULL, CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), user.getId().toString(),
                "PLATFORM_ADMIN", action, "AUDIT_TEST",
                UUID.randomUUID().toString(), "regression", "{}");
        try {
            MvcResult login = mockMvc.perform(post("/api/v1/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"email":"%s","password":"%s"}
                                    """.formatted(email, TestDataFactory.PASSWORD)))
                    .andExpect(status().isOk())
                    .andReturn();
            String token = objectMapper
                    .readTree(login.getResponse().getContentAsString())
                    .get("accessToken").asText();

            MvcResult result = mockMvc.perform(get("/api/v1/platform/audit-events")
                            .param("action", action)
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andReturn();
            JsonNode events = objectMapper.readTree(
                    result.getResponse().getContentAsString());
            assertThat(events.isArray()).isTrue();
            assertThat(events.toString()).contains(action);
        } finally {
            jdbc.update("DELETE FROM platform_audit_events WHERE action_code = ?", action);
            jdbc.update("DELETE FROM audit_events WHERE actor_user_id = ?", user.getId());
            jdbc.update("DELETE FROM refresh_tokens WHERE user_id = ?", user.getId());
            jdbc.update("DELETE FROM users WHERE id = ?", user.getId());
        }
    }
}
