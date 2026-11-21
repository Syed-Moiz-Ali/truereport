package com.truereport.shared.i18n;

import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Additive translation status for admin reads. One bulk row query per entity
 * type; no per-field N+1.
 */
@Service
public class TranslationStatusService {

    public static final String OK = "OK";
    public static final String MACHINE_PENDING_REVIEW = "MACHINE_PENDING_REVIEW";
    public static final String STALE = "STALE";
    public static final String MISSING = "MISSING";
    public static final String AUTHORING_PENDING = "AUTHORING_PENDING";

    private final ContentTranslationStore translations;
    private final TranslationJobStore jobs;
    private final ContentSourceCatalog sources;
    private final LanguageCatalog languages;
    private final ContentTranslationService resolver;

    public TranslationStatusService(ContentTranslationStore translations, TranslationJobStore jobs,
                                    ContentSourceCatalog sources, LanguageCatalog languages,
                                    ContentTranslationService resolver) {
        this.translations = translations;
        this.jobs = jobs;
        this.sources = sources;
        this.languages = languages;
        this.resolver = resolver;
    }

    /** Kept for the canonical (default-language) admin read. */
    public Map<String, String> statuses(String entityType, Collection<String> entityIds) {
        return rollup(entityType, entityIds, languages.defaultLanguage());
    }

    /**
     * Rollup per requested language. For the default language only non-OK
     * statuses are returned so existing English payloads stay unchanged; for
     * any other language every entity gets a status.
     */
    public Map<String, String> rollup(String entityType, Collection<String> entityIds,
                                      String lang) {
        Map<String, String> result = new LinkedHashMap<>();
        if (entityIds == null || entityIds.isEmpty()) {
            return result;
        }
        String target = languages.normalize(lang);
        boolean canonical = target.equals(languages.defaultLanguage());
        List<RegistryField> fields = translations.fields(entityType);
        if (fields.isEmpty()) {
            return result;
        }
        List<String> fieldNames = fields.stream().map(RegistryField::field).toList();
        Map<String, TranslationRow> rows = new LinkedHashMap<>();
        for (TranslationRow row : translations.findMany(entityType, entityIds,
                fieldNames, List.of(canonical ? languages.defaultLanguage() : target))) {
            rows.put(row.entityId() + "|" + row.field(), row);
        }
        for (String id : entityIds) {
            String worst = OK;
            boolean anySource = false;
            for (RegistryField field : fields) {
                String source = sources.source(entityType, id, field.field(),
                        languages.defaultLanguage());
                if (source == null || source.isBlank()) {
                    continue;
                }
                anySource = true;
                TranslationRow row = rows.get(id + "|" + field.field());
                String status = classify(row, source, canonical);
                if (canonical && OK.equals(status) && row == null) {
                    // Human-authored canonical text: no provenance to report.
                    continue;
                }
                worst = worse(worst, status);
            }
            if (canonical) {
                if (!OK.equals(worst)) {
                    result.put(id, worst);
                }
            } else if (anySource) {
                result.put(id, worst);
            }
        }
        return result;
    }

    /** Per-field status map for the detail endpoint. */
    public Map<String, String> fieldStatuses(String entityType, String entityId, String lang) {
        Map<String, String> result = new LinkedHashMap<>();
        String target = languages.normalize(lang);
        boolean canonical = target.equals(languages.defaultLanguage());
        for (RegistryField field : translations.fields(entityType)) {
            String source = sources.source(entityType, entityId, field.field(),
                    languages.defaultLanguage());
            if (source == null || source.isBlank()) {
                continue;
            }
            TranslationRow row = translations.find(entityType, entityId, field.field(), target)
                    .orElse(null);
            String status = classify(row, source, canonical);
            if (canonical && OK.equals(status) && row == null) {
                continue;
            }
            result.put(field.field(), status);
        }
        if (canonical && result.isEmpty()) {
            Set<String> authoring = new LinkedHashSet<>(jobs.pendingEntityIds(entityType,
                    TranslationJobStore.TO_CANONICAL, List.of(entityId)));
            if (!authoring.isEmpty()) {
                result.put("__authoring", AUTHORING_PENDING);
            }
        }
        return result;
    }

    private String classify(TranslationRow row, String source, boolean canonical) {
        if (row == null) {
            return canonical ? OK : MISSING;
        }
        if (canonical && !"MACHINE".equals(row.origin())) {
            // Human-authored canonical rows are not gated by provenance.
            return "REVIEWED".equals(row.status()) ? OK : MACHINE_PENDING_REVIEW;
        }
        if (!"REVIEWED".equals(row.status())) {
            return STALE.equals(row.status()) ? STALE : MACHINE_PENDING_REVIEW;
        }
        if (!resolver.hash(source).equals(row.sourceHash())) {
            return STALE;
        }
        return OK;
    }

    private static String worse(String left, String right) {
        List<String> priority = List.of(OK, MISSING, MACHINE_PENDING_REVIEW, STALE);
        return priority.indexOf(right) > priority.indexOf(left) ? right : left;
    }
}
