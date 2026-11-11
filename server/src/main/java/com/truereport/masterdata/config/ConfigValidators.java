package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ScoreBandDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class ConfigValidators {

    public static final Set<String> RESULT_CODES = Set.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND",
            "NOT_CHECKED", "NOT_APPLICABLE", "COULD_NOT_VERIFY");
    public static final Set<String> INPUT_TYPES = Set.of("SELECT", "MULTI_SELECT", "NUMBER", "BOOLEAN", "TEXT");
    public static final Set<String> EVIDENCE_TYPES = Set.of("PHOTO", "VIDEO", "DOCUMENT");
    public static final Set<String> DIRECTIONS = Set.of("HIGHER_IS_BETTER", "LOWER_IS_BETTER");

    private ConfigValidators() {
    }

    public static void validateScoreBands(List<ScoreBandDto> bands) {
        List<FieldIssue> issues = new ArrayList<>();
        if (bands == null || bands.isEmpty()) {
            throw bandError("SCORE_BANDS_REQUIRED", "Score bands are required");
        }
        List<ScoreBandDto> sorted = new ArrayList<>(bands);
        sorted.sort(Comparator.comparingInt(ScoreBandDto::minScore));
        int expected = 0;
        for (ScoreBandDto band : sorted) {
            if (!RESULT_CODES.contains(band.resultCode())) {
                issues.add(FieldIssue.of("resultCode", "RESULT_CODE_INVALID", "error.resultOption.invalid"));
            }
            if (band.minScore() != expected) {
                issues.add(FieldIssue.of("bands", "SCORE_BANDS_GAP",
                        "error.scoreBands.invalid"));
            }
            if (band.minScore() > band.maxScore() || band.maxScore() > 100) {
                issues.add(FieldIssue.of("bands", "SCORE_BAND_RANGE", "error.scoreBands.invalid"));
            }
            if (band.defaultScore() < band.minScore() || band.defaultScore() > band.maxScore()) {
                issues.add(FieldIssue.of("defaultScore", "SCORE_BAND_DEFAULT", "error.scoreBands.invalid"));
            }
            expected = band.maxScore() + 1;
        }
        if (expected != 101) {
            issues.add(FieldIssue.of("bands", "SCORE_BANDS_COVERAGE", "error.scoreBands.invalid"));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("SCORE_BANDS_INVALID",
                    "Score bands must be contiguous, non-overlapping and cover 0-100", issues);
        }
    }

    public static void validateMeasurementBands(List<MeasurementBandDto> bands) {
        if (bands == null || bands.isEmpty()) {
            return;
        }
        List<FieldIssue> issues = new ArrayList<>();
        for (MeasurementBandDto band : bands) {
            if (!RESULT_CODES.contains(band.resultCode())) {
                issues.add(FieldIssue.of("resultCode", "RESULT_CODE_INVALID", "error.resultOption.invalid"));
            }
            if (!DIRECTIONS.contains(band.direction())) {
                issues.add(FieldIssue.of("direction", "DIRECTION_INVALID", "error.measurementBands.invalid"));
            }
            if (band.minValue() == null || band.maxValue() == null
                    || band.minValue().compareTo(band.maxValue()) >= 0) {
                issues.add(FieldIssue.of("bands", "MEASUREMENT_RANGE", "error.measurementBands.invalid"));
            }
        }
        bands.stream()
                .collect(java.util.stream.Collectors.groupingBy(
                        b -> b.fieldCode() + "|" + b.unitCode() + "|" + b.direction()))
                .forEach((key, group) -> {
                    List<MeasurementBandDto> sorted = new ArrayList<>(group);
                    sorted.sort(Comparator.comparing(MeasurementBandDto::minValue));
                    for (int i = 1; i < sorted.size(); i++) {
                        MeasurementBandDto previous = sorted.get(i - 1);
                        MeasurementBandDto current = sorted.get(i);
                        if (previous.maxValue().compareTo(current.minValue()) > 0) {
                            issues.add(FieldIssue.of("bands", "MEASUREMENT_OVERLAP",
                                    "error.measurementBands.invalid"));
                        }
                    }
                });
        if (!issues.isEmpty()) {
            throw ApiException.validation("MEASUREMENT_BANDS_INVALID",
                    "Measurement bands must be contiguous and non-overlapping", issues);
        }
    }

    public static void validateIssueFields(List<IssueFieldDto> fields, Set<String> optionSetCodes) {
        if (fields == null || fields.isEmpty()) {
            return;
        }
        List<FieldIssue> issues = new ArrayList<>();
        Set<String> codes = new HashSet<>();
        for (IssueFieldDto field : fields) {
            if (field.fieldCode() == null || field.fieldCode().isBlank()) {
                issues.add(FieldIssue.of("fieldCode", "FIELD_CODE_REQUIRED", "error.issueFields.invalid"));
                continue;
            }
            if (!codes.add(field.fieldCode())) {
                issues.add(FieldIssue.of(field.fieldCode(), "FIELD_CODE_DUPLICATE", "error.issueFields.invalid"));
            }
            if (!INPUT_TYPES.contains(field.inputType())) {
                issues.add(FieldIssue.of(field.fieldCode() + ".inputType", "INPUT_TYPE_INVALID",
                        "error.issueFields.invalid"));
            }
            boolean needsOptions = "SELECT".equals(field.inputType()) || "MULTI_SELECT".equals(field.inputType());
            if (needsOptions && (field.optionSetCode() == null || field.optionSetCode().isBlank())) {
                issues.add(FieldIssue.of(field.fieldCode() + ".optionSetCode", "OPTION_SET_REQUIRED",
                        "error.issueFields.invalid"));
            }
            if (field.optionSetCode() != null && !field.optionSetCode().isBlank()
                    && !optionSetCodes.contains(field.optionSetCode())) {
                issues.add(FieldIssue.of(field.fieldCode() + ".optionSetCode", "OPTION_SET_UNKNOWN",
                        "error.issueFields.invalid"));
            }
            if (field.requiredForStatuses() != null) {
                for (String status : field.requiredForStatuses()) {
                    if (!RESULT_CODES.contains(status)) {
                        issues.add(FieldIssue.of(field.fieldCode() + ".requiredForStatuses",
                                "RESULT_CODE_INVALID", "error.resultOption.invalid"));
                    }
                }
            }
            if ("NUMBER".equals(field.inputType()) && field.minValue() != null && field.maxValue() != null
                    && field.minValue().compareTo(field.maxValue()) >= 0) {
                issues.add(FieldIssue.of(field.fieldCode() + ".range", "NUMBER_RANGE",
                        "error.issueFields.invalid"));
            }
        }
        fields.stream()
                .filter(f -> f.dependsOnFieldCode() != null && !f.dependsOnFieldCode().isBlank())
                .forEach(f -> {
                    if (!codes.contains(f.dependsOnFieldCode())) {
                        issues.add(FieldIssue.of(f.fieldCode() + ".dependsOnFieldCode",
                                "DEPENDENCY_UNKNOWN", "error.issueFields.invalid"));
                    }
                });
        if (!issues.isEmpty()) {
            throw ApiException.validation("ISSUE_FIELDS_INVALID",
                    "Issue field configuration is invalid", issues);
        }
    }

    public static void requireBilingual(String field, String en, String ar, List<FieldIssue> issues) {
        if (en == null || en.isBlank()) {
            issues.add(FieldIssue.of(field + "En", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (ar == null || ar.isBlank()) {
            issues.add(FieldIssue.of(field + "Ar", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
    }

    private static ApiException bandError(String code, String message) {
        return ApiException.validation(code, message,
                List.of(FieldIssue.of("bands", code, "error.scoreBands.invalid")));
    }

    public static boolean blank(BigDecimal value) {
        return value == null;
    }
}
