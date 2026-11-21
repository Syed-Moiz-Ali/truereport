package com.truereport.reports;

import org.junit.jupiter.api.Test;

import java.io.InputStream;
import java.util.Properties;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class ReportMessagesLocaleTest {

    @Test
    void spanishCatalogCoversEveryEnglishKey() throws Exception {
        Properties english = load("i18n/report_en.properties");
        Properties spanish = load("i18n/report_es.properties");

        assertThat(spanish.stringPropertyNames())
                .as("report_es must cover every report_en key")
                .containsAll(english.stringPropertyNames());
    }

    @Test
    void englishAndSpanishLabelsResolveByLocale() {
        assertThat(ReportMessages.labels("en").get("title"))
                .isEqualTo("Vehicle inspection report");
        assertThat(ReportMessages.labels("es").get("title"))
                .isEqualTo("Informe de inspección del vehículo");
        assertThat(ReportMessages.result("es", "DEFECT_FOUND"))
                .isEqualTo("Defecto encontrado");
        assertThat(ReportMessages.severity("es", "SAFETY_CRITICAL"))
                .isEqualTo("Seguridad crítica");
    }

    @Test
    void categorySummaryLabelsResolvePerLocale() {
        assertThat(ReportMessages.label("en", "categorySummary.passedMany"))
                .isEqualTo("{0} Categories Passed");
        assertThat(ReportMessages.label("es", "categorySummary.passedMany"))
                .isEqualTo("{0} categorías aprobadas");
        assertThat(ReportMessages.label("es", "categorySummary.attentionOne"))
                .isEqualTo("{0} categoría necesita atención");
        assertThat(ReportMessages.label("es", "categoryStatus.attention"))
                .isEqualTo("Requiere servicio");
        assertThat(ReportMessages.label("en", "categorySummary.separator"))
                .isEqualTo("\u2022");
        // French is partial; the new keys fall back per key instead of failing.
        assertThat(ReportMessages.label("fr", "categorySummary.passedMany"))
                .isEqualTo("{0} Categories Passed");
    }

    @Test
    void frenchUsesPresentKeysAndFallsBackPerKey() {
        assertThat(ReportMessages.labels("fr").get("title"))
                .isEqualTo("Rapport d'inspection du véhicule");
        assertThat(ReportMessages.labels("fr").get("summary"))
                .isEqualTo("Résumé de l'inspection");
        // report_fr.properties is intentionally partial; missing keys fall back to English.
        assertThat(ReportMessages.labels("fr").get("disclaimer"))
                .isEqualTo(ReportMessages.labels("en").get("disclaimer"));
    }

    @Test
    void deliverySpanishResolvesAndFallsBack() {
        assertThat(com.truereport.delivery.DeliveryMessages.forLink("es", "TR-1", "https://x")
                .subject()).isEqualTo("Informe de inspección del vehículo listo");
        assertThat(com.truereport.delivery.DeliveryMessages.forLink("fr", "TR-1", "https://x")
                .subject()).isEqualTo("Vehicle inspection report ready");
    }

    private static Properties load(String path) throws Exception {
        Properties properties = new Properties();
        try (InputStream input = ReportMessagesLocaleTest.class.getClassLoader()
                .getResourceAsStream(path)) {
            assertThat(input).as(path).isNotNull();
            properties.load(input);
        }
        Set<String> keys = properties.stringPropertyNames();
        assertThat(keys).isNotEmpty();
        return properties;
    }
}
