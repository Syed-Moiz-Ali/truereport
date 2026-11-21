package com.truereport.jobs;

import com.truereport.documents.PlatformReportPdf;
import com.truereport.jobs.PlatformJobStore.DocumentRow;
import com.truereport.jobs.PlatformJobStore.DocumentTypeRow;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.storage.ObjectStorage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Document generation follows the job's preferred language: one row per
 * document type, republishing reuses that row, and a job without a language
 * keeps the English default.
 */
class PlatformJobDocumentServiceTest {

    private static final String VERSION_ID = "version-1";
    private static final String DOCUMENT_ID = "document-1";
    private static final DocumentTypeRow REPORT_TYPE =
            new DocumentTypeRow("REPORT", "Report", null, 1);

    private PlatformJobStore store;
    private ObjectStorage storage;
    private OutboxService outbox;
    private PlatformJobDocumentService service;

    @BeforeEach
    void setUp() {
        store = mock(PlatformJobStore.class);
        storage = mock(ObjectStorage.class);
        outbox = mock(OutboxService.class);
        service = new PlatformJobDocumentService(store, storage, new PlatformReportPdf(), outbox);
        when(store.activeDocumentTypes()).thenReturn(List.of(REPORT_TYPE));
    }

    @Test
    void spanishJobCreatesAnEsRowAndEsFilename() {
        when(store.documents(VERSION_ID)).thenReturn(List.of());
        when(store.insertDocument(VERSION_ID, "REPORT", "es")).thenReturn(DOCUMENT_ID);
        when(store.document(DOCUMENT_ID))
                .thenReturn(Optional.of(document(DOCUMENT_ID, "es")));

        service.generateForVersion(job("es"), VERSION_ID);

        verify(store).insertDocument(VERSION_ID, "REPORT", "es");
        verify(store, never()).insertDocument(anyString(), anyString(), eq("en"));
        ArgumentCaptor<String> key = ArgumentCaptor.forClass(String.class);
        verify(storage).put(key.capture(), any(byte[].class), eq("application/pdf"));
        assertThat(key.getValue()).endsWith("/REPORT-es.pdf");
        verify(store).markDocumentReady(eq(DOCUMENT_ID), eq(key.getValue()),
                eq("application/pdf"), anyLong());
        verify(store, never()).markDocumentFailed(anyString(), anyString());
    }

    @Test
    void republishingReusesTheExistingLanguageRow() {
        when(store.documents(VERSION_ID))
                .thenReturn(List.of(document(DOCUMENT_ID, "es")));
        when(store.document(DOCUMENT_ID))
                .thenReturn(Optional.of(document(DOCUMENT_ID, "es")));

        service.generateForVersion(job("es"), VERSION_ID);
        service.generateForVersion(job("es"), VERSION_ID);

        verify(store, never()).insertDocument(anyString(), anyString(), anyString());
        verify(store, times(2)).markDocumentReady(eq(DOCUMENT_ID), anyString(),
                eq("application/pdf"), anyLong());
    }

    @Test
    void jobWithoutPreferredLanguageStaysEnglish() {
        when(store.documents(VERSION_ID)).thenReturn(List.of());
        when(store.insertDocument(VERSION_ID, "REPORT", "en")).thenReturn(DOCUMENT_ID);
        when(store.document(DOCUMENT_ID))
                .thenReturn(Optional.of(document(DOCUMENT_ID, "en")));

        service.generateForVersion(job(null), VERSION_ID);

        verify(store).insertDocument(VERSION_ID, "REPORT", "en");
    }

    private static DocumentRow document(String id, String language) {
        return new DocumentRow(id, VERSION_ID, "REPORT", "Report", null, language,
                null, "application/pdf", null, "PENDING", null, null);
    }

    private static JobRow job(String preferredLanguage) {
        return new JobRow(
                "job-1", "workshop-1", "JOB-1", "APPROVED", "APPROVED", "UNPUBLISHED",
                null, null, "Delivery Customer", "+971500009900", null,
                "1HGCM82633A004352", "Toyota", "Corolla", 2020, "PLATE-1",
                12000, "KM", "AUTOMATIC", "PETROL", preferredLanguage,
                null, null, null, null, null, null, null, null, null,
                88, "B", false, null, true, true, "user-1",
                null, null, 1);
    }
}
