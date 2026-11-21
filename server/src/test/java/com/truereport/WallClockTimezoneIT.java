package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.TimeZone;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * A zone-less value is UTC wall time to every client. The API must round-trip
 * {@link LocalDateTime} unchanged even when the JVM zone is Asia/Calcutta.
 *
 * <p>This test forces a non-UTC JVM default. With {@code getTimestamp()} the
 * returned value moves by the JVM offset; with
 * {@code getObject(..., LocalDateTime.class)} it does not.</p>
 */
class WallClockTimezoneIT extends IntegrationTestBase {

    private static final String JOBS = "/api/v1/workshop/jobs";
    private static final String TECHNICIAN_JOBS = "/api/v1/technician/jobs";

    @Autowired
    JdbcTemplate jdbc;

    private TimeZone originalZone;

    @BeforeEach
    void forceJvmZone() {
        originalZone = TimeZone.getDefault();
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Calcutta"));
    }

    @AfterEach
    void restoreJvmZone() {
        TimeZone.setDefault(originalZone);
    }

    @Test
    void scheduledAndLifecycleTimesRoundTripUnchanged() throws Exception {
        assertThat(ZoneId.systemDefault().getId()).isEqualTo("Asia/Calcutta");
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        String templateVersionId = PlatformJobFixtures.templateVersion(jdbc);

        MvcResult created = mockMvc.perform(post(JOBS)
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"templateVersionId":"%s","customerName":"Wall Clock",
                                 "customerPhone":"+971500000000",
                                 "customerEmail":"wallclock@test.local",
                                 "vehicleVin":"1HGCM82633A004352","vehicleMake":"Toyota",
                                 "vehicleModel":"Corolla","vehicleYear":2022,
                                 "vehiclePlate":"TZ-12345","odometerValue":12000,
                                 "odometerUnit":"KM","transmission":"AUTOMATIC",
                                 "fuelType":"PETROL","preferredLanguage":"en",
                                 "scheduledAt":"2026-11-21T12:00:00","consentGranted":true,
                                 "assignedTechnicianId":"%s"}
                                """.formatted(templateVersionId, fixture.techA().getId())))
                .andExpect(status().isCreated())
                .andReturn();
        String jobId = objectMapper.readTree(created.getResponse().getContentAsString())
                .get("id").asText();

        // Fixed wall-clock values in the storage format; no zone conversion.
        jdbc.update("""
                UPDATE platform_jobs
                SET started_at = ?, completed_at = ?, published_at = ?, created_at = ?
                WHERE id = ?
                """,
                LocalDateTime.parse("2026-11-21T12:05:30"),
                LocalDateTime.parse("2026-11-21T13:45:10"),
                LocalDateTime.parse("2026-11-21T14:00:00"),
                LocalDateTime.parse("2026-11-20T08:15:30"), jobId);

        JsonNode job = getJson(admin, JOBS + "/" + jobId);
        assertWallClock(job.get("scheduledAt").asText(), "2026-11-21T12:00:00");
        assertWallClock(job.get("startedAt").asText(), "2026-11-21T12:05:30");
        assertWallClock(job.get("completedAt").asText(), "2026-11-21T13:45:10");
        assertWallClock(job.get("publishedAt").asText(), "2026-11-21T14:00:00");
        assertWallClock(job.get("createdAt").asText(), "2026-11-20T08:15:30");

        JsonNode technicianJobs = getJson(technician, TECHNICIAN_JOBS);
        JsonNode row = null;
        for (JsonNode item : technicianJobs.get("items")) {
            if (jobId.equals(item.get("id").asText())) {
                row = item;
            }
        }
        assertThat(row).as("job assigned to the technician").isNotNull();
        assertWallClock(row.get("scheduledAt").asText(), "2026-11-21T12:00:00");
        assertWallClock(row.get("startedAt").asText(), "2026-11-21T12:05:30");
    }

    private static void assertWallClock(String actual, String expected) {
        assertThat(actual).isNotBlank();
        assertThat(LocalDateTime.parse(actual))
                .as("wall-clock value must not move with the JVM zone")
                .isEqualTo(LocalDateTime.parse(expected));
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
