package com.truereport.shared.i18n;

import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import com.truereport.shared.i18n.TranslationReviewRequiredException.Issue;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Safety gate for machine-derived/reviewed content. The default mode only
 * checks fields marked {@code safety_critical}; {@code all} checks every
 * registered field and {@code off} disables the gate.
 */
@Service
public class TranslationReviewGate {

    private static final int MAX_ISSUES = 50;

    private final ContentTranslationStore translations;
    private final ContentSourceCatalog sources;
    private final LanguageCatalog languages;
    private final ContentTranslationService service;
    private final String mode;

    public TranslationReviewGate(ContentTranslationStore translations,
                                 ContentSourceCatalog sources,
                                 LanguageCatalog languages,
                                 ContentTranslationService service,
                                 @Value("${truereport.i18n.review.gate:safety_critical}")
                                 String mode) {
        this.translations = translations;
        this.sources = sources;
        this.languages = languages;
        this.service = service;
        this.mode = mode == null ? "safety_critical" : mode.trim().toLowerCase();
    }

    public String mode() {
        return mode;
    }

    public void assertTemplatePublish(Collection<String> itemVersionIds) {
        if ("off".equals(mode) || itemVersionIds == null || itemVersionIds.isEmpty()) {
            return;
        }
        List<Issue> issues = canonicalIssues("ITEM", itemVersionIds);
        failIfAny(issues);
    }

    public void assertLanguageReady(String lang) {
        if ("off".equals(mode)) {
            return;
        }
        List<Issue> issues = languageIssues(lang);
        failIfAny(issues);
    }

    /** Job publish gate: only the job's rendered item versions, not the whole library. */
    public void assertJobPublish(Collection<String> itemVersionIds, String lang) {
        String target = languages.normalize(lang);
        if ("off".equals(mode) || target.isBlank()
                || target.equals(languages.defaultLanguage())
                || itemVersionIds == null || itemVersionIds.isEmpty()) {
            return;
        }
        failIfAny(languageIssuesFor("ITEM", itemVersionIds, target));
    }

    public List<Issue> languageIssuesFor(String entityType, Collection<String> entityIds,
                                         String lang) {
        List<Issue> issues = new ArrayList<>();
        String target = languages.normalize(lang);
        if ("off".equals(mode) || target.isBlank()
                || target.equals(languages.defaultLanguage())) {
            return issues;
        }
        String defaultLang = languages.defaultLanguage();
        for (RegistryField field : fields(entityType)) {
            for (String entityId : entityIds) {
                if (issues.size() >= MAX_ISSUES) {
                    return issues;
                }
                String source = sources.source(entityType, entityId, field.field(), defaultLang);
                if (source == null || source.isBlank()) {
                    continue;
                }
                TranslationRow row = translations.find(entityType, entityId, field.field(),
                        target).orElse(null);
                if (row == null || row.body() == null || row.body().isBlank()) {
                    issues.add(issue(entityType, entityId, field.field(), target, "MISSING"));
                    continue;
                }
                if (!"REVIEWED".equals(row.status())) {
                    issues.add(issue(entityType, entityId, field.field(), target,
                            "STALE".equals(row.status()) ? "STALE" : "PENDING_REVIEW"));
                } else if (!hash(source).equals(row.sourceHash())) {
                    issues.add(issue(entityType, entityId, field.field(), target, "STALE"));
                }
            }
        }
        return issues;
    }

    public List<Issue> canonicalIssues(String entityType, Collection<String> entityIds) {
        List<Issue> issues = new ArrayList<>();
        if ("off".equals(mode)) {
            return issues;
        }
        String defaultLang = languages.defaultLanguage();
        for (RegistryField field : fields(entityType)) {
            for (String entityId : entityIds) {
                if (issues.size() >= MAX_ISSUES) {
                    return issues;
                }
                String source = sources.source(entityType, entityId, field.field(), defaultLang);
                if (source == null || source.isBlank()) {
                    continue;
                }
                TranslationRow row = translations.find(entityType, entityId, field.field(),
                        defaultLang).orElse(null);
                if (row == null) {
                    // Human-authored canonical text: no provenance row to review.
                    continue;
                }
                if (!"REVIEWED".equals(row.status())) {
                    issues.add(issue(entityType, entityId, field.field(), defaultLang,
                            "STALE".equals(row.status()) ? "STALE" : "PENDING_REVIEW"));
                } else if (!hash(source).equals(row.sourceHash())) {
                    issues.add(issue(entityType, entityId, field.field(), defaultLang, "STALE"));
                }
            }
        }
        return issues;
    }

    public List<Issue> languageIssues(String lang) {
        String target = languages.normalize(lang);
        List<Issue> issues = new ArrayList<>();
        if ("off".equals(mode) || target.isBlank()
                || target.equals(languages.defaultLanguage())) {
            return issues;
        }
        String defaultLang = languages.defaultLanguage();
        for (RegistryField field : allFields()) {
            for (ContentSourceCatalog.Source source : sources.sources(field.entityType(),
                    field.field(), defaultLang)) {
                if (issues.size() >= MAX_ISSUES) {
                    return issues;
                }
                TranslationRow row = translations.find(field.entityType(), source.entityId(),
                        field.field(), target).orElse(null);
                if (row == null || row.body() == null || row.body().isBlank()) {
                    issues.add(issue(field.entityType(), source.entityId(), field.field(),
                            target, "MISSING"));
                    continue;
                }
                if (!"REVIEWED".equals(row.status())) {
                    issues.add(issue(field.entityType(), source.entityId(), field.field(),
                            target, "STALE".equals(row.status()) ? "STALE" : "PENDING_REVIEW"));
                } else if (!hash(source.text()).equals(row.sourceHash())) {
                    issues.add(issue(field.entityType(), source.entityId(), field.field(),
                            target, "STALE"));
                }
            }
        }
        return issues;
    }

    private List<RegistryField> fields(String entityType) {
        List<RegistryField> result = new ArrayList<>();
        for (RegistryField field : translations.fields(entityType)) {
            if (applies(field)) {
                result.add(field);
            }
        }
        return result;
    }

    private List<RegistryField> allFields() {
        List<RegistryField> result = new ArrayList<>();
        for (RegistryField field : translations.fields(null)) {
            if (applies(field)) {
                result.add(field);
            }
        }
        return result;
    }

    private boolean applies(RegistryField field) {
        return "all".equals(mode) || field.safetyCritical();
    }

    private void failIfAny(List<Issue> issues) {
        if (!issues.isEmpty()) {
            throw new TranslationReviewRequiredException(issues);
        }
    }

    private static Issue issue(String entityType, String entityId, String field, String lang,
                               String reason) {
        return new Issue(entityType, entityId, field, lang, reason);
    }

    private String hash(String source) {
        return service.hash(source);
    }
}
