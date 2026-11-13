package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformTemplateScopeIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void publishedOnlyExcludesUnpublishedTemplates() throws Exception {
        Login platform = login("platform@test.local");
        String publishedId = UUID.randomUUID().toString();
        String draftId = UUID.randomUUID().toString();
        String versionId = UUID.randomUUID().toString();
        insertTemplate(publishedId, "SCOPE-PUBLISHED", "ACTIVE", null);
        insertVersion(versionId, publishedId);
        jdbc.update("""
                UPDATE platform_templates SET current_published_version_id = ?
                WHERE id = ?
                """, versionId, publishedId);
        insertTemplate(draftId, "SCOPE-DRAFT", "ACTIVE", null);

        JsonNode all = getJson(platform,
                "/api/v1/platform/master/templates");
        assertThat(codes(all)).contains("SCOPE-PUBLISHED", "SCOPE-DRAFT");

        JsonNode published = getJson(platform,
                "/api/v1/platform/master/templates?publishedOnly=true");
        assertThat(codes(published)).contains("SCOPE-PUBLISHED");
        assertThat(codes(published)).doesNotContain("SCOPE-DRAFT");
    }

    private void insertVersion(String versionId, String templateId) {
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at,
                     created_at, updated_at)
                VALUES (?, ?, 1, 'PUBLISHED', CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, versionId, templateId);
    }

    private void insertTemplate(String id, String code, String status,
                                String publishedVersionId) {
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name_en, name_ar, description_en, description_ar,
                     status, current_published_version_id, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, '', '', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, code, code, status, publishedVersionId);
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        return objectMapper.readTree(mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    private static java.util.Set<String> codes(JsonNode templates) {
        java.util.Set<String> result = new java.util.HashSet<>();
        templates.forEach(node -> result.add(node.get("code").asText()));
        return result;
    }
}
