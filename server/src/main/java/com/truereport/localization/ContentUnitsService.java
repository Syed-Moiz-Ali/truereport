package com.truereport.localization;

import com.truereport.localization.api.ContentTranslationDtos.ContentUnitDto;
import com.truereport.localization.api.ContentTranslationDtos.ContentUnitsPageDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.i18n.ContentSourceCatalog;
import com.truereport.shared.i18n.ContentTranslationService;
import com.truereport.shared.i18n.ContentTranslationStore;
import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import com.truereport.shared.i18n.LanguageCatalog;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Read-side inventory of every canonical content text unit for one target
 * language.
 *
 * <p>The coverage report counts units per field, and the review queue only sees
 * rows that already exist. A newly added language has neither, so an admin had
 * no way to enumerate what still needs typing. This service lists the canonical
 * units themselves — from the source tables, not from
 * {@code content_translation} — and joins the target row when present. Units
 * with no row (or a blank body) are returned with {@code text/status/origin}
 * set to {@code null}.</p>
 *
 * <p>Strictly read-only: no provider calls, no jobs, no writes.</p>
 */
@Service
public class ContentUnitsService {

    /** Canonical unit order: platform groups first, then any other enabled group. */
    private static final List<String> GROUP_ORDER = TranslationFieldRegistry.GROUP_ORDER;
    private static final String ALL = "all";
    private static final String MISSING = "missing";
    private static final int MAX_SIZE = 200;

    private static final Comparator<ContentSourceCatalog.Source> SOURCE_ORDER =
            Comparator.comparing(ContentSourceCatalog.Source::text,
                            String.CASE_INSENSITIVE_ORDER)
                    .thenComparing(ContentSourceCatalog.Source::text)
                    .thenComparing(ContentSourceCatalog.Source::entityId);

    private final ContentTranslationStore translations;
    private final ContentSourceCatalog catalog;
    private final LanguageCatalog languages;
    private final ContentTranslationService resolver;

    public ContentUnitsService(ContentTranslationStore translations,
                               ContentSourceCatalog catalog,
                               LanguageCatalog languages,
                               ContentTranslationService resolver) {
        this.translations = translations;
        this.catalog = catalog;
        this.languages = languages;
        this.resolver = resolver;
    }

    @Transactional(readOnly = true)
    public ContentUnitsPageDto units(String lang, String entityType, String filter, String query,
                                     int page, int size) {
        String target = resolver.requireWritableTarget(lang);
        String type = resolveEntityType(entityType);
        String mode = normalizeFilter(filter);
        String needle = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);
        int safeSize = Math.min(MAX_SIZE, Math.max(1, size));
        int safePage = Math.max(0, page);

        List<ContentUnitDto> units = collect(type, target, mode, needle);
        int total = units.size();
        int from = (int) Math.min(total, (long) safePage * safeSize);
        int to = Math.min(total, from + safeSize);
        return new ContentUnitsPageDto(target, total, safePage, safeSize,
                List.copyOf(units.subList(from, to)));
    }

    /**
     * {@code null} means every enabled entity type. A supplied type must be an
     * enabled {@code translatable_field} group; anything else is a 422, the same
     * contract the write endpoint uses for unknown fields.
     */
    private String resolveEntityType(String entityType) {
        if (entityType == null || entityType.isBlank()) {
            return null;
        }
        String type = ContentSourceCatalog.canonicalEntityType(entityType);
        if (type.isBlank() || translations.fields(type).isEmpty()) {
            throw ApiException.validation("ENTITY_TYPE_UNKNOWN", "Unknown entity type",
                    List.of(FieldIssue.of("entityType", "ENTITY_TYPE_UNKNOWN",
                            "error.field.invalid")));
        }
        return type;
    }

    private static String normalizeFilter(String filter) {
        String value = filter == null || filter.isBlank()
                ? ALL : filter.trim().toLowerCase(Locale.ROOT);
        if (!ALL.equals(value) && !MISSING.equals(value)) {
            throw ApiException.validation("FILTER_INVALID", "Filter must be all or missing",
                    List.of(FieldIssue.of("filter", "INVALID", "error.field.invalid")));
        }
        return value;
    }

    private List<ContentUnitDto> collect(String entityType, String target, String mode,
                                         String needle) {
        Map<String, List<RegistryField>> byType = new LinkedHashMap<>();
        for (RegistryField field : translations.fields(entityType)) {
            byType.computeIfAbsent(field.entityType(), ignored -> new ArrayList<>()).add(field);
        }
        List<String> orderedTypes = new ArrayList<>(GROUP_ORDER);
        for (String candidate : byType.keySet()) {
            if (!orderedTypes.contains(candidate)) {
                orderedTypes.add(candidate);
            }
        }
        orderedTypes.retainAll(byType.keySet());

        List<ContentUnitDto> units = new ArrayList<>();
        for (String type : orderedTypes) {
            for (RegistryField field : orderedFields(byType.get(type))) {
                units.addAll(unitsForField(type, field, target, mode, needle));
            }
        }
        return units;
    }

    /** Registry field order (label, instruction, standardSpec…), then unknown fields. */
    private static List<RegistryField> orderedFields(List<RegistryField> fields) {
        List<String> preferred = TranslationFieldRegistry.fieldsFor(fields.get(0).entityType());
        return fields.stream()
                .sorted(Comparator.comparingInt((RegistryField field) -> {
                            int index = preferred.indexOf(field.field());
                            return index < 0 ? Integer.MAX_VALUE : index;
                        })
                        .thenComparing(RegistryField::field))
                .toList();
    }

    private List<ContentUnitDto> unitsForField(String entityType, RegistryField field,
                                               String target, String mode, String needle) {
        List<ContentSourceCatalog.Source> ordered = new ArrayList<>();
        Set<String> ids = new LinkedHashSet<>();
        for (ContentSourceCatalog.Source source
                : catalog.sources(entityType, field.field(), languages.defaultLanguage())) {
            if (source.text() == null || source.text().isBlank()) {
                continue;
            }
            if (ids.add(source.entityId())) {
                ordered.add(source);
            }
        }
        if (ordered.isEmpty()) {
            return List.of();
        }
        ordered.sort(SOURCE_ORDER);

        Map<String, TranslationRow> rows = new LinkedHashMap<>();
        for (TranslationRow row : translations.findMany(entityType, ids,
                List.of(field.field()), List.of(target))) {
            rows.putIfAbsent(row.entityId(), row);
        }

        List<ContentUnitDto> units = new ArrayList<>();
        for (ContentSourceCatalog.Source source : ordered) {
            TranslationRow row = rows.get(source.entityId());
            boolean translated = row != null && row.body() != null && !row.body().isBlank();
            if (MISSING.equals(mode) && translated) {
                continue;
            }
            if (!needle.isEmpty() && !matches(source.text(),
                    translated ? row.body() : null, needle)) {
                continue;
            }
            units.add(new ContentUnitDto(entityType, source.entityId(), field.field(),
                    source.text(),
                    translated ? row.body() : null,
                    translated ? row.status() : null,
                    translated ? row.origin() : null,
                    field.safetyCritical()));
        }
        return units;
    }

    private static boolean matches(String sourceText, String translatedText, String needle) {
        if (sourceText != null && sourceText.toLowerCase(Locale.ROOT).contains(needle)) {
            return true;
        }
        return translatedText != null
                && translatedText.toLowerCase(Locale.ROOT).contains(needle);
    }

}
