package com.truereport.localization;

import com.truereport.localization.api.ContentTranslationDtos.PlatformLanguageDto;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.shared.i18n.LanguageCatalog;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * Languages offered by the content review desk.
 *
 * <p>Every LIVE language except the canonical source is listed, even before it
 * has any {@code content_translation} row. That keeps the selector aligned with
 * the language registry, so an admin can see all three languages and knows
 * which one still needs a backfill instead of wondering why a language is
 * missing.</p>
 */
@Service
public class ContentLanguageService {

    private final LanguageRepository languages;
    private final LanguageCatalog catalog;

    public ContentLanguageService(LanguageRepository languages, LanguageCatalog catalog) {
        this.languages = languages;
        this.catalog = catalog;
    }

    @Transactional(readOnly = true)
    public List<PlatformLanguageDto> contentLanguages() {
        String canonical = languages.defaultCode();
        if (canonical == null || canonical.isBlank()) {
            canonical = catalog.defaultLanguage();
        }
        List<PlatformLanguageDto> result = new ArrayList<>();
        for (LanguageDto language : languages.findLive()) {
            if (language.code().equals(canonical)) {
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
