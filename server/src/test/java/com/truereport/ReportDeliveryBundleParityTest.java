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
 * Server i18n: the report and delivery bundles are English-only and must stay
 * complete, while templates must not contain literal user-facing text.
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

    private static ResourceBundle bundle(String baseName) {
        return ResourceBundle.getBundle(baseName, Locale.ENGLISH);
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
    void bundleValuesAreNotBlank(String baseName) {
        ResourceBundle bundle = bundle(baseName);
        for (String key : keys(bundle)) {
            assertThat(bundle.getString(key).strip())
                    .as("%s[%s] must not be blank", baseName, key)
                    .isNotBlank();
        }
    }

    @ParameterizedTest
    @ValueSource(strings = {"i18n.report", "i18n.delivery"})
    void englishBundlesHaveNoOtherLocaleVariants(String baseName) {
        // Arabic bundles were removed; only the English bundle may ship.
        assertThat(getClass().getResourceAsStream("/" + baseName.replace('.', '/') + "_ar.properties"))
                .isNull();
    }

    @Test
    void reportLabelsCoverEveryLabelKey() {
        Map<String, Object> labels = ReportMessages.labels("en");
        ResourceBundle bundle = bundle("i18n.report");
        for (String key : ReportMessages.LABEL_KEYS) {
            assertThat(bundle.containsKey(key)).as("bundle key %s", key).isTrue();
            assertThat(labels.get(key)).as("label %s", key).isEqualTo(bundle.getString(key));
        }
        assertThat(labels.keySet()).containsExactlyInAnyOrderElementsOf(ReportMessages.LABEL_KEYS);
    }

    @Test
    void reportResultAndSeverityAreTranslated() {
        for (String code : REPORT_RESULT_CODES) {
            assertThat(ReportMessages.result("en", code)).isNotBlank().isNotEqualTo(code);
        }
        for (String code : REPORT_SEVERITY_CODES) {
            assertThat(ReportMessages.severity("en", code)).isNotBlank();
        }
        assertThat(ReportMessages.result("en", "UNKNOWN_CODE")).isEqualTo("UNKNOWN_CODE");
        assertThat(ReportMessages.severity("en", "UNKNOWN_CODE")).isEmpty();
        assertThat(ReportMessages.limitations("en")).hasSize(4).doesNotContainNull();
        assertThat(ReportMessages.disclaimer("en")).isNotBlank();
        assertThat(ReportMessages.photoAlt("en")).isNotBlank();
    }

    @Test
    void nonEnglishLanguageArgumentsUseTheirCatalogAndFallBack() {
        assertThat(ReportMessages.labels("es").get("title"))
                .isEqualTo("Informe de inspección del vehículo");
        assertThat(DeliveryMessages.forEmail("es", "TR-42").body())
                .contains("Su informe de inspección");
        // A language with no catalog at all falls back to English per key.
        assertThat(ReportMessages.labels("de"))
                .containsExactlyInAnyOrderEntriesOf(ReportMessages.labels("en"));
    }

    @Test
    void deliveryMessagesUsePlaceholders() {
        DeliveryMessages.Message link = DeliveryMessages.forLink("en", "TR-42", "https://x/r/tok");
        assertThat(link.subject()).isNotBlank();
        assertThat(link.body()).contains("TR-42", "https://x/r/tok");
        DeliveryMessages.Message email = DeliveryMessages.forEmail("en", "TR-42");
        assertThat(email.body()).contains("TR-42", "attached PDF");
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
