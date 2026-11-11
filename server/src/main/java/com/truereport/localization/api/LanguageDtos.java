package com.truereport.localization.api;

import java.util.List;
import java.util.Map;

public final class LanguageDtos {

    private LanguageDtos() {
    }

    public record LanguageDto(
            String code,
            String nameEn,
            String nameAr,
            String nativeName,
            String direction,
            boolean active,
            boolean isDefault,
            int sortOrder
    ) {
        public String name(LocaleView view) {
            return view == LocaleView.AR ? nameAr : nameEn;
        }
    }

    public enum LocaleView { EN, AR }

    public record CreateLanguageRequest(
            String code,
            String nameEn,
            String nameAr,
            String nativeName,
            String direction,
            Boolean active,
            Integer sortOrder
    ) {
    }

    public record UpdateLanguageRequest(
            String nameEn,
            String nameAr,
            String nativeName,
            String direction,
            Boolean active,
            Integer sortOrder
    ) {
    }

    public record ReorderLanguagesRequest(List<String> orderedCodes) {
    }

    public record SetLanguageRequest(String language) {
    }

    public record MeLanguageDto(String language, String direction, String fallback) {
    }

    public record CoverageNamespace(int total, List<String> missing) {
    }

    public record TranslationCoverageDto(List<String> languages,
                                         Map<String, CoverageNamespace> namespaces) {
    }
}
