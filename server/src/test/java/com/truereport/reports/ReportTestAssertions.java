package com.truereport.reports;

import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Reusable guards for the rendered public/PDF report view model.
 *
 * <p>Every value the templates render must be populated; a labelled cell is
 * never allowed to fall back to {@code ""}. Optional fields (a missing note, a
 * special spec, an optional photo) are omitted from the map or are explicitly
 * listed below, and the templates guard them with {@code th:if}.</p>
 */
final class ReportTestAssertions {

    private static final Set<String> OPTIONAL_EMPTY_KEYS = Set.of(
            "note", "reasonCode", "standardSpec", "videoCaption", "videoUrl",
            "videoDuration", "partPhoto", "pressure", "brakePad", "diagnosticSensor",
            "technicianNote", "branch", "safetyCapReason", "imageUrl", "details",
            "inspectNote", "clientName", "odometer", "gearbox", "fuelType",
            "vehicleType", "severity", "severityEn", "severityCode", "reason",
            "paintThickness");

    private static final Set<String> FINDING_RESULTS = Set.of(
            "DEFECT_FOUND", "ATTENTION_RECOMMENDED");

    private ReportTestAssertions() {
    }

    static void assertNoEmptyRenderedValues(Map<String, Object> page) {
        walk(page, "", null);
    }

    private static void walk(Object value, String path, Map<?, ?> parent) {
        if (value instanceof Map<?, ?> map) {
            if (map.isEmpty()) {
                return;
            }
            String resultCode = map.get("resultCode") instanceof String code ? code : null;
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                String key = String.valueOf(entry.getKey());
                String childPath = path.isEmpty() ? key : path + "." + key;
                Object child = entry.getValue();
                if (child instanceof String text) {
                    if (!isOptionalEmpty(key, map, resultCode)) {
                        assertThat(text)
                                .as("empty rendered report value at %s", childPath)
                                .isNotBlank();
                    }
                } else if (child != null) {
                    walk(child, childPath, map);
                }
            }
        } else if (value instanceof List<?> list) {
            for (int index = 0; index < list.size(); index++) {
                walk(list.get(index), path + "[" + index + "]", parent);
            }
        }
    }

    private static boolean isOptionalEmpty(String key, Map<?, ?> map, String resultCode) {
        if ("severity".equals(key) || "severityEn".equals(key)) {
            Object severityCode = map.get("severityCode");
            return severityCode == null || String.valueOf(severityCode).isBlank();
        }
        if ("reason".equals(key)) {
            return resultCode == null || !FINDING_RESULTS.contains(resultCode);
        }
        if ("diagnosticMetric".equals(key) || "measuredSpec".equals(key)) {
            return !(map.get("measurements") instanceof List<?> measurements)
                    || measurements.isEmpty();
        }
        return OPTIONAL_EMPTY_KEYS.contains(key);
    }
}
