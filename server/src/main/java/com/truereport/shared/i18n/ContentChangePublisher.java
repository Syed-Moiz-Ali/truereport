package com.truereport.shared.i18n;

import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import com.truereport.shared.i18n.TranslationJobStore;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Cheap, in-transaction change detection: writes translation rows/jobs but does
 * not call any provider. The scheduled worker does the actual translation.
 */
@Service
public class ContentChangePublisher {

    private final ContentTranslationStore translations;
    private final TranslationJobStore jobs;
    private final LanguageCatalog languages;
    private final ContentTranslationService service;

    public ContentChangePublisher(ContentTranslationStore translations, TranslationJobStore jobs,
                                  LanguageCatalog languages, ContentTranslationService service) {
        this.translations = translations;
        this.jobs = jobs;
        this.languages = languages;
        this.service = service;
    }

    /** Canonical English text changed: stale existing rows and enqueue missing ones. */
    @Transactional
    public void fieldChanged(String entityType, String entityId, String field, String text) {
        String hash = service.hash(text);
        Map<String, TranslationRow> rows = new LinkedHashMap<>();
        for (TranslationRow row : translations.findForField(entityType, entityId, field)) {
            rows.put(row.lang(), row);
        }
        for (String lang : languages.languages()) {
            if (lang.equals(languages.defaultLanguage())) {
                continue;
            }
            enqueueIfNeeded(entityType, entityId, field, lang, hash, rows.get(lang), false);
        }
        service.invalidate(entityType, entityId);
    }

    /**
     * A non-canonical authoring write. The authored text is stored verbatim and
     * a TO_CANONICAL job derives the English source. Other languages are filled
     * after the canonical text is known.
     */
    @Transactional
    public void authored(String entityType, String entityId, String field, String lang,
                         String text) {
        String target = languages.normalize(lang);
        String body = text == null ? "" : text;
        translations.upsert(entityType, entityId, field, target, body, "AUTHORED", "REVIEWED",
                target, service.hash(body), null, null);
        translations.markCanonicalStale(entityType, entityId, field, languages.defaultLanguage());
        jobs.enqueue(entityType, entityId, field, target, TranslationJobStore.TO_CANONICAL);
        service.invalidate(entityType, entityId);
    }

    /** Called by the worker after TO_CANONICAL updated the canonical column. */
    @Transactional
    public void canonicalChanged(String entityType, String entityId, String field, String text,
                                 String excludeLang) {
        String hash = service.hash(text);
        String skip = languages.normalize(excludeLang);
        Map<String, TranslationRow> rows = new LinkedHashMap<>();
        for (TranslationRow row : translations.findForField(entityType, entityId, field)) {
            rows.put(row.lang(), row);
        }
        for (String lang : languages.languages()) {
            if (lang.equals(languages.defaultLanguage()) || lang.equals(skip)) {
                continue;
            }
            enqueueIfNeeded(entityType, entityId, field, lang, hash, rows.get(lang), false);
        }
        service.invalidate(entityType, entityId);
    }

    /** Hard delete cleanup (used when a content row is removed). */
    @Transactional
    public void deleteAll(String entityType, String entityId) {
        translations.deleteAll(entityType, entityId);
        jobs.deleteAll(entityType, entityId);
        service.invalidate(entityType, entityId);
    }

    private void enqueueIfNeeded(String entityType, String entityId, String field, String lang,
                                 String hash, TranslationRow row, boolean force) {
        boolean current = row != null && row.body() != null && !row.body().isBlank()
                && hash.equals(row.sourceHash());
        if (current && !force) {
            return;
        }
        if (row != null) {
            translations.updateStatus(entityType, entityId, field, lang, "STALE");
        }
        // Manual translations are never overwritten by machine output.
        if (row != null && "AUTHORED".equals(row.origin())) {
            return;
        }
        jobs.enqueue(entityType, entityId, field, lang,
                TranslationJobStore.FROM_CANONICAL);
    }
}
