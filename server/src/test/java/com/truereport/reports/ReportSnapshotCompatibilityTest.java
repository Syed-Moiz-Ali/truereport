package com.truereport.reports;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Published snapshots are immutable data written by whichever server was live at publish
 * time. Reading must tolerate fields a newer server added, otherwise a rollback turns every
 * published link into a 404.
 */
class ReportSnapshotCompatibilityTest {

    private final ObjectMapper strict = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

    @Test
    void ignoresUnknownTopLevelAndNestedFields() throws Exception {
        String json = """
                {
                  "reportNumber": "TR-1",
                  "reportVersion": 1,
                  "language": "es",
                  "futureReportingField": {"nested": true},
                  "vehicle": {"make": "Toyota", "futureVehicleField": 3},
                  "keyFindings": [{"stableCode": "ENG-OIL-01", "label": "Aceite",
                                   "futureItemField": ["x"]}]
                }
                """;

        ReportSnapshot snapshot = strict.readValue(json, ReportSnapshot.class);

        assertThat(snapshot.reportNumber()).isEqualTo("TR-1");
        assertThat(snapshot.language()).isEqualTo("es");
        assertThat(snapshot.vehicle().make()).isEqualTo("Toyota");
        assertThat(snapshot.keyFindings()).singleElement()
                .extracting(ReportSnapshot.ItemSnapshot::stableCode)
                .isEqualTo("ENG-OIL-01");
    }
}
