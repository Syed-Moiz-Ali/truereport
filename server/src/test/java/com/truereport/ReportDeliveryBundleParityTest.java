package com.truereport;

import com.truereport.delivery.DeliveryMessages;
import com.truereport.reports.ReportMessages;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase C0 Workstream C (server i18n): EN/AR message bundles must stay in parity and
 * report/PDF/delivery templates must not contain literal user-facing text.
 */
class ReportDeliveryBundleParityTest {

    private static final List<String> REPORT_RESULT_CODES = List.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND",
            "NOT_CHECKED", "NOT_APPLICABLE", "COULD_NOT_VERIFY");
    private static final List<String> REPORT_SEVERITY_CODES = List.of(
            "MINOR", "MODERATE", "MAJOR", "SAFETY_CRITICAL");
    private static final List<String> TEMPLATE_FILES = List.of(
            "public-report.html", "print-report.html", "unavailable.html",
            "temporarily-unavailable.html");
    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\d+)[^}]*\\}");
    private static final Pattern TEXT_NODE =
            Pattern.compile("(?s)<([a-zA-Z][^>]*)>([^<>]*)<");

    private static ResourceBundle bundle(String baseName, String language) {
        Locale locale = "ar".equals(language) ? new Locale("ar") : Locale.ENGLISH;
        return ResourceBundle.getBundle(baseName, locale);
    }

    private static Set<String> keys(ResourceBundle bundle) {
        return bundle.keySet().stream().collect(Collectors.toCollection(TreeSet::new));
    }

    private static Set<String> placeholders(String pattern) {
        Matcher matcher = PLACEHOLDER.matcher(pattern);
        Set<String> indices = new HashSet<>();
        while (matcher.find()) {
            indices.add(matcher.group(1));
        }
        return indices;
    }

    @ParameterizedTest
    @ValueSource(strings = {"i18n.report", "i18n.delivery"})
    void bundleKeysMatchEnVsAr(String baseName) {
        assertThat(keys(bundle(baseName, "ar")))
                .as("AR bundle keys must equal EN bundle keys for " + baseName)
                .isEqualTo(keys(bundle(baseName, "en")));
    }

    @ParameterizedTest
    @ValueSource(strings = {"i18n.report", "i18n.delivery"})
    void bundleValuesAreNotBlank(String baseName) {
        for (String language : List.of("en", "ar")) {
            ResourceBundle bundle = bundle(baseName, language);
            for (String key : keys(bundle)) {
                assertThat(bundle.getString(key).strip())
                        .as("%s[%s] must not be blank", baseName, key)
                        .isNotBlank();
            }
        }
    }

    @ParameterizedTest
    @ValueSource(strings = {"i18n.report", "i18n.delivery"})
    void bundlePlaceholdersMatchEnVsAr(String baseName) {
        ResourceBundle en = bundle(baseName, "en");
        for (String key : keys(en)) {
            assertThat(placeholders(bundle(baseName, "ar").getString(key)))
                    .as("placeholders for %s must match EN vs AR", key)
                    .isEqualTo(placeholders(en.getString(key)));
        }
    }

    @Test
    void reportLabelsCoverEveryLabelKeyInBothLanguages() {
        for (String language : List.of("en", "ar")) {
            Map<String, Object> labels = ReportMessages.labels(language);
            ResourceBundle bundle = bundle("i18n.report", language);
            for (String key : ReportMessages.LABEL_KEYS) {
                assertThat(bundle.containsKey(key)).as("bundle key %s", key).isTrue();
                assertThat(labels.get(key))
                        .as("label %s [%s]", key, language)
                        .isEqualTo(bundle.getString(key));
            }
            assertThat(labels.keySet()).containsExactlyInAnyOrderElementsOf(ReportMessages.LABEL_KEYS);
        }
    }

    @Test
    void reportResultAndSeverityAreTranslated() {
        for (String code : REPORT_RESULT_CODES) {
            assertThat(ReportMessages.result("en", code)).isNotBlank().isNotEqualTo(code);
            assertThat(ReportMessages.result("ar", code)).isNotBlank().isNotEqualTo(code);
        }
        for (String code : REPORT_SEVERITY_CODES) {
            assertThat(ReportMessages.severity("en", code)).isNotBlank();
            assertThat(ReportMessages.severity("ar", code)).isNotBlank();
        }
        assertThat(ReportMessages.result("en", "UNKNOWN_CODE")).isEqualTo("UNKNOWN_CODE");
        assertThat(ReportMessages.severity("en", "UNKNOWN_CODE")).isEmpty();
        assertThat(ReportMessages.limitations("en")).hasSize(4).doesNotContainNull();
        assertThat(ReportMessages.limitations("ar")).hasSize(4).doesNotContainNull();
        assertThat(ReportMessages.disclaimer("en")).isNotBlank();
        assertThat(ReportMessages.disclaimer("ar")).isNotBlank();
        assertThat(ReportMessages.photoAlt("en")).isNotBlank();
        assertThat(ReportMessages.photoAlt("ar")).isNotBlank();
    }

    @Test
    void deliveryMessagesUsePlaceholdersInBothLanguages() {
        DeliveryMessages.Message linkEn = DeliveryMessages.forLink("en", "TR-42", "https://x/r/tok");
        assertThat(linkEn.subject()).isNotBlank();
        assertThat(linkEn.body()).contains("TR-42", "https://x/r/tok");
        DeliveryMessages.Message linkAr = DeliveryMessages.forLink("ar", "TR-42", "https://x/r/tok");
        assertThat(linkAr.subject()).isNotBlank();
        assertThat(linkAr.body()).contains("TR-42", "https://x/r/tok");
        DeliveryMessages.Message emailEn = DeliveryMessages.forEmail("en", "TR-42");
        assertThat(emailEn.body()).contains("TR-42", "attached PDF");
        DeliveryMessages.Message emailAr = DeliveryMessages.forEmail("ar", "TR-42");
        assertThat(emailAr.body()).contains("TR-42");
    }

    @Test
    void templatesContainNoLiteralUserFacingText() throws Exception {
        Path dir = Path.of("src/main/resources/templates/report");
        assertThat(dir).isDirectory();
        for (String file : TEMPLATE_FILES) {
            String raw = Files.readString(dir.resolve(file), StandardCharsets.UTF_8);
            assertThat(raw)
                    .as("%s must bind attributes via th:* instead of static literals", file)
                    .doesNotContain(" alt=\"", " data-label=\"");
            String searchable = raw
                    .replaceAll("(?s)<style.*?</style>", "")
                    .replaceAll("(?s)<!--.*?-->", "");
            Matcher matcher = TEXT_NODE.matcher(searchable);
            while (matcher.find()) {
                String attributes = matcher.group(1);
                String text = matcher.group(2).strip();
                if (attributes.contains("th:")) {
                    // Inner text is a render-time fallback; Thymeleaf replaces it.
                    continue;
                }
                if (text.isEmpty() || !text.matches("(?s).*\\p{L}.*")) {
                    continue;
                }
                assertThat(text)
                        .as("literal user-facing text in %s (brand name is the only exception)", file)
                        .isEqualTo("TrueReport");
            }
        }
    }
}
