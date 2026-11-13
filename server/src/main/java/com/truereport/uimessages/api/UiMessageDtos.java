package com.truereport.uimessages.api;

import java.util.List;
import java.util.Map;

public final class UiMessageDtos {

    private UiMessageDtos() {
    }

    public record ManifestLanguageDto(String code, String direction, String nativeName,
                                      Map<String, Integer> versions,
                                      String path) {
    }

    public record UiMessageManifestDto(
            String defaultLanguage,
            Map<String, Integer> namespaces,
            List<ManifestLanguageDto> languages) {
    }

    public record UiMessageBundleDto(
            String language,
            String fallbackLanguage,
            Map<String, Integer> versions,
            Map<String, Map<String, String>> catalogs,
            Map<String, List<String>> missingKeys) {
    }
}
