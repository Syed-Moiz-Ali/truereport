package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TranslationGlossaryIT extends IntegrationTestBase {

    private static final String BASE = "/api/v1/platform/i18n/glossary";

    @Test
    void glossaryCrudAndSeedTerms() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode seeded = getJson(platform, BASE + "?sourceLang=en&targetLang=es");
        JsonNode brakePad = findTerm(seeded, "brake pad");
        assertThat(brakePad).isNotNull();
        assertThat(brakePad.get("translation").asText()).isEqualTo("pastilla de freno");

        String term = "control arm " + UUID.randomUUID().toString().substring(0, 6);
        JsonNode created = postJson(platform, BASE, """
                {"sourceLang":"en","targetLang":"es","term":"%s",
                 "translation":"brazo de control","caseSensitive":true,"locked":true}
                """.formatted(term));
        String id = created.get("id").asText();
        assertThat(created.get("locked").asBoolean()).isTrue();
        assertThat(created.get("caseSensitive").asBoolean()).isTrue();

        JsonNode updated = putJson(platform, BASE + "/" + id, """
                {"translation":"brazo de suspensión"}
                """);
        assertThat(updated.get("translation").asText()).isEqualTo("brazo de suspensión");

        mockMvc.perform(delete(BASE + "/" + id)
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isNoContent());
        mockMvc.perform(delete(BASE + "/" + id)
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isNotFound());
    }

    @Test
    void glossaryValidationRejectsUnknownLanguageAndMissingFields() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(post(BASE)
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLang":"en","targetLang":"de","term":"x","translation":"y"}
                                """))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("GLOSSARY_INVALID"));

        mockMvc.perform(post(BASE)
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLang":"en","targetLang":"es","term":"","translation":"y"}
                                """))
                .andExpect(status().isUnprocessableEntity());
    }

    private JsonNode findTerm(JsonNode rows, String term) {
        for (JsonNode row : rows) {
            if (term.equals(row.get("term").asText())) {
                return row;
            }
        }
        return null;
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
