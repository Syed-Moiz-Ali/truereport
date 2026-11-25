package com.truereport.shared.i18n;

import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Lookup-only resolver for authored content translations.
 *
 * <p>Exact target-language hit wins, then the default-language row, then the
 * supplied English source. A row whose {@code source_hash} no longer matches the
 * current English text is treated as stale and falls back to English; the
 * coverage report surfaces it as {@code stale}. No machine translation happens
 * here.</p>
 */
@Service
public class ContentTranslationService {

    private static final int MAX_CACHE_ENTRIES = 20_000;

    public record Coverage(String entityType, String field, int total, int translated,
                           int missing, int stale, int pendingReview, int blocked,
                           boolean safetyCritical) {
    }

    public record Translation(String entityType, String entityId, String field, String lang,
                              String body, String origin, String status, String sourceLang,
                              String sourceHash, String provider) {
    }

    private final ContentTranslationStore store;
    private final ContentSourceCatalog sources;
    private final LanguageCatalog languages;
    private final Map<String, String> cache = new ConcurrentHashMap<>();

    public ContentTranslationService(ContentTranslationStore store,
                                     ContentSourceCatalog sources,
                                     LanguageCatalog languages) {
        this.store = store;
        this.sources = sources;
        this.languages = languages;
    }

    public String defaultLanguage() {
        return languages.defaultLanguage();
    }

    /** Clears every cached translation, e.g. after a bulk review decision. */
    public void invalidateAll() {
        cache.clear();
    }

    public boolean isSupported(String lang) {
        return languages.isSupported(lang);
    }

    public String resolve(String entityType, UUID entityId, String field, String lang,
                          String englishFallback) {
        return resolve(entityType, entityId == null ? null : entityId.toString(), field, lang,
                englishFallback);
    }

    public String resolve(String entityType, String entityId, String field, String lang,
                          String englishFallback) {
        String target = languages.normalize(lang);
        String fallback = englishFallback == null ? "" : englishFallback;
        if (target.isBlank() || target.equals(languages.defaultLanguage())) {
            return fallback;
        }
        String hash = hash(fallback);
        String key = cacheKey(entityType, entityId, field, target, hash);
        String cached = cache.get(key);
        if (cached != null) {
            return cached;
        }
        TranslationRow row = store.find(entityType, entityId, field, target).orElse(null);
        if (servable(row, hash)) {
            cachePut(key, row.body());
            return row.body();
        }
        return fallback;
    }

    /**
     * Only human-approved text is served. Machine output waiting in the review
     * queue ({@code PENDING_REVIEW}), drafts and stale rows fall back to the
     * canonical English source.
     */
    private static boolean servable(TranslationRow row, String sourceHash) {
        return row != null
                && "REVIEWED".equals(row.status())
                && row.body() != null
                && !row.body().isBlank()
                && sourceHash.equals(row.sourceHash());
    }

    /**
     * Bulk resolver for list responses. One query for every entity/field pair;
     * the result mirrors {@code englishByEntity} with localized bodies where a
     * current translation exists.
     */
    public Map<String, Map<String, String>> resolveMany(
            String entityType, Map<String, Map<String, String>> englishByEntity, String lang) {
        String target = languages.normalize(lang);
        Map<String, Map<String, String>> result = new LinkedHashMap<>();
        if (target.isBlank() || target.equals(languages.defaultLanguage())
                || englishByEntity.isEmpty()) {
            englishByEntity.forEach((id, fields) ->
                    result.put(id, new LinkedHashMap<>(fields)));
            return result;
        }
        Set<String> ids = new LinkedHashSet<>();
        Set<String> fields = new LinkedHashSet<>();
        englishByEntity.forEach((id, values) -> {
            ids.add(id);
            fields.addAll(values.keySet());
        });
        List<TranslationRow> rows = store.findMany(entityType, ids, fields,
                List.of(target, languages.defaultLanguage()));
        Map<String, TranslationRow> byKey = new LinkedHashMap<>();
        for (TranslationRow row : rows) {
            byKey.put(row.entityId() + "|" + row.field() + "|" + row.lang(), row);
        }
        englishByEntity.forEach((id, values) -> {
            Map<String, String> localized = new LinkedHashMap<>();
            values.forEach((field, english) -> {
                String fallback = english == null ? "" : english;
                String hash = hash(fallback);
                TranslationRow row = byKey.get(id + "|" + field + "|" + target);
                if (servable(row, hash)) {
                    cachePut(cacheKey(entityType, id, field, target, hash), row.body());
                    localized.put(field, row.body());
                } else {
                    localized.put(field, fallback);
                }
            });
            result.put(id, localized);
        });
        return result;
    }

