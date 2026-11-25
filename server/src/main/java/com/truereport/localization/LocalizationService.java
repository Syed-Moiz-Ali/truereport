package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.CoverageNamespace;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.MeLanguageDto;
import com.truereport.localization.api.LanguageDtos.TranslationCoverageDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.i18n.LanguageCatalog;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Language registry plus per-user language preference.
 *
 * <p>The registry is the {@code platform_languages} table. Static manifest
 * languages are seeded at startup; Platform Admin can add a code at runtime,
 * which immediately registers it in {@link LanguageCatalog}. Retiring a language
 * is always a soft update so existing content translations are preserved and a
 * later re-create can reactivate them.</p>
 */
@Service
public class LocalizationService {

    /** Language tag accepted by the writer: {@code de}, {@code pt-BR}, {@code zh-Hant-TW}. */
    private static final Pattern LANGUAGE_CODE = Pattern.compile("^[a-z]{2,3}(-[a-z0-9]{2,8})*$");
    private static final int MAX_CODE_LENGTH = 16;

    private final LanguageRepository languages;
    private final TranslationBacklogService backlog;
    private final LanguageCatalog languageCatalog;
    private final com.truereport.shared.i18n.TranslationReviewGate reviewGate;
    private final com.truereport.uimessages.LanguageRegistryWriter registryWriter;
    private final WellKnownLanguages knownLanguages;

    public LocalizationService(LanguageRepository languages, TranslationBacklogService backlog,
                               LanguageCatalog languageCatalog,
                               com.truereport.shared.i18n.TranslationReviewGate reviewGate,
                               com.truereport.uimessages.LanguageRegistryWriter registryWriter,
                               WellKnownLanguages knownLanguages) {
        this.languages = languages;
        this.backlog = backlog;
        this.languageCatalog = languageCatalog;
        this.reviewGate = reviewGate;
        this.registryWriter = registryWriter;
        this.knownLanguages = knownLanguages;
    }

    /** Outcome of a create call: 201 for a new code, 200 for a reactivated row. */
    public record LanguageCreationResult(LanguageDto language, boolean created) {
    }

    @Transactional
    public LanguageDto goLive(String code) {
        String target = normalize(code);
        LanguageDto language = languages.find(target).orElseThrow(ApiException::notFound);
        reviewGate.assertLanguageReady(target);
        if (languages.updateStatus(target, "LIVE", true) == 0) {
            throw ApiException.notFound();
        }
        languageCatalog.register(target);
        registryWriter.register(target,
                knownLanguages.find(target).map(WellKnownLanguages.KnownLanguage::name)
                        .orElse(language.nativeName()),
                language.nativeName(), language.direction());
        return languages.find(target).orElseThrow(ApiException::notFound);
    }

    /**
     * Creates a LIVE language or reactivates a retired row with the supplied
     * metadata. The code is registered in the runtime catalog immediately, so
     * content units/authoring accept it without a restart.
     */
    @Transactional
    public LanguageCreationResult createLanguage(String code, String nativeName,
                                                 String direction) {
        String target = normalize(code);
        if (target.isEmpty() || target.length() > MAX_CODE_LENGTH
                || !LANGUAGE_CODE.matcher(target).matches()) {
            throw validation("code", "LANGUAGE_INVALID",
                    "Language code must match ^[a-z]{2,3}(-[a-z0-9]{2,8})*$");
        }
        if (target.equals(canonicalCode())) {
            throw validation("code", "LANGUAGE_DEFAULT",
                    "The default language cannot be created or replaced");
        }
        String resolvedDirection = direction(direction);
        String resolvedName = nativeName == null || nativeName.isBlank()
                ? target : nativeName.trim();
        if (resolvedName.length() > 80) {
            throw validation("nativeName", "LANGUAGE_INVALID",
                    "Native name must be at most 80 characters");
        }

        LanguageDto existing = languages.find(target).orElse(null);
        if (existing != null && existing.active() && "LIVE".equals(existing.status())) {
            throw ApiException.conflict("LANGUAGE_EXISTS",
                    "Language '" + target + "' is already live");
        }

        int sortOrder = languages.maxSortOrder() + 1;
        if (existing == null) {
            languages.insert(target, resolvedName, resolvedDirection, sortOrder);
        } else {
            languages.reactivate(target, resolvedName, resolvedDirection, sortOrder);
        }
        languageCatalog.register(target);
        // The manifest, the language switcher and the per-app catalogs all read
        // languages.json, so a new language must be written there too.
        String englishName = knownLanguages.find(target)
                .map(WellKnownLanguages.KnownLanguage::name)
                .orElse(resolvedName);
        registryWriter.register(target, englishName, resolvedName, resolvedDirection);
        return new LanguageCreationResult(
                languages.find(target).orElseThrow(ApiException::notFound), existing == null);
    }

