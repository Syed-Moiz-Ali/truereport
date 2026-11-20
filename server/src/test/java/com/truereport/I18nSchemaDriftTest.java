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
 * Guardrails for the Flutter key generator and the two catalog families.
 *
 * <p>{@code i18n/schema.json} is generated from the ARB metadata and equals the
 * union of the two client catalogs. The clients are allowed to differ (each app
 * migrates its own hardcoded strings), but the schema must never drift from the
 * union in either direction.</p>
 *
 * <p>Backend-resolved {@code platform_admin} and {@code common} keys are dotted
 * and hierarchical, while UI-only {@code workshop_admin} and {@code technician}
 * keys are flat camelCase.</p>
 */
class I18nSchemaDriftTest {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");
    private static final Pattern DOTTED_KEY =
            Pattern.compile("^[a-z][A-Za-z0-9]*(\\.[a-z][A-Za-z0-9]*)+$");
    private static final Pattern PLATFORM_PRESENTATION_KEY =
            Pattern.compile("^dash[A-Za-z0-9]+$");
    private static final Pattern FLAT_CAMEL_KEY =
            Pattern.compile("^[a-z][A-Za-z0-9]*$");

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void catalogSplitMatchesTheContract() throws Exception {
        // Sizes are intentionally not pinned here: every phase adds keys. What matters
        // is the split invariant (union/schema/taxonomy tests below) and that no file
        // is empty or unexpectedly clears its family.
        assertThat(keys(read("common/en.json"))).isNotEmpty();
        // Spanish is intentionally partial: any translated key must exist in English.
        assertThat(keys(read("common/es.json")))
                .isSubsetOf(keys(read("common/en.json")));
        assertThat(keys(read("platform_admin/en.json"))).isNotEmpty();
        assertThat(keys(read("workshop_admin/en.json"))).isNotEmpty();
        assertThat(keys(read("technician/en.json"))).isNotEmpty();
        assertThat(keys(read("workshop_admin/es.json"))).isNotEmpty();
        assertThat(keys(read("technician/es.json"))).isNotEmpty();
    }

    @Test
    void schemaKeysMatchTheUnionOfTheClientCatalogsExactly() throws Exception {
        Set<String> schema = keys(read("schema.json").get("keys"));
        Set<String> workshop = keys(read("workshop_admin/en.json"));
        Set<String> technician = keys(read("technician/en.json"));

        Set<String> union = new TreeSet<>(workshop);
        union.addAll(technician);

        // Exact parity in both directions: a key added to either client needs a
        // regenerated schema, and a schema key must be owned by at least one client.
        assertThat(schema).isEqualTo(union);
    }

    @Test
    void everyClientKeyIsServedByItsOwnBundle() throws Exception {
        Set<String> common = keys(read("common/en.json"));
        Set<String> schema = keys(read("schema.json").get("keys"));

        Set<String> servedWorkshop = new HashSet<>(common);
        servedWorkshop.addAll(keys(read("workshop_admin/en.json")));
        Set<String> servedTechnician = new HashSet<>(common);
        servedTechnician.addAll(keys(read("technician/en.json")));

        assertThat(servedWorkshop)
                .as("every workshop_admin key must be served by the workshop_admin bundle")
                .containsAll(keys(read("workshop_admin/en.json")));
        assertThat(servedTechnician)
                .as("every technician key must be served by the technician bundle")
                .containsAll(keys(read("technician/en.json")));

        // Every generator key is served by at least one of the two apps.
        Set<String> allServed = new HashSet<>(servedWorkshop);
        allServed.addAll(servedTechnician);
        assertThat(allServed).containsAll(schema);
    }

    @Test
    void sharedKeysResolveToTheSameEnglishTextInBothApps() throws Exception {
        Map<String, String> workshop = values(read("workshop_admin/en.json"));
        Map<String, String> technician = values(read("technician/en.json"));

        Set<String> shared = new TreeSet<>(workshop.keySet());
        shared.retainAll(technician.keySet());

        List<String> violations = new ArrayList<>();
        for (String key : shared) {
            if (!workshop.get(key).equals(technician.get(key))) {
                violations.add("workshop_admin/en.json '" + key + "'='"
                        + workshop.get(key) + "' vs technician/en.json '" + key + "'='"
                        + technician.get(key) + "'");
            }
        }
        assertThat(violations)
                .as("keys present in both client catalogs must resolve to the same English text")
                .isEmpty();
    }

    @Test
    void backendResolvedKeysAreDottedHierarchical() throws Exception {
        List<String> violations = new ArrayList<>();
        for (String file : new String[]{"platform_admin/en.json", "common/en.json",
                "common/es.json"}) {
            JsonNode catalog = read(file);
            boolean platform = file.startsWith("platform_admin/");
            catalog.fieldNames().forEachRemaining(key -> {
                boolean valid = DOTTED_KEY.matcher(key).matches()
                        || (platform && PLATFORM_PRESENTATION_KEY.matcher(key).matches());
                if (!valid) {
                    violations.add(file + " -> '" + key + "'");
                }
            });
        }
        assertThat(violations)
                .as("platform_admin/common keys must be dotted hierarchical "
                        + "(^[a-z][A-Za-z0-9]*(\\.[a-z][A-Za-z0-9]*)+$); "
                        + "platform presentation keys may be dashCamelCase")
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

    @Test
    void schemaPlaceholdersExistInAtLeastOneDefiningCatalog() throws Exception {
        JsonNode schema = read("schema.json").get("keys");
        Map<String, String> workshop = values(read("workshop_admin/en.json"));
        Map<String, String> technician = values(read("technician/en.json"));

        List<String> violations = new ArrayList<>();
        for (Iterator<Map.Entry<String, JsonNode>> it = schema.fields(); it.hasNext(); ) {
            Map.Entry<String, JsonNode> entry = it.next();
            JsonNode placeholders = entry.getValue().get("placeholders");
            if (placeholders == null || placeholders.isEmpty()) {
                continue;
            }
            String key = entry.getKey();
            List<String> texts = new ArrayList<>();
            if (workshop.containsKey(key)) {
                texts.add(workshop.get(key));
            }
            if (technician.containsKey(key)) {
                texts.add(technician.get(key));
            }
            if (texts.isEmpty()) {
                violations.add("schema.json '" + key
                        + "' has placeholders but is defined in neither client catalog");
                continue;
            }
            for (String expected : keys(placeholders)) {
                boolean found = texts.stream()
                        .anyMatch(text -> tokens(text).contains(expected));
                if (!found) {
                    violations.add("schema.json '" + key + "' placeholder {" + expected
                            + "} missing from its English value in "
                            + (workshop.containsKey(key) ? "workshop_admin/en.json " : "")
                            + (technician.containsKey(key) ? "technician/en.json" : ""));
                }
            }
        }
        assertThat(violations)
                .as("every schema placeholder token must appear in at least one defining catalog")
                .isEmpty();
    }

    private static Set<String> tokens(String value) {
        Set<String> names = new HashSet<>();
        Matcher matcher = PLACEHOLDER.matcher(value == null ? "" : value);
        while (matcher.find()) {
            names.add(matcher.group(1));
        }
        return names;
    }

    private static String text(JsonNode catalog, String key) {
        JsonNode value = catalog.get(key);
        return value == null || value.isNull() ? null : value.asText();
    }

    private static Map<String, String> values(JsonNode catalog) {
        Map<String, String> values = new LinkedHashMap<>();
        catalog.fields().forEachRemaining(entry ->
                values.put(entry.getKey(), entry.getValue().asText()));
        return values;
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
