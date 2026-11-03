package com.truereport;

import com.truereport.shared.uuid.UuidBinaryConverter;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FoundationIT extends IntegrationTestBase {

    @Autowired
    WorkshopRepository workshopRepository;

    @Autowired
    JdbcTemplate jdbcTemplate;

    @Test
    void uuidV7RoundTripsThroughBinary16() {
        Workshop saved = workshopRepository.save(new Workshop("UUID round-trip"));
        workshopRepository.flush();
        UUID id = saved.getId();

        assertThat(id).isNotNull();
        byte[] storedId = new UuidBinaryConverter().convertToDatabaseColumn(id);
        byte[] bytes = jdbcTemplate.queryForObject(
                "SELECT id FROM workshops WHERE id = ?",
                byte[].class,
                storedId);
        assertThat(bytes).hasSize(16);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT OCTET_LENGTH(id) FROM workshops WHERE id = ?",
                Integer.class,
                storedId)).isEqualTo(16);
        assertThat(workshopRepository.findById(id)).isPresent();
    }

    @Test
    void healthAndOpenApiAreAvailable() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("TrueReport API")));
    }

    @Test
    void unavailablePageIsNeutralAndDoesNotEchoTheToken() throws Exception {
        mockMvc.perform(get("/r/unavailable"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Robots-Tag", "noindex, nofollow"))
                .andExpect(header().string("Referrer-Policy", "no-referrer"))
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("This link is unavailable")))
                .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("r/unavailable"))));

        mockMvc.perform(get("/r/secret-token-value"))
                .andExpect(status().isNotFound())
                .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("secret-token-value"))));
    }
}
