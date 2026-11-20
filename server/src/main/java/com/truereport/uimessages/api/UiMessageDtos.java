package com.truereport.uimessages.api;

import java.util.List;
import java.util.Map;

public final class UiMessageDtos {

    private UiMessageDtos() {
    }

    public record ManifestLanguageDto(String code, String name, String nativeName,
                                      String direction, int version) {
    }

    public record UiMessageManifestDto(
            String defaultLanguage,
            String client,
            List<String> namespaces,
            List<ManifestLanguageDto> languages) {
    }

    public record UiMessageBundleDto(
            String language,
            String fallbackLanguage,
            String client,
            List<String> namespaces,
            Map<String, Integer> versions,
            Map<String, Map<String, String>> catalogs,
            Map<String, String> messages) {
    }
}
