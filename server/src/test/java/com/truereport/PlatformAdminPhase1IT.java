package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.identity.UserStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformAdminPhase1IT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    UserRepository userRepository;

    @Autowired
    PasswordEncoder passwordEncoder;

    @Test
    void seedIsIdempotentAndCreatesSixCategoriesThirtyItems() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode first = postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        assertThat(first.get("created").asInt()).isGreaterThan(0);

        assertThat(count("platform_categories")).isEqualTo(6);
        assertThat(count("platform_items")).isEqualTo(30);
        assertThat(count("platform_document_types")).isEqualTo(5);
        assertThat(count("platform_option_sets")).isEqualTo(10);
        assertThat(count("platform_templates")).isEqualTo(1);

        JsonNode second = postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        assertThat(second.get("created").asInt()).isZero();
    }

    @Test
    void categoryWeightCheckAndSeventhCategory() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        mockMvc.perform(get("/api/v1/platform/master/categories/weight-check")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true))
                .andExpect(jsonPath("$.total").value(100));

        JsonNode created = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"CAT-X","nameEn":"Seventh category","nameAr":"التصنيف السابع",
                 "weightPercentage":5,"sortOrder":7}
                """);
        assertThat(created.get("code").asText()).isEqualTo("CAT-X");
        assertThat(created.get("weightPercentage").decimalValue()).isEqualByComparingTo("5");

        mockMvc.perform(get("/api/v1/platform/master/categories/weight-check")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(false))
                .andExpect(jsonPath("$.total").value(105));
    }

    @Test
    void itemConfigBandsEvidenceAndPublishImmutability() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode item = getJson(platform, "/api/v1/platform/master/items?search=BRK-PAD-01");
        String itemId = item.get(0).get("id").asText();

        JsonNode draft = postJson(platform,
                "/api/v1/platform/master/items/" + itemId + "/versions", "{}");
        JsonNode version = draft.get("versions").get(0);
        String versionId = version.get("id").asText();
        assertThat(version.get("status").asText()).isEqualTo("DRAFT");

        putJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/bands", """
                {"bands":[
                  {"resultCode":"DEFECT_FOUND","minScore":0,"maxScore":59,"defaultScore":0,
                   "criteriaEn":"Fail","criteriaAr":"فشل"},
                  {"resultCode":"ATTENTION_RECOMMENDED","minScore":60,"maxScore":84,"defaultScore":70,
                   "criteriaEn":"Attention","criteriaAr":"انتباه"},
                  {"resultCode":"NO_ISSUE_OBSERVED","minScore":85,"maxScore":100,"defaultScore":100,
                   "criteriaEn":"Pass","criteriaAr":"نجاح"}
                ]}
                """);

        putJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/evidence-rules", """
                {"rules":[
                  {"resultCode":"NO_ISSUE_OBSERVED","minPhotos":1,"minVideos":1,"minNotesChars":0,
                   "requiredEvidenceType":"PHOTO"},
                  {"resultCode":"ATTENTION_RECOMMENDED","minPhotos":1,"minVideos":1,"minNotesChars":15,
                   "requiredEvidenceType":"PHOTO"},
                  {"resultCode":"DEFECT_FOUND","minPhotos":2,"minVideos":1,"minNotesChars":15,
                   "requiredEvidenceType":"PHOTO"}
                ]}
                """);

        putJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/measurement-bands", """
                {"bands":[
                  {"fieldCode":"MEASUREMENT","unitCode":"MM","direction":"HIGHER_IS_BETTER",
                   "minValue":0,"maxValue":2.999,"resultCode":"DEFECT_FOUND","defaultScore":0,
                   "labelEn":"Below minimum","labelAr":"أقل من الحد الأدنى","sortOrder":1},
                  {"fieldCode":"MEASUREMENT","unitCode":"MM","direction":"HIGHER_IS_BETTER",
                   "minValue":3.0,"maxValue":5.499,"resultCode":"ATTENTION_RECOMMENDED","defaultScore":70,
                   "labelEn":"Worn","labelAr":"متآكل","sortOrder":2},
                  {"fieldCode":"MEASUREMENT","unitCode":"MM","direction":"HIGHER_IS_BETTER",
                   "minValue":5.5,"maxValue":99,"resultCode":"NO_ISSUE_OBSERVED","defaultScore":100,
                   "labelEn":"Within spec","labelAr":"ضمن المواصفات","sortOrder":3}
                ]}
                """);

        putJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/issue-fields", """
                {"fields":[
                  {"fieldCode":"ISSUE_TYPE","labelEn":"Issue Type","labelAr":"نوع العطل",
                   "inputType":"SELECT","optionSetCode":"ISSUE_TYPE","required":true,
                   "requiredForStatuses":["ATTENTION_RECOMMENDED","DEFECT_FOUND"],"sortOrder":1}
                ]}
                """);

        JsonNode published = postJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/publish", "{}");
        assertThat(published.get("status").asText()).isEqualTo("PUBLISHED");

        mockMvc.perform(put("/api/v1/platform/master/items/" + itemId
                                + "/versions/" + versionId + "/bands")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bands\":[]}"))
                .andExpect(status().isConflict());
    }

    @Test
    void optionValueInUseCannotBeRetiredWithoutReplacement() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode sets = getJson(platform, "/api/v1/platform/master/option-sets");
        JsonNode location = null;
        for (JsonNode set : sets) {
            if ("LOCATION".equals(set.get("code").asText())) {
                location = set;
            }
        }
        assertThat(location).isNotNull();
        String setId = location.get("id").asText();
        String frontLeftId = null;
        for (JsonNode value : location.get("values")) {
            if ("FRONT_LEFT".equals(value.get("code").asText())) {
                frontLeftId = value.get("id").asText();
            }
        }
        assertThat(frontLeftId).isNotNull();

        mockMvc.perform(post("/api/v1/platform/master/option-sets/" + setId
                                + "/values/" + frontLeftId + "/retire")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("OPTION_IN_USE"));

        mockMvc.perform(post("/api/v1/platform/master/option-sets/" + setId
                                + "/values/" + frontLeftId + "/retire")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"replacementCode\":\"FRONT\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RETIRED"));
    }

    @Test
    void templateWeightPreviewAndMakerChecker() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode items = getJson(platform, "/api/v1/platform/master/items?search=BRK-PAD-01");
        String itemId = items.get(0).get("id").asText();
        JsonNode detail = getJson(platform, "/api/v1/platform/master/items/" + itemId);
        String versionId = detail.get("versions").get(0).get("id").asText();

        JsonNode template = postJson(platform, "/api/v1/platform/master/templates", """
                {"code":"TPL-TEST-01","nameEn":"Test template","nameAr":"قالب اختبار",
                 "descriptionEn":"Test","descriptionAr":"اختبار"}
                """);
        String templateId = template.get("id").asText();
        String templateVersionId = template.get("versions").get(0).get("id").asText();

        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + templateVersionId + "/items", """
                {"items":[{"itemVersionId":"%s","included":true,"sortOrder":1}]}
                """.formatted(versionId));

        mockMvc.perform(get("/api/v1/platform/master/templates/" + templateId
                                + "/versions/" + templateVersionId + "/weight-preview")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rows.length()").value(1));

        JsonNode published = postJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + templateVersionId + "/publish", "{}");
        assertThat(published.get("versions").get(0).get("status").asText())
                .isEqualTo("PENDING_APPROVAL");

        mockMvc.perform(post("/api/v1/platform/master/templates/" + templateId
                                + "/versions/" + templateVersionId + "/approve")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("MAKER_CHECKER_SELF_APPROVAL"));

        Login second = createSecondPlatformAdmin();
        mockMvc.perform(post("/api/v1/platform/master/templates/" + templateId
                                + "/versions/" + templateVersionId + "/approve")
                        .header("Authorization", bearer(second)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.versions[0].status").value("PUBLISHED"));
    }

    @Test
    void scoringDocumentTypesAndGovernanceWork() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode scoring = getJson(platform, "/api/v1/platform/scoring-rules");
        String ruleId = scoring.get("rule").get("id").asText();

        mockMvc.perform(put("/api/v1/platform/scoring-rules/" + ruleId + "/grade-boundaries")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"boundaries":[
                                  {"gradeCode":"A","minScore":90,"maxScore":100,"labelEn":"Excellent",
                                   "labelAr":"ممتاز","sortOrder":1,"approved":false},
                                  {"gradeCode":"B","minScore":80,"maxScore":95,"labelEn":"Good",
                                   "labelAr":"جيد","sortOrder":2,"approved":false}
                                ]}
                                """))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("GRADE_BOUNDARIES_INVALID"));

        putJson(platform, "/api/v1/platform/scoring-rules/" + ruleId + "/grade-boundaries", """
                {"boundaries":[
                  {"gradeCode":"A","minScore":90,"maxScore":100,"labelEn":"Excellent",
                   "labelAr":"ممتاز","sortOrder":1,"approved":false},
                  {"gradeCode":"B","minScore":80,"maxScore":89,"labelEn":"Good",
                   "labelAr":"جيد","sortOrder":2,"approved":false},
                  {"gradeCode":"C","minScore":65,"maxScore":79,"labelEn":"Fair",
                   "labelAr":"مقبول","sortOrder":3,"approved":false},
                  {"gradeCode":"D","minScore":0,"maxScore":64,"labelEn":"Poor",
                   "labelAr":"ضعيف","sortOrder":4,"approved":false}
                ]}
                """);

        JsonNode documentTypes = getJson(platform, "/api/v1/platform/document-types");
        assertThat(documentTypes.size()).isEqualTo(5);

        postJson(platform, "/api/v1/platform/document-types", """
                {"code":"EXTRA_REPORT","nameEn":"Extra report","nameAr":"تقرير إضافي",
                 "required":false,"sortOrder":9}
                """);

        mockMvc.perform(get("/api/v1/platform/config-health")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.checks").isArray());

        JsonNode categories = getJson(platform, "/api/v1/platform/master/categories");
        String categoryId = categories.get(0).get("id").asText();
        mockMvc.perform(get("/api/v1/platform/master/CATEGORY/" + categoryId + "/impact")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entityType").value("CATEGORY"));
    }

    @Test
    void roleDenialAndLocalizedErrors() throws Exception {
        Login technician = login("tech.a@test.local");
        mockMvc.perform(post("/api/v1/platform/seed/default-checklist")
                        .header("Authorization", bearer(technician)))
                .andExpect(status().isForbidden());

        Login platform = login("platform@test.local");
        mockMvc.perform(post("/api/v1/platform/master/option-sets")
                        .header("Authorization", bearer(platform))
                        .header("Accept-Language", "ar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CODE_REQUIRED"))
                .andExpect(jsonPath("$.messageAr").isNotEmpty())
                .andExpect(jsonPath("$.messageEn").isNotEmpty());

        mockMvc.perform(get("/api/v1/i18n/languages"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").exists());

        mockMvc.perform(get("/api/v1/i18n/languages")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").exists());

        mockMvc.perform(get("/api/v1/i18n/me")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.language").value("en"));
    }

    private Login createSecondPlatformAdmin() {
        User user = new User("platform2@test.local",
                passwordEncoder.encode(TestDataFactory.PASSWORD), "Platform Admin Two");
        user.setStatus(UserStatus.ACTIVE);
        user.setPlatformAdmin(true);
        userRepository.save(user);
        try {
            return login("platform2@test.local");
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
    }

    private int count(String table) {
        Integer value = jdbc.queryForObject("SELECT COUNT(*) FROM " + table, Integer.class);
        return value == null ? 0 : value;
    }

    private String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(post(path)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(put(path)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
