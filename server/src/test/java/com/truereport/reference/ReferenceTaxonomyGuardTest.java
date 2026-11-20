package com.truereport.reference;

import com.truereport.reference.ReferenceEnums.EvidenceType;
import com.truereport.reference.ReferenceEnums.ChecklistStatus;
import com.truereport.reference.ReferenceEnums.ConsentStatus;
import com.truereport.reference.ReferenceEnums.ContentType;
import com.truereport.reference.ReferenceEnums.DeliveryStatus;
import com.truereport.reference.ReferenceEnums.DocumentTypeStatus;
import com.truereport.reference.ReferenceEnums.HealthStatus;
import com.truereport.reference.ReferenceEnums.InputType;
import com.truereport.reference.ReferenceEnums.MeasurementDirection;
import com.truereport.reference.ReferenceEnums.TranslationStatus;
import com.truereport.reference.ReferenceEnums.WorkshopStatus;
import com.truereport.reference.ReferenceEnums.PlatformChipStatus;
import com.truereport.reference.ReferenceEnums.Grade;
import com.truereport.reference.ReferenceEnums.JobStatus;
import com.truereport.reference.ReferenceEnums.MeasurementUnit;
import com.truereport.reference.ReferenceEnums.PublicationStatus;
import com.truereport.reference.ReferenceEnums.ResultCode;
import com.truereport.reference.ReferenceEnums.ReviewStatus;
import com.truereport.reference.ReferenceEnums.Severity;
import com.truereport.uimessages.PlatformUiMessageCatalog;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Seed guard: the taxonomy rows must exist for every Java code, and every
 * label key must resolve in a shipped catalog.
 */
@SpringBootTest
@ActiveProfiles("test")
class ReferenceTaxonomyGuardTest {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    PlatformUiMessageCatalog uiMessages;

    @Test
    void everyJobReviewAndPublicationCodeHasASeededRow() {
        assertCodes(ReferenceTaxonomy.JOB_STATUS, codes(JobStatus.values()));
        assertCodes(ReferenceTaxonomy.REVIEW_STATUS, codes(ReviewStatus.values()));
        assertCodes(ReferenceTaxonomy.PUBLICATION_STATUS, codes(PublicationStatus.values()));
    }

    @Test
    void everySeverityResultGradeAndUnitCodeHasASeededRow() {
        assertCodes(ReferenceTaxonomy.SEVERITY, codes(Severity.values()));
        assertCodes(ReferenceTaxonomy.RESULT, codes(ResultCode.values()));
        assertCodes(ReferenceTaxonomy.GRADE, codes(Grade.values()));
        assertCodes(ReferenceTaxonomy.MEASUREMENT_UNIT, codes(MeasurementUnit.values()));
        assertCodes(ReferenceTaxonomy.EVIDENCE_TYPE, codes(EvidenceType.values()));
    }

    @Test
    void everyClientStatusMapHasASeededRow() {
        assertCodes(ReferenceTaxonomy.WORKSHOP_STATUS, codes(WorkshopStatus.values()));
        assertCodes(ReferenceTaxonomy.CHECKLIST_STATUS, codes(ChecklistStatus.values()));
        assertCodes(ReferenceTaxonomy.HEALTH_STATUS, codes(HealthStatus.values()));
        assertCodes(ReferenceTaxonomy.DELIVERY_STATUS, codes(DeliveryStatus.values()));
        assertCodes(ReferenceTaxonomy.CONSENT_STATUS, codes(ConsentStatus.values()));
        assertCodes(ReferenceTaxonomy.TRANSLATION_STATUS, codes(TranslationStatus.values()));
        assertCodes(ReferenceTaxonomy.DOCUMENT_TYPE_STATUS, codes(DocumentTypeStatus.values()));
        assertCodes(ReferenceTaxonomy.CONTENT_TYPE, codes(ContentType.values()));
        assertCodes(ReferenceTaxonomy.INPUT_TYPE, codes(InputType.values()));
        assertCodes(ReferenceTaxonomy.MEASUREMENT_DIRECTION, codes(MeasurementDirection.values()));

        // PENDING and FAILED are intentionally reused from document-status.
        List<String> chip = jdbc.queryForList(
                "SELECT code FROM reference_domain WHERE domain_key = ?",
                String.class, ReferenceTaxonomy.PLATFORM_CHIP_STATUS);
        assertThat(chip).containsExactly(PlatformChipStatus.DISABLED.name());
        List<String> document = jdbc.queryForList(
                "SELECT code FROM reference_domain WHERE domain_key = ?",
                String.class, ReferenceTaxonomy.DOCUMENT_STATUS);
        assertThat(document).contains("PENDING", "FAILED");
    }

    @Test
    void everySeedLabelKeyResolvesInAShippedCatalog() {
        Map<String, String> common = uiMessages.namespace("common", "en").values();
        Map<String, String> workshop = uiMessages.namespace("workshop_admin", "en").values();
        Map<String, String> technician = uiMessages.namespace("technician", "en").values();
        Map<String, String> platform = uiMessages.namespace("platform_admin", "en").values();

        List<String> missing = new ArrayList<>();
        for (ReferenceTaxonomy.DomainSeed row : ReferenceTaxonomy.DOMAINS) {
            String key = row.labelKey();
            if (!common.containsKey(key) && !workshop.containsKey(key)
                    && !technician.containsKey(key) && !platform.containsKey(key)) {
                missing.add(row.domainKey() + "." + row.code() + " -> " + key);
            }
        }
        assertThat(missing).as("label_key must exist in a shipped catalog").isEmpty();
    }

    @Test
    void transitionGraphIsSeededForEveryEntity() {
        for (String entity : ReferenceTaxonomy.TRANSITION_ENTITIES.keySet()) {
            Integer count = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM status_transition WHERE entity = ?",
                    Integer.class, entity);
            assertThat(count).as("transitions for %s", entity).isNotNull().isGreaterThan(0);
        }
    }

    private void assertCodes(String domainKey, List<String> expected) {
        List<String> actual = jdbc.queryForList(
                "SELECT code FROM reference_domain WHERE domain_key = ? ORDER BY sort_order, code",
                String.class, domainKey);
        assertThat(actual)
                .as("seeded codes for %s", domainKey)
                .containsExactlyInAnyOrderElementsOf(expected);
    }

    private static List<String> codes(Enum<?>[] values) {
        List<String> codes = new ArrayList<>();
        for (Enum<?> value : values) {
            codes.add(value.name());
        }
        return codes;
    }
}
