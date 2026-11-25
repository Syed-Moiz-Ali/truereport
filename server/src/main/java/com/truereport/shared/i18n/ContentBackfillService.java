package com.truereport.shared.i18n;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Explicit backfill for content that predates the translation pipeline.
 *
 * <p>Change-driven enqueueing only sees writes that happen after the pipeline
 * exists, so historical rows have no translation rows and no jobs. This service
 * scans the enabled {@code translatable_field} registry, and enqueues
 * {@code FROM_CANONICAL} jobs for fields that have canonical source text but no
 * usable translation (missing, stale or hash-mismatched). It never calls the
 * provider: the worker drains the jobs as usual.</p>
 */
@Service
public class ContentBackfillService {

    private static final Logger log = LoggerFactory.getLogger(ContentBackfillService.class);

    public record Result(int enqueued, int skipped, List<String> languages,
                         List<String> entityTypes) {
    }

    private final ContentTranslationStore translations;
    private final TranslationJobStore jobs;
    private final ContentSourceCatalog sources;
    private final LanguageCatalog languages;
    private final ContentTranslationService service;

    public ContentBackfillService(ContentTranslationStore translations,
                                  TranslationJobStore jobs,
                                  ContentSourceCatalog sources,
                                  LanguageCatalog languages,
                                  ContentTranslationService service) {
        this.translations = translations;
        this.jobs = jobs;
        this.sources = sources;
        this.languages = languages;
        this.service = service;
    }

    @Transactional
    public Result backfill(List<String> requestedLanguages, List<String> requestedEntityTypes,
                           boolean dryRun) {
        List<String> targets = resolveLanguages(requestedLanguages);
        List<String> entityTypes = resolveEntityTypes(requestedEntityTypes);
        int enqueued = 0;
        int skipped = 0;
        for (String entityType : entityTypes) {
            for (RegistryField field : translations.fields(entityType)) {
                Counted counted = backfillField(entityType, field.field(), targets, dryRun);
                enqueued += counted.enqueued();
                skipped += counted.skipped();
            }
        }
        log.info("backfill enqueued={} skipped={} languages={} entityTypes={} dryRun={}",
                enqueued, skipped, targets, entityTypes, dryRun);
        return new Result(enqueued, skipped, targets, entityTypes);
    }

    private Counted backfillField(String entityType, String field, List<String> targets,
                                  boolean dryRun) {
        List<ContentSourceCatalog.Source> sourceRows =
                sources.sources(entityType, field, languages.defaultLanguage());
        if (sourceRows.isEmpty()) {
            return Counted.ZERO;
        }
        Set<String> entityIds = new LinkedHashSet<>();
        for (ContentSourceCatalog.Source source : sourceRows) {
            if (source.text() != null && !source.text().isBlank()) {
                entityIds.add(source.entityId());
            }
        }
        if (entityIds.isEmpty()) {
            return Counted.ZERO;
        }
        Map<String, TranslationRow> rows = new LinkedHashMap<>();
        for (TranslationRow row : translations.findMany(entityType, entityIds, List.of(field),
                targets)) {
            rows.put(rowsKey(row.entityId(), row.lang()), row);
        }
        Map<String, String> states = jobs.statesFor(entityType, field, entityIds, targets,
                TranslationJobStore.FROM_CANONICAL);

        int enqueued = 0;
        int skipped = 0;
        for (ContentSourceCatalog.Source source : sourceRows) {
            if (source.text() == null || source.text().isBlank()) {
                continue;
            }
            String hash = service.hash(source.text());
            for (String lang : targets) {
                String key = rowsKey(source.entityId(), lang);
                TranslationRow row = rows.get(key);
                if (!needsTranslation(row, hash)) {
                    skipped++;
                    continue;
                }
                if (row != null && "AUTHORED".equals(row.origin())) {
                    // Human-authored text is never replaced by machine output; the
                    // stale row stays for a reviewer to edit.
                    skipped++;
                    continue;
                }
                String state = states.get(key);
                if ("PENDING".equals(state) || "RUNNING".equals(state)) {
                    skipped++;
                    continue;
                }
                boolean pending = dryRun
                        ? state == null || "DONE".equals(state) || "FAILED".equals(state)
                        : jobs.enqueueIfPending(entityType, source.entityId(), field, lang,
                                TranslationJobStore.FROM_CANONICAL);
                if (pending) {
                    enqueued++;
                } else {
                    skipped++;
                }
            }
        }
        return new Counted(enqueued, skipped);
    }

    /** Missing/blank, explicitly stale, or a hash that no longer matches the source. */
    private static boolean needsTranslation(TranslationRow row, String sourceHash) {
        if (row == null || row.body() == null || row.body().isBlank()) {
            return true;
        }
        if ("STALE".equals(row.status())) {
            return true;
        }
        return !sourceHash.equals(row.sourceHash());
    }

    private List<String> resolveLanguages(List<String> requested) {
        if (requested == null || requested.isEmpty()) {
            List<String> defaults = new ArrayList<>();
            for (String language : translations.liveLanguages()) {
                if (!language.equals(languages.defaultLanguage())) {
                    defaults.add(language);
                }
            }
            return defaults;
        }
        List<String> result = new ArrayList<>();
        for (String value : requested) {
            String lang = languages.normalize(value);
            if (lang.isBlank() || !languages.isSupported(lang)) {
                throw ApiException.validation("LANGUAGE_UNKNOWN", "Unknown language code",
                        List.of(FieldIssue.of("languages", "LANGUAGE_UNKNOWN",
                                "error.locale.invalid")));
            }
            if (lang.equals(languages.defaultLanguage())) {
                throw ApiException.validation("LANGUAGE_DEFAULT",
                        "Cannot backfill the canonical source language",
                        List.of(FieldIssue.of("languages", "DEFAULT_LANGUAGE",
                                "error.locale.invalid")));
            }
            if (!result.contains(lang)) {
                result.add(lang);
            }
        }
        return result;
    }

    private List<String> resolveEntityTypes(List<String> requested) {
        if (requested == null || requested.isEmpty()) {
            List<String> defaults = new ArrayList<>();
            for (RegistryField field : translations.fields(null)) {
                if (!defaults.contains(field.entityType())) {
                    defaults.add(field.entityType());
                }
            }
            return defaults;
        }
        List<String> result = new ArrayList<>();
        for (String value : requested) {
            String entityType = ContentSourceCatalog.canonicalEntityType(value);
            if (entityType.isBlank() || !sources.isKnownEntityType(entityType)) {
                throw ApiException.validation("ENTITY_TYPE_UNKNOWN", "Unknown entity type",
                        List.of(FieldIssue.of("entityTypes", "ENTITY_TYPE_UNKNOWN",
                                "error.field.invalid")));
            }
            if (!result.contains(entityType)) {
                result.add(entityType);
            }
        }
        return result;
    }

    private static String rowsKey(String entityId, String lang) {
        return entityId + "|" + lang;
    }

    private record Counted(int enqueued, int skipped) {
        static final Counted ZERO = new Counted(0, 0);
    }
}
