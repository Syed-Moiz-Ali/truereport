package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Guardrail for the Flutter key generator: {@code i18n/schema.json} is generated
 * from the ARB metadata and must match the catalogs the server serves exactly.
 *
 * <p>Any key added to or removed from an ARB catalog without regenerating the
 * schema fails this test in both directions, so the generator can never
 * reference a key the server does not serve (or miss one it does).</p>
 *
 * <p>Key shapes are also enforced: backend-resolved {@code platform_admin} and
 * {@code common} keys are dotted and hierarchical, while the UI-only
 * {@code workshop_admin} and {@code technician} keys are flat camelCase.</p>
 */
class I18nSchemaDriftTest {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");
    private static final Pattern DOTTED_KEY =
            Pattern.compile("^[a-z][A-Za-z0-9]*(\\.[a-z][A-Za-z0-9]*)+$");
    private static final Pattern FLAT_CAMEL_KEY =
            Pattern.compile("^[a-z][A-Za-z0-9]*$");

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void catalogSplitMatchesTheContract() throws Exception {
        JsonNode commonEn = read("common/en.json");
        JsonNode commonEs = read("common/es.json");
        JsonNode workshopEn = read("workshop_admin/en.json");
        JsonNode technicianEn = read("technician/en.json");
        JsonNode workshopEs = read("workshop_admin/es.json");
        JsonNode technicianEs = read("technician/es.json");

        assertThat(commonEn.size()).isEqualTo(59);
        assertThat(keys(commonEn)).allMatch(key -> key.indexOf('.') > 0);
        assertThat(commonEs.size()).isZero();

        assertThat(workshopEn.size()).isEqualTo(1237);
        assertThat(keys(workshopEn)).noneMatch(key -> key.indexOf('.') > 0);
        assertThat(workshopEn).isEqualTo(technicianEn);

        assertThat(workshopEs.size()).isEqualTo(62);
        assertThat(workshopEs).isEqualTo(technicianEs);
    }

    @Test
    void schemaKeysMatchTheArbCatalogsExactly() throws Exception {
        Set<String> schema = keys(read("schema.json").get("keys"));
        Set<String> workshop = keys(read("workshop_admin/en.json"));
        Set<String> technician = keys(read("technician/en.json"));

        assertThat(workshop)
                .as("workshop and technician ARB catalogs must stay identical")
                .isEqualTo(technician);

        // Exact parity in both directions: a new catalog key needs a regenerated
        // schema, and every schema key must have a served value.
        assertThat(schema).isEqualTo(workshop);
    }

    @Test
    void everySchemaKeyIsServedInEveryClientBundle() throws Exception {
        Set<String> schema = keys(read("schema.json").get("keys"));
        Set<String> common = keys(read("common/en.json"));

        for (String client : new String[]{"workshop_admin", "technician"}) {
            Set<String> served = new HashSet<>(common);
            served.addAll(keys(read(client + "/en.json")));
            assertThat(served)
                    .as("%s bundle must serve every schema key", client)
                    .containsAll(schema);
        }
    }

    @Test
    void schemaPlaceholdersExistInTheEnglishText() throws Exception {
        JsonNode schema = read("schema.json").get("keys");
        Map<String, String> values = new LinkedHashMap<>();
        read("workshop_admin/en.json").fields().forEachRemaining(entry ->
                values.put(entry.getKey(), entry.getValue().asText()));

        for (Iterator<Map.Entry<String, JsonNode>> it = schema.fields(); it.hasNext(); ) {
            Map.Entry<String, JsonNode> entry = it.next();
            JsonNode placeholders = entry.getValue().get("placeholders");
            if (placeholders == null || placeholders.isEmpty()) {
                continue;
            }
            assertThat(values)
                    .as("schema placeholder key %s must be served", entry.getKey())
                    .containsKey(entry.getKey());
            String text = values.get(entry.getKey());
            Set<String> tokens = new HashSet<>();
            Matcher matcher = PLACEHOLDER.matcher(text);
            while (matcher.find()) {
                tokens.add(matcher.group(1));
            }
            assertThat(tokens)
                    .as("placeholders for %s in workshop_admin/en.json", entry.getKey())
                    .containsAll(keys(placeholders));
        }
    }

    @Test
    void backendResolvedKeysAreDottedHierarchical() throws Exception {
        List<String> violations = new ArrayList<>();
        for (String file : new String[]{"platform_admin/en.json", "common/en.json",
                "common/es.json"}) {
            JsonNode catalog = read(file);
            catalog.fieldNames().forEachRemaining(key -> {
                if (!DOTTED_KEY.matcher(key).matches()) {
                    violations.add(file + " -> '" + key + "'");
                }
            });
        }
        assertThat(violations)
                .as("platform_admin/common keys must be dotted hierarchical "
                        + "(^[a-z][A-Za-z0-9]*(\\.[a-z][A-Za-z0-9]*)+$)")
                .isEmpty();
    }

    @Test
    void uiOnlyKeysAreFlatCamelCase() throws Exception {
        List<String> violations = new ArrayList<>();
        for (String file : new String[]{"workshop_admin/en.json", "workshop_admin/es.json",
                "technician/en.json", "technician/es.json"}) {
            JsonNode catalog = read(file);
            catalog.fieldNames().forEachRemaining(key -> {
                if (!FLAT_CAMEL_KEY.matcher(key).matches()) {
                    violations.add(file + " -> '" + key + "'");
                }
            });
        }
        assertThat(violations)
                .as("workshop_admin/technician keys must be flat camelCase "
                        + "(^[a-z][A-Za-z0-9]*$, no dots)")
                .isEmpty();
    }

    @Test
    void sharedLabelsHaveIdenticalEnglishValues() throws Exception {
        JsonNode common = read("common/en.json");
        JsonNode workshop = read("workshop_admin/en.json");
        JsonNode technician = read("technician/en.json");

        Map<String, String> pairs = Map.of(
                "filter.all", "filterAll",
                "role.platformAdmin", "rolePlatformAdmin",
                "role.technician", "roleTechnician",
                "role.workshopAdmin", "roleWorkshopAdmin");

        List<String> violations = new ArrayList<>();
        pairs.forEach((dotted, flat) -> {
            String commonValue = text(common, dotted);
            String workshopValue = text(workshop, flat);
            String technicianValue = text(technician, flat);
            if (commonValue == null || !commonValue.equals(workshopValue)
                    || !commonValue.equals(technicianValue)) {
                violations.add("common/en.json '" + dotted + "'='" + commonValue
                        + "' vs workshop_admin/en.json '" + flat + "'='" + workshopValue
                        + "' vs technician/en.json '" + flat + "'='" + technicianValue + "'");
            }
        });
        assertThat(violations)
                .as("the four labels shared by both key shapes must have identical English values")
                .isEmpty();
    }

    private static String text(JsonNode catalog, String key) {
        JsonNode value = catalog.get(key);
        return value == null || value.isNull() ? null : value.asText();
    }

    private JsonNode read(String resource) throws Exception {
        try (InputStream stream = getClass().getResourceAsStream("/i18n/" + resource)) {
            assertThat(stream).as("missing /i18n/%s", resource).isNotNull();
            return objectMapper.readTree(stream);
        }
    }

    private static Set<String> keys(JsonNode node) {
        Set<String> keys = new TreeSet<>();
        node.fieldNames().forEachRemaining(keys::add);
        return keys;
    }
}
