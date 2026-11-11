package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ScoreBandDto;
import com.truereport.shared.error.ApiException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ConfigValidatorsTest {

    @Test
    void acceptsContiguousScoreBandsCoveringZeroToHundred() {
        ConfigValidators.validateScoreBands(List.of(
                new ScoreBandDto("DEFECT_FOUND", 0, 59, 0, "Fail", "فشل"),
                new ScoreBandDto("ATTENTION_RECOMMENDED", 60, 84, 70, "Attention", "انتباه"),
                new ScoreBandDto("NO_ISSUE_OBSERVED", 85, 100, 100, "Pass", "نجاح")));
    }

    @Test
    void rejectsScoreBandGap() {
        assertThatThrownBy(() -> ConfigValidators.validateScoreBands(List.of(
                new ScoreBandDto("DEFECT_FOUND", 0, 59, 0, "Fail", "فشل"),
                new ScoreBandDto("NO_ISSUE_OBSERVED", 61, 100, 100, "Pass", "نجاح"))))
                .isInstanceOf(ApiException.class)
                .extracting(error -> ((ApiException) error).code())
                .isEqualTo("SCORE_BANDS_INVALID");
    }

    @Test
    void rejectsOverlappingMeasurementBands() {
        assertThatThrownBy(() -> ConfigValidators.validateMeasurementBands(List.of(
                band("0", "3", "DEFECT_FOUND"),
                band("2.5", "99", "NO_ISSUE_OBSERVED"))))
                .isInstanceOf(ApiException.class)
                .extracting(error -> ((ApiException) error).code())
                .isEqualTo("MEASUREMENT_BANDS_INVALID");
    }

    @Test
    void acceptsDirectionAwareContiguousMeasurementBands() {
        ConfigValidators.validateMeasurementBands(List.of(
                band("0", "7", "NO_ISSUE_OBSERVED"),
                band("7.001", "16", "ATTENTION_RECOMMENDED"),
                band("16.001", "99", "DEFECT_FOUND")));
    }

    @Test
    void rejectsSelectFieldWithoutOptionSet() {
        IssueFieldDto field = new IssueFieldDto(null, "ISSUE_TYPE", "Issue Type", "نوع العطل",
                "SELECT", null, null, true, List.of("DEFECT_FOUND"), null, null, 0,
                null, null, false, false, 1, List.of());
        assertThatThrownBy(() -> ConfigValidators.validateIssueFields(List.of(field), Set.of()))
                .isInstanceOf(ApiException.class)
                .satisfies(error -> assertThat(((ApiException) error).issues()).isNotEmpty());
    }

    private MeasurementBandDto band(String min, String max, String result) {
        return new MeasurementBandDto("MEASUREMENT", "MM", "HIGHER_IS_BETTER",
                new BigDecimal(min), new BigDecimal(max), result, 100, "Label", "تسمية", 1);
    }
}
