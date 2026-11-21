package com.truereport.localization;

import com.truereport.localization.api.ContentTranslationDtos.PlatformLanguageDto;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.shared.i18n.ContentTranslationStore;
import com.truereport.shared.i18n.LanguageCatalog;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Reviewable languages for the dynamic content-translation queue.
 *
 * <p>The source of truth is the live database registry
 * ({@code platform_languages}): an admin-created language appears here as soon
 * as it has at least one {@code content_translation} row. The canonical source
 * language is never reviewable. Metadata and ordering come from the registry
 * row, not from the static UI manifest.</p>
 */
@Service
public class ContentLanguageService {

    private final ContentTranslationStore translations;
    private final LanguageRepository languages;
    private final LanguageCatalog catalog;

    public ContentLanguageService(ContentTranslationStore translations,
                                  LanguageRepository languages,
                                  LanguageCatalog catalog) {
        this.translations = translations;
        this.languages = languages;
        this.catalog = catalog;
    }

    @Transactional(readOnly = true)
    public List<PlatformLanguageDto> contentLanguages() {
        List<String> present = translations.distinctLanguages();
        if (present.isEmpty()) {
            return List.of();
        }
        Set<String> presentCodes = new HashSet<>();
        for (String code : present) {
            String normalized = catalog.normalize(code);
            if (!normalized.isBlank()) {
                presentCodes.add(normalized);
            }
        }
        String canonical = languages.defaultCode();
        if (canonical == null || canonical.isBlank()) {
            canonical = catalog.defaultLanguage();
        }
        List<PlatformLanguageDto> result = new ArrayList<>();
        for (LanguageDto language : languages.findLive()) {
            if (language.code().equals(canonical) || !presentCodes.contains(language.code())) {
                continue;
            }
            result.add(new PlatformLanguageDto(
                    language.code(),
                    language.displayName(),
                    language.nativeName(),
                    language.direction(),
                    language.sortOrder()));
        }
        return List.copyOf(result);
    }
}
