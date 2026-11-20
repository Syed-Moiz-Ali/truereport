package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Regression: published report snapshots from jobs without optional vehicle
 * data must not render labelled-but-empty spec cells, and the customer name
 * must be masked on the public page.
 */
class ReportViewMapperTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ReportViewMapper mapper = new ReportViewMapper(objectMapper);

    @Test
    void vehicleSpecsOmitUnknownFieldsAndMaskClientName() throws Exception {
        ReportVersion version = version(snapshotWithoutOptionalSpecs(null));

        Map<String, Object> page = mapper.publicPage(version, List.of(), "en", false,
                null, "E2E Customer");
        Map<String, Object> vehicle = vehicle(page);

        assertThat(vehicle.get("clientName")).isEqualTo("E2E C***");
        assertThat(vehicle).doesNotContainKeys(
                "drivetrain", "engineSize", "horsepower", "cylinders",
                "exteriorColor", "interiorTrim", "wheels", "steeringSide",
                "keysCount", "emirate", "inspectionCenter", "specsOrigin",
                "conditionBadge", "gearbox", "fuelType");
        assertThat(vehicle.values())
                .filteredOn(value -> value instanceof CharSequence)
                .allMatch(value -> !value.toString().isBlank());
        ReportTestAssertions.assertNoEmptyRenderedValues(page);
    }

    @Test
    void printPageUsesTheSameMaskedNameAndOmittedSpecs() throws Exception {
        ReportVersion version = version(snapshotWithoutOptionalSpecs(null));

        Map<String, Object> page = mapper.printPage(version, List.of(), "E2E Customer");
        Map<String, Object> vehicle = vehicle(page);

        assertThat(vehicle.get("clientName")).isEqualTo("E2E C***");
        assertThat(vehicle).doesNotContainKeys("drivetrain", "engineSize");
    }

    @Test
    void snapshotCustomerNameIsUsedWhenNoOverrideIsSupplied() throws Exception {
        ReportVersion version = version(snapshotWithoutOptionalSpecs("Jane Q Doe"));

        Map<String, Object> vehicle = vehicle(mapper.publicPage(version, List.of(), "en", false));
        assertThat(vehicle.get("clientName")).isEqualTo("Jane D***");
    }

    @Test
    void noCustomerNameOmitsTheFieldInsteadOfEmittingBlank() throws Exception {
        ReportVersion version = version(snapshotWithoutOptionalSpecs(null));

        Map<String, Object> vehicle = vehicle(mapper.publicPage(version, List.of(), "en", false));
        assertThat(vehicle).doesNotContainKey("clientName");
    }

    @Test
    void noEmptyGuardRejectsABlankRenderedLabel() {
        Map<String, Object> page = Map.of("categories",
                List.of(Map.of("label", "", "labelEn", "Brakes")));

        assertThatThrownBy(() -> ReportTestAssertions.assertNoEmptyRenderedValues(page))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining("categories[0].label");
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> vehicle(Map<String, Object> page) {
        return (Map<String, Object>) page.get("vehicle");
    }

    private String snapshotWithoutOptionalSpecs(String customerName) throws Exception {
        Map<String, Object> vehicle = new LinkedHashMap<>();
        vehicle.put("make", "Toyota");
        vehicle.put("model", "Corolla");
        vehicle.put("year", 2022);
        vehicle.put("vinMasked", "****3456");
        vehicle.put("odometerValue", 12000);
        vehicle.put("odometerUnit", "KM");

        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("reportNumber", "JOB-TEST-1");
        snapshot.put("reportVersion", 1);
        snapshot.put("finalizedAt", "2026-11-20T10:00:00");
        snapshot.put("publishedAt", "2026-11-20T10:00:00");
        snapshot.put("vehicle", vehicle);
        snapshot.put("inspection", Map.of("scope", "Inspection",
                "templateVersionNo", 1, "dateTime", "2026-11-20T10:00:00"));
        snapshot.put("workshop", Map.of("name", "Workshop A", "branch", ""));
        snapshot.put("technician", Map.of("displayName", "Technician A"));
        if (customerName != null) {
            snapshot.put("customerName", customerName);
        }
        snapshot.put("coverage", Map.of("total", 1, "applicable", 1, "completed", 1,
                "notApplicable", 0, "notChecked", 0, "couldNotVerify", 0));
        snapshot.put("keyFindings", List.of());
        snapshot.put("categories", List.of());
        snapshot.put("notChecked", List.of());
        snapshot.put("limitations", List.of());
        snapshot.put("disclaimer", "");
        snapshot.put("verificationHash", "hash");
        return objectMapper.writeValueAsString(snapshot);
    }

    private ReportVersion version(String snapshotJson) {
        return new ReportVersion(UUID.randomUUID(), UUID.randomUUID(), 1, "JOB-TEST-1",
                new byte[32], snapshotJson, new byte[32], LocalDateTime.now());
    }
}
