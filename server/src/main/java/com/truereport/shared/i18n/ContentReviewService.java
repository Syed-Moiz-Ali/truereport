package com.truereport.shared.i18n;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.ReviewRow;
import com.truereport.shared.i18n.ContentTranslationStore.StateCount;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ContentReviewService {

    public record ReviewItem(String entityType, String entityId, String field, String lang,
                             String body, String origin, String status, String provider,
                             String sourceText, boolean safetyCritical, String reviewNote) {
    }

    public record Summary(String lang, Map<String, Integer> states,
                          int safetyCriticalPendingReview, int safetyCriticalBlocked) {
    }

    private static final List<String> STATES =
            List.of("DRAFT", "PENDING_REVIEW", "REVIEWED", "STALE");
    private static final List<String> ACTIONS = List.of("APPROVE", "EDIT", "REJECT");

    private final ContentTranslationStore translations;
    private final ContentSourceCatalog sources;
    private final LanguageCatalog languages;
    private final ContentTranslationService resolver;

    public ContentReviewService(ContentTranslationStore translations,
                                ContentSourceCatalog sources,
                                LanguageCatalog languages,
                                ContentTranslationService resolver) {
        this.translations = translations;
        this.sources = sources;
        this.languages = languages;
        this.resolver = resolver;
    }

    @Transactional(readOnly = true)
    public List<ReviewItem> queue(String lang, String state, String entityType, int page, int size) {
        String target = requireLanguage(lang);
        String status = normalizeState(state);
        String type = entityType == null || entityType.isBlank()
                ? null : ContentSourceCatalog.canonicalEntityType(entityType);
        int safeSize = Math.min(100, Math.max(1, size));
        int safePage = Math.max(0, page);
        return translations.reviewQueue(target, status, type, safeSize, safePage * safeSize)
                .stream().map(row -> toItem(row)).toList();
    }

    @Transactional(readOnly = true)
    public Summary summary(String lang) {
        String target = requireLanguage(lang);
        Map<String, Integer> states = new LinkedHashMap<>();
        for (String state : STATES) {
            states.put(state, 0);
        }
        for (StateCount count : translations.summary(target)) {
            states.put(count.state(), count.count());
        }
        return new Summary(target, states,
                translations.countByStatusSafety(target, "PENDING_REVIEW", true),
                translations.countByStatusSafety(target, "PENDING_REVIEW", true)
                        + translations.countByStatusSafety(target, "STALE", true));
    }

    @Transactional
    public ReviewItem review(String entityType, String entityId, String field, String lang,
                             String action, String body, String note, String actorId) {
        String type = ContentSourceCatalog.canonicalEntityType(entityType);
        String id = ContentSourceCatalog.canonicalEntityId(entityId)
                .orElseThrow(ApiException::notFound);
        String target = requireLanguage(lang);
        String normalizedAction = action == null ? "" : action.trim().toUpperCase();
        if (!ACTIONS.contains(normalizedAction)) {
            throw ApiException.validation("REVIEW_ACTION_INVALID",
                    "Review action must be APPROVE, EDIT or REJECT",
                    List.of(FieldIssue.of("action", "INVALID", "error.field.invalid")));
        }
        TranslationRow row = translations.find(type, id, field, target)
                .orElseThrow(ApiException::notFound);
        RegistryField registryField = translations.field(type, field)
                .orElseThrow(ApiException::notFound);

        switch (normalizedAction) {
            case "APPROVE" -> translations.markReview(type, id, field, target, "REVIEWED",
                    actorId, note);
            case "REJECT" -> {
                translations.markReview(type, id, field, target, "STALE", actorId, note);
                if (target.equals(languages.defaultLanguage())) {
                    // The canonical English is no longer trustworthy: authored
                    // languages stay as the only reliable copy.
                    translations.markMachineStale(type, id, field, target);
                }
            }
            case "EDIT" -> {
                if (body == null || body.isBlank()) {
                    throw ApiException.validation("BODY_REQUIRED",
                            "Edited translation body is required",
                            List.of(FieldIssue.of("body", "REQUIRED",
                                    "error.field.invalid")));
                }
                String text = body.trim();
                if (text.length() > registryField.maxLength()) {
                    throw ApiException.validation("BODY_TOO_LONG",
                            "Translation exceeds the maximum length of "
                                    + registryField.maxLength(),
                            List.of(FieldIssue.of("body", "MAX_LENGTH",
                                    "error.field.invalid")));
                }
                String source = sources.source(type, id, field, languages.defaultLanguage());
                translations.edit(type, id, field, target, text,
                        resolver.hash(source == null ? "" : source), actorId, note);
            }
            default -> throw new IllegalStateException("Unhandled review action");
        }
        resolver.invalidate(type, id);
        TranslationRow updated = translations.find(type, id, field, target)
                .orElseThrow(ApiException::notFound);
        String source = sources.source(type, id, field, languages.defaultLanguage());
        boolean safety = translations.field(type, field)
                .map(RegistryField::safetyCritical).orElse(false);
        return new ReviewItem(type, id, field, target, updated.body(), updated.origin(),
                updated.status(), updated.provider(), source, safety, note);
    }

    private ReviewItem toItem(ReviewRow row) {
        String source = sources.source(row.entityType(), row.entityId(), row.field(),
                languages.defaultLanguage());
        boolean safety = translations.field(row.entityType(), row.field())
                .map(RegistryField::safetyCritical).orElse(false);
        return new ReviewItem(row.entityType(), row.entityId(), row.field(), row.lang(),
                row.body(), row.origin(), row.status(), row.provider(), source, safety,
                row.reviewNote());
    }

    private String requireLanguage(String lang) {
        String target = languages.normalize(lang);
        if (target.isBlank() || !languages.isSupported(target)) {
            throw ApiException.validation("LANGUAGE_UNKNOWN", "Unknown language code",
                    List.of(FieldIssue.of("lang", "LANGUAGE_UNKNOWN", "error.locale.invalid")));
        }
        return target;
    }

    private static String normalizeState(String state) {
        String value = state == null || state.isBlank()
                ? "PENDING_REVIEW" : state.trim().toUpperCase();
        if (!STATES.contains(value)) {
            throw ApiException.validation("REVIEW_STATE_INVALID",
                    "Unknown review state",
                    List.of(FieldIssue.of("state", "INVALID", "error.field.invalid")));
        }
        return value;
    }
}
