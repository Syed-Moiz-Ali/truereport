package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.shared.error.ApiException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ConfigValidatorsTest {

    @Test
    void rejectsMeasurementBandsThatOverlap() {
        assertThatThrownBy(() -> ConfigValidators.validateMeasurementBands(List.of(
                band("0", "3", "DEFECT_FOUND"),
                band("2.999", "5", "ATTENTION_RECOMMENDED"),
                band("5.001", "99", "NO_ISSUE_OBSERVED"))))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void acceptsContiguousMeasurementBands() {
        ConfigValidators.validateMeasurementBands(List.of(
                band("0", "2.999", "DEFECT_FOUND"),
                band("3", "5.499", "ATTENTION_RECOMMENDED"),
                band("5.5", "99", "NO_ISSUE_OBSERVED")));
    }

    @Test
    void rejectsSelectFieldWithoutOptionSet() {
        IssueFieldDto field = new IssueFieldDto(null, "ISSUE_TYPE", "Issue Type",
                "SELECT", null, null, true, List.of("DEFECT_FOUND"), null, null, 0,
                null, null, false, false, 1, List.of(), Map.of(),
                "Issue Type", "نوع المشكلة");
        assertThatThrownBy(() -> ConfigValidators.validateIssueFields(List.of(field), Set.of()))
                .isInstanceOf(ApiException.class)
                .satisfies(error -> assertThat(((ApiException) error).issues()).isNotEmpty());
    }

    private MeasurementBandDto band(String min, String max, String result) {
        return new MeasurementBandDto("MEASUREMENT", "MM", "HIGHER_IS_BETTER",
                new BigDecimal(min), new BigDecimal(max), result, 100, "Label", 1,
                Map.of(), "Label", "التسمية");
    }
}
