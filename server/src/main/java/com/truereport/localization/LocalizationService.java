package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.CoverageNamespace;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.MeLanguageDto;
import com.truereport.localization.api.LanguageDtos.TranslationCoverageDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.uimessages.PlatformUiMessageCatalog;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Read-only language registry plus per-user language preference.
 *
 * <p>Static UI languages are declared by the JSON manifest and synchronized
 * into the registry at startup. Platform Admin cannot add, edit, publish or
 * retire languages from the UI; changing the manifest and restarting is the
 * only supported workflow.</p>
 */
@Service
public class LocalizationService {

    private final LanguageRepository languages;
    private final TranslationBacklogService backlog;
    private final PlatformUiMessageCatalog catalog;

    public LocalizationService(LanguageRepository languages, TranslationBacklogService backlog,
                               PlatformUiMessageCatalog catalog) {
        this.languages = languages;
        this.backlog = backlog;
        this.catalog = catalog;
    }

    @Transactional(readOnly = true)
    public List<LanguageDto> activeLanguages() {
        // User-facing surfaces expose only languages that the manifest sync
        // marked LIVE and active.
        // English-only product: never expose another language to a client.
        return languages.findLive().stream()
                .filter(language -> "en".equalsIgnoreCase(language.code()))
                .toList();
    }

    /**
     * Platform Admin registry view: only languages declared by its static
     * manifest. Shared DB rows used by other apps are intentionally not
     * exposed here while Platform Admin is English-only.
     */
    @Transactional(readOnly = true)
    public List<LanguageDto> allLanguages() {
        // English-only product: the platform registry exposes only English.
        return languages.findLive().stream()
                .filter(language -> "en".equalsIgnoreCase(language.code()))
                .toList();
    }

    @Transactional(readOnly = true)
    public MeLanguageDto me(String userId) {
        String fallback = "en";
        String language = "en";
        LanguageDto dto = languages.find("en").orElse(null);
        String direction = dto == null ? "ltr" : dto.direction();
        return new MeLanguageDto(language, direction, fallback);
    }

    @Transactional
    public MeLanguageDto setMyLanguage(String userId, String code) {
        if (code == null || code.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        if (!"en".equalsIgnoreCase(code.trim())) {
            throw validation("language", "LANGUAGE_INACTIVE", "error.locale.invalid");
        }
        LanguageDto language = languages.find("en")
                .orElseThrow(() -> validation("language", "LANGUAGE_UNKNOWN",
                        "error.locale.invalid"));
        if (!language.active() || !"LIVE".equals(language.status())) {
            throw validation("language", "LANGUAGE_INACTIVE", "error.locale.invalid");
        }
        languages.savePreference(userId, language.code());
        return new MeLanguageDto(language.code(), language.direction(),
                languages.defaultCode() == null ? "en" : languages.defaultCode());
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

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid language request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
