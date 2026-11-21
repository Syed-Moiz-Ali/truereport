package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Pre-inspection vehicle hero photo lifecycle, verification and authorization.
 */
class VehiclePhotoIT extends IntegrationTestBase {

    private static final String JOBS = "/api/v1/technician/jobs";
    private static final byte[] PNG = Base64.getDecoder().decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    PlatformJobStore store;

    @Autowired
    PlatformJobTokenService tokens;

    @Test
    void initUploadCompleteGetContentAndDelete() throws Exception {
        Login tech = login("tech.a@test.local");
        String jobId = assignedJob("IN_PROGRESS");

        mockMvc.perform(get(path(jobId)).header("Authorization", bearer(tech)))
                .andExpect(status().isNotFound());

        String sha = sha256(PNG);
        JsonNode init = json(init(tech, jobId, "image/png", PNG.length, sha)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING_UPLOAD"))
                .andExpect(jsonPath("$.mime").value("image/png"))
                .andExpect(jsonPath("$.bytes").value(PNG.length)));
        String photoId = init.get("id").asText();

        upload(tech, jobId, photoId, PNG)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UPLOADED"))
                .andExpect(jsonPath("$.sha256").value(sha));

        MvcResult completed = mockMvc.perform(post(path(jobId) + "/" + photoId + "/complete")
                        .header("Authorization", bearer(tech)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("READY"))
                .andReturn();
        assertThat(LocalDateTime.parse(objectMapper.readTree(
                completed.getResponse().getContentAsString()).get("capturedAt").asText()))
                .isEqualTo(LocalDateTime.parse("2026-11-22T10:00:00"));

        mockMvc.perform(get(path(jobId)).header("Authorization", bearer(tech)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(photoId))
                .andExpect(jsonPath("$.status").value("READY"))
                .andExpect(jsonPath("$.sha256").value(sha));

        MvcResult content = mockMvc.perform(get(path(jobId) + "/content")
                        .header("Authorization", bearer(tech)))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", MediaType.IMAGE_PNG_VALUE))
                .andExpect(header().string("Cache-Control", "no-store"))
                .andReturn();
        assertThat(content.getResponse().getContentAsByteArray()).isEqualTo(PNG);

        mockMvc.perform(delete(path(jobId)).header("Authorization", bearer(tech)))
                .andExpect(status().isNoContent());
        mockMvc.perform(get(path(jobId)).header("Authorization", bearer(tech)))
                .andExpect(status().isNotFound());
        mockMvc.perform(get(path(jobId) + "/content").header("Authorization", bearer(tech)))
                .andExpect(status().isNotFound());
    }

    @Test
    void instantCapturedAtIsStoredAsDubaiWallTime() throws Exception {
        Login tech = login("tech.a@test.local");
        String jobId = assignedJob("IN_PROGRESS");

        JsonNode init = json(initAt(tech, jobId, "image/png", PNG.length, sha256(PNG),
                "2026-11-22T06:00:00Z")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING_UPLOAD")));
        assertThat(init.get("id").asText()).isNotBlank();

        JsonNode stored = json(mockMvc.perform(get(path(jobId))
                        .header("Authorization", bearer(tech)))
                .andExpect(status().isOk()));
        assertThat(LocalDateTime.parse(stored.get("capturedAt").asText()))
                .isEqualTo(LocalDateTime.parse("2026-11-22T10:00:00"));
    }

    @Test
    void wrongHashIsRejectedAsCorrupt() throws Exception {
        Login tech = login("tech.a@test.local");
        String jobId = assignedJob("IN_PROGRESS");
        byte[] other = new byte[PNG.length];
        System.arraycopy(PNG, 0, other, 0, PNG.length);
        other[other.length - 1] = (byte) (other[other.length - 1] ^ 0x7f);

        JsonNode init = json(init(tech, jobId, "image/png", PNG.length, sha256(other))
                .andExpect(status().isCreated()));

        upload(tech, jobId, init.get("id").asText(), PNG)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("VEHICLE_PHOTO_CORRUPT"));
    }

    @Test
    void secondInitReplacesThePreviousPhoto() throws Exception {
        Login tech = login("tech.a@test.local");
        String jobId = assignedJob("IN_PROGRESS");
        String firstId = json(init(tech, jobId, "image/png", PNG.length, sha256(PNG))
                .andExpect(status().isCreated())).get("id").asText();
        upload(tech, jobId, firstId, PNG).andExpect(status().isOk());

        String secondId = json(init(tech, jobId, "image/webp", PNG.length, sha256(PNG))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mime").value("image/webp")))
                .get("id").asText();

        assertThat(secondId).isNotEqualTo(firstId);
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_job_media
                WHERE job_id = ? AND kind = 'VEHICLE_HERO'
                """, Integer.class, jobId)).isEqualTo(1);
        mockMvc.perform(get(path(jobId)).header("Authorization", bearer(tech)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(secondId))
                .andExpect(jsonPath("$.status").value("PENDING_UPLOAD"));
    }

    @Test
    void otherTechniciansCannotReadOrWrite() throws Exception {
        String jobId = assignedJob("IN_PROGRESS");
        Login other = login("tech.c@test.local");

        mockMvc.perform(get(path(jobId)).header("Authorization", bearer(other)))
                .andExpect(status().isNotFound());
        init(other, jobId, "image/png", PNG.length, sha256(PNG))
                .andExpect(status().isNotFound());
        mockMvc.perform(delete(path(jobId)).header("Authorization", bearer(other)))
                .andExpect(status().isNotFound());
    }

    @Test
    void publishedJobRejectsVehiclePhotoChanges() throws Exception {
        String jobId = assignedJob("PUBLISHED");
        Login tech = login("tech.a@test.local");

        init(tech, jobId, "image/png", PNG.length, sha256(PNG))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("JOB_STATE_INVALID"));
    }

    @Test
    void invalidMimeAndOversizeAreRejected() throws Exception {
        String jobId = assignedJob("ASSIGNED");
        Login tech = login("tech.a@test.local");

        init(tech, jobId, "image/gif", PNG.length, sha256(PNG))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("VEHICLE_PHOTO_INVALID"));
        init(tech, jobId, "image/png", 8L * 1024L * 1024L + 1L, sha256(PNG))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("VEHICLE_PHOTO_INVALID"));
    }

    // ------------------------------------------------------------------ helpers

    private String assignedJob(String status) {
        PlatformJobFixtures.Fixture seeded = PlatformJobFixtures.publishedJob(
                jdbc, store, tokens, fixture.workshopA().getId(), fixture.adminA().getId(),
                "+971500009900", "photo@test.local", "en", true, status, "{}");
        jdbc.update("UPDATE platform_jobs SET assigned_technician_id = ? WHERE id = ?",
                fixture.techA().getId().toString(), seeded.jobId());
        return seeded.jobId();
    }

    private org.springframework.test.web.servlet.ResultActions init(
            Login login, String jobId, String mime, long bytes, String sha) throws Exception {
        return initAt(login, jobId, mime, bytes, sha, "2026-11-22T10:00:00");
    }

    private org.springframework.test.web.servlet.ResultActions initAt(
            Login login, String jobId, String mime, long bytes, String sha,
            String capturedAt) throws Exception {
        return mockMvc.perform(post(path(jobId))
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"mime":"%s","bytes":%d,"sha256":"%s",
                         "capturedAt":"%s",
                         "captureSource":"CAMERA","deviceId":null}
                        """.formatted(mime, bytes, sha, capturedAt)));
    }

    private org.springframework.test.web.servlet.ResultActions upload(
            Login login, String jobId, String photoId, byte[] bytes) throws Exception {
        return mockMvc.perform(put(path(jobId) + "/" + photoId + "/content")
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .content(bytes));
    }

    private static String path(String jobId) {
        return JOBS + "/" + jobId + "/vehicle-photo";
    }

    private static String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }

    private JsonNode json(
            org.springframework.test.web.servlet.ResultActions actions) throws Exception {
        return objectMapper.readTree(actions.andReturn().getResponse()
                .getContentAsString(StandardCharsets.UTF_8));
    }

    private static String sha256(byte[] bytes) throws Exception {
        return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(bytes));
    }
}