    /**
     * Soft-retires a language: the row and every content translation remain, but
     * the language disappears from live lists and the runtime catalog.
     */
    @Transactional
    public LanguageDto retireLanguage(String code) {
        String target = normalize(code);
        if (target.isEmpty()) {
            throw ApiException.notFound();
        }
        if (target.equals(canonicalCode())) {
            throw validation("code", "LANGUAGE_DEFAULT",
                    "The default language cannot be retired");
        }
        LanguageDto existing = languages.find(target).orElseThrow(ApiException::notFound);
        if (existing.active() || !"RETIRED".equals(existing.status())) {
            if (languages.retire(target) == 0) {
                throw ApiException.notFound();
            }
        }
        languageCatalog.unregister(target);
        registryWriter.unregister(target);
        return languages.find(target).orElseThrow(ApiException::notFound);
    }

    @Transactional(readOnly = true)
    public List<LanguageDto> activeLanguages() {
        // Every live registry row is user-selectable. The manifest is only a seed.
        return languages.findLive();
    }

    /** Platform Admin registry view: every live language, in registry order. */
    @Transactional(readOnly = true)
    public List<LanguageDto> allLanguages() {
        return languages.findLive();
    }

    @Transactional(readOnly = true)
    public MeLanguageDto me(String userId) {
        String fallback = canonicalCode();
        LanguageDto selected = languages.preferredLanguage(userId)
                .flatMap(languages::find)
                .filter(LocalizationService::isActive)
                .orElseGet(() -> languages.find(fallback)
                        .filter(LocalizationService::isActive)
                        .orElse(null));
        String language = selected == null ? fallback : selected.code();
        String direction = selected == null ? "ltr" : selected.direction();
        return new MeLanguageDto(language, direction, fallback);
    }

    @Transactional
    public MeLanguageDto setMyLanguage(String userId, String code) {
        if (code == null || code.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        String target = normalize(code);
        LanguageDto language = languages.find(target)
                .filter(LocalizationService::isActive)
                .orElseThrow(() -> validation("language", "LANGUAGE_INACTIVE",
                        "error.locale.invalid"));
        languages.savePreference(userId, language.code());
        return new MeLanguageDto(language.code(), language.direction(), canonicalCode());
    }

    @Transactional(readOnly = true)
    public TranslationCoverageDto coverage() {
        List<String> codes = languages.findLive().stream().map(LanguageDto::code).toList();
        List<LanguageDto> targets = languages.findLive().stream()
                .filter(language -> !language.isDefault())
                .toList();
        Map<String, Integer> totals = new LinkedHashMap<>();
        Map<String, List<String>> missing = new LinkedHashMap<>();
        String[] namespaces = {"master.categories", "master.items", "master.options",
                "master.templates", "master.documentTypes"};
        String[] entityTypes = {"CATEGORY", "ITEM", "OPTION_VALUE", "TEMPLATE", "DOCUMENT_TYPE"};
        for (int i = 0; i < namespaces.length; i++) {
            totals.put(namespaces[i], 0);
            missing.put(namespaces[i], new ArrayList<>());
        }
        for (LanguageDto language : targets) {
            var backlogForLanguage = backlog.backlog(language.code());
            for (var group : backlogForLanguage.groups()) {
                int index = java.util.Arrays.asList(entityTypes).indexOf(group.entityType());
                if (index < 0) {
                    continue;
                }
                String namespace = namespaces[index];
                totals.merge(namespace, group.total(), Integer::sum);
                for (var item : group.items()) {
                    if (!"APPROVED".equals(item.status())) {
                        missing.get(namespace).add(language.code() + ":" + item.entityCode());
                    }
                }
            }
        }
        Map<String, CoverageNamespace> result = new LinkedHashMap<>();
        for (String namespace : namespaces) {
            result.put(namespace, new CoverageNamespace(
                    totals.getOrDefault(namespace, 0),
                    missing.getOrDefault(namespace, List.of())));
        }
        return new TranslationCoverageDto(codes, result);
    }

    private String canonicalCode() {
        String stored = languages.defaultCode();
        if (stored != null && !stored.isBlank()) {
            return normalize(stored);
        }
        return normalize(languageCatalog.defaultLanguage());
    }

    private static boolean isActive(LanguageDto language) {
        return language.active() && "LIVE".equals(language.status());
    }

    private static String direction(String direction) {
        if (direction == null || direction.isBlank()) {
            return "ltr";
        }
        String normalized = direction.trim().toLowerCase(Locale.ROOT);
        if (!"ltr".equals(normalized) && !"rtl".equals(normalized)) {
            throw validation("direction", "LANGUAGE_INVALID",
                    "Direction must be ltr or rtl");
        }
        return normalized;
    }

    private static String normalize(String code) {
        return code == null ? "" : code.trim().toLowerCase(Locale.ROOT);
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid language request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
