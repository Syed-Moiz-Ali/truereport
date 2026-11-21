package com.truereport.shared.i18n;

import java.util.List;
import java.util.Map;

/**
 * Translation provider SPI. Implementations must return exactly one output per
 * input, in a map keyed by the input text, preserving order.
 */
public interface TranslationProvider {

    String id();

    Map<String, String> translate(List<String> texts, String sourceLang, String targetLang);
}
