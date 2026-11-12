package com.truereport.jobs;

import com.truereport.documents.PlatformReportPdf;
import com.truereport.jobs.PlatformJobStore.DocumentRow;
import com.truereport.jobs.PlatformJobStore.DocumentTypeRow;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.storage.ObjectStorage;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Generates the EN/AR report documents after publish. Generation is attempted
 * immediately after the publish transaction and is also recorded in the
 * transactional outbox so a failed artifact can be retried safely.
 */
@Service
public class PlatformJobDocumentService {

    private static final List<String> LANGUAGES = List.of("en", "ar");

    private final PlatformJobStore store;
    private final ObjectStorage storage;
    private final PlatformReportPdf pdf;
    private final OutboxService outbox;

    public PlatformJobDocumentService(PlatformJobStore store, ObjectStorage storage,
                                      PlatformReportPdf pdf, OutboxService outbox) {
        this.store = store;
        this.storage = storage;
        this.pdf = pdf;
        this.outbox = outbox;
    }

    @Transactional
    public void generateForVersion(JobRow job, String reportVersionId) {
        List<DocumentRow> existing = store.documents(reportVersionId);
        for (DocumentTypeRow type : store.activeDocumentTypes()) {
            for (String language : LANGUAGES) {
                DocumentRow row = existing.stream()
                        .filter(document -> document.documentTypeCode().equals(type.code())
                                && document.language().equals(language))
                        .findFirst()
                        .orElse(null);
                if (row == null) {
                    String id = store.insertDocument(reportVersionId, type.code(), language);
                    row = store.document(id).orElse(null);
                }
                if (row != null) {
                    generateOne(job, row, type);
                }
            }
        }
    }

    @Transactional
    public List<DocumentRow> retry(JobRow job, String reportVersionId, String documentTypeCode) {
        DocumentTypeRow type = store.documentType(documentTypeCode)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "DOCUMENT_TYPE_NOT_FOUND", "error.job.documentNotFound",
                        "Document type not found"));
        List<DocumentRow> rows = store.documents(reportVersionId, documentTypeCode);
        if (rows.isEmpty()) {
            throw new ApiException(HttpStatus.NOT_FOUND, "DOCUMENT_NOT_FOUND",
                    "error.job.documentNotFound", "No generated document exists for this type");
        }
        List<DocumentRow> updated = new ArrayList<>();
        for (DocumentRow row : rows) {
            generateOne(job, row, type);
            store.document(row.id()).ifPresent(updated::add);
        }
        return updated;
    }

    public byte[] content(DocumentRow document) {
        if (document.storageKey() == null || document.storageKey().isBlank()) {
            throw new ApiException(HttpStatus.CONFLICT, "DOCUMENT_NOT_READY",
                    "error.job.documentNotReady", "The document has not been generated yet");
        }
        return storage.get(document.storageKey());
    }

    private void generateOne(JobRow job, DocumentRow document, DocumentTypeRow type) {
        try {
            String language = "ar".equals(document.language()) ? "ar" : "en";
            List<String> lines = new ArrayList<>();
            lines.add("TrueReport Inspection Report");
            lines.add("Reference: " + job.reference());
            lines.add("Document: " + ("ar".equals(language) ? type.nameAr() : type.nameEn()));
            lines.add("Language: " + ("ar".equals(language) ? "Arabic" : "English"));
            lines.add("Customer: " + job.customerName());
            lines.add("Vehicle: " + job.vehicleYear() + " " + job.vehicleMake() + " "
                    + job.vehicleModel());
            lines.add("VIN: " + job.vehicleVin());
            lines.add("Plate: " + job.vehiclePlate());
            lines.add("Score: " + (job.score() == null ? "-" : job.score())
                    + "   Grade: " + (job.gradeCode() == null ? "-" : job.gradeCode()));
            lines.add("Status: " + job.status());
            String title = "ar".equals(language) ? type.nameAr() : type.nameEn();
            byte[] bytes = pdf.render(title, lines);
            String storageKey = "platform-reports/" + job.id() + "/" + document.reportVersionId()
                    + "/" + document.documentTypeCode() + "-" + language + ".pdf";
            storage.put(storageKey, bytes, "application/pdf");
            store.markDocumentReady(document.id(), storageKey, "application/pdf", bytes.length);
            outbox.publish("REPORT_DOCUMENT", document.id(), "REPORT_DOCUMENT_GENERATED",
                    Map.of("jobId", job.id(), "documentId", document.id(),
                            "language", language, "documentType", document.documentTypeCode()));
        } catch (RuntimeException exception) {
            store.markDocumentFailed(document.id(), exception.getMessage());
            outbox.publish("REPORT_DOCUMENT", document.id(), "REPORT_DOCUMENT_FAILED",
                    Map.of("jobId", job.id(), "documentId", document.id(),
                            "language", document.language(),
                            "documentType", document.documentTypeCode(),
                            "error", String.valueOf(exception.getMessage())));
        }
    }
}