    @Transactional(readOnly = true)
    public List<Coverage> coverage(String lang, String entityTypeFilter) {
        String target = requireWritableTarget(lang);
        String entityType = entityTypeFilter == null || entityTypeFilter.isBlank()
                ? null : ContentSourceCatalog.canonicalEntityType(entityTypeFilter);
        List<RegistryField> registry = store.fields(entityType);
        List<Coverage> result = new ArrayList<>();
        for (RegistryField field : registry) {
            List<ContentSourceCatalog.Source> sourceRows =
                    sources.sources(field.entityType(), field.field(), languages.defaultLanguage());
            int total = sourceRows.size();
            int translated = 0;
            int stale = 0;
            int pendingReview = 0;
            int blocked = 0;
            if (total > 0) {
                Set<String> ids = new LinkedHashSet<>();
                for (ContentSourceCatalog.Source row : sourceRows) {
                    ids.add(row.entityId());
                }
                Map<String, TranslationRow> rows = new LinkedHashMap<>();
                for (TranslationRow row : store.findMany(field.entityType(), ids,
                        List.of(field.field()), List.of(target))) {
                    rows.put(row.entityId(), row);
                }
                for (ContentSourceCatalog.Source source : sourceRows) {
                    TranslationRow row = rows.get(source.entityId());
                    if (row == null || row.body() == null || row.body().isBlank()) {
                        continue;
                    }
                    if (hash(source.text()).equals(row.sourceHash())) {
                        translated++;
                    } else {
                        stale++;
                    }
                    if ("PENDING_REVIEW".equals(row.status())) {
                        pendingReview++;
                    }
                    if ("PENDING_REVIEW".equals(row.status()) || "STALE".equals(row.status())) {
                        blocked++;
                    }
                }
            }
            result.add(new Coverage(field.entityType(), field.field(), total, translated,
                    total - translated - stale, stale, pendingReview, blocked,
                    field.safetyCritical()));
        }
        return result;
    }

    @Transactional
    public Translation write(String entityType, String entityId, String field, String lang,
                             String body, String actorId) {
        String type = ContentSourceCatalog.canonicalEntityType(entityType);
        String id = ContentSourceCatalog.canonicalEntityId(type, entityId)
                .orElseThrow(ApiException::notFound);
        String target = requireWritableTarget(lang);
        RegistryField registryField = requireField(type, field);
        if (body == null || body.isBlank()) {
            throw ApiException.validation("BODY_REQUIRED", "Translation body is required",
                    List.of(FieldIssue.of("body", "REQUIRED", "error.field.invalid")));
        }
        String text = body.trim();
        if (text.length() > registryField.maxLength()) {
            throw ApiException.validation("BODY_TOO_LONG",
                    "Translation exceeds the maximum length of " + registryField.maxLength(),
                    List.of(FieldIssue.of("body", "MAX_LENGTH", "error.field.invalid")));
        }
        if (!sources.exists(type, id)) {
            throw ApiException.notFound();
        }
        String english = sources.source(type, id, registryField.field(), languages.defaultLanguage());
        String sourceHash = hash(english == null ? "" : english);
        store.upsert(type, id, registryField.field(), target, text, "AUTHORED", "REVIEWED",
                languages.defaultLanguage(), sourceHash, null, actorId);
        invalidate(type, id);
        TranslationRow row = store.find(type, id, registryField.field(), target)
                .orElseThrow();
        return new Translation(type, id, row.field(), row.lang(), row.body(), row.origin(),
                row.status(), row.sourceLang(), row.sourceHash(), row.provider());
    }

    @Transactional
    public void delete(String entityType, String entityId, String field, String lang) {
        String type = ContentSourceCatalog.canonicalEntityType(entityType);
        String id = ContentSourceCatalog.canonicalEntityId(type, entityId)
                .orElseThrow(ApiException::notFound);
        String target = requireWritableTarget(lang);
        RegistryField registryField = requireField(type, field);
        if (!sources.exists(type, id)) {
            throw ApiException.notFound();
        }
        store.delete(type, id, registryField.field(), target);
        invalidate(type, id);
    }

    public Optional<RegistryField> registryField(String entityType, String field) {
        return store.field(ContentSourceCatalog.canonicalEntityType(entityType), field);
    }

    public List<RegistryField> registryFields(String entityType) {
        return store.fields(entityType);
    }

    public String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    digest.digest((value == null ? "" : value).getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public void invalidate(String entityType, String entityId) {
        String prefix = entityType + "|" + entityId + "|";
        cache.keySet().removeIf(key -> key.startsWith(prefix));
    }

    private RegistryField requireField(String entityType, String field) {
        return store.field(entityType, field)
                .orElseThrow(() -> ApiException.validation("FIELD_NOT_TRANSLATABLE",
                        "Field is not registered as translatable",
                        List.of(FieldIssue.of("field", "NOT_TRANSLATABLE",
                                "error.field.invalid"))));
    }

    /**
     * Validates that {@code lang} is a supported, non-canonical target language.
     * Shared with the read-side authoring surfaces so they reject exactly the
     * same languages as {@link #write}.
     */
    public String requireWritableTarget(String lang) {
        String target = languages.normalize(lang);
        if (target.isBlank() || !languages.isSupported(target)) {
            throw ApiException.validation("LANGUAGE_UNKNOWN", "Unknown language code",
                    List.of(FieldIssue.of("lang", "LANGUAGE_UNKNOWN", "error.locale.invalid")));
        }
        if (target.equals(languages.defaultLanguage())) {
            throw ApiException.validation("LANGUAGE_DEFAULT", "Cannot translate the source language",
                    List.of(FieldIssue.of("lang", "DEFAULT_LANGUAGE", "error.locale.invalid")));
        }
        return target;
    }

    private static String cacheKey(String entityType, String entityId, String field,
                                   String lang, String hash) {
        return entityType + "|" + entityId + "|" + field + "|" + lang + "|" + hash;
    }

    private void cachePut(String key, String value) {
        if (cache.size() >= MAX_CACHE_ENTRIES) {
            cache.clear();
        }
        cache.put(key, value);
    }
}
