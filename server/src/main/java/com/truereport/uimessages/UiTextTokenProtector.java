package com.truereport.uimessages;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class UiTextTokenProtector {

    public static final Set<String> TECHNICAL_TOKENS = Set.of(
            "CoreOS",
            "GRID V4.2 ONLINE",
            "Production Cluster EU-West",
            "ED25519-SHA512",
            "{}",
            "/",
            "-",
            "\u2014",
            "LTR",
            "RTL",
            "support@truereport.test");

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");
    private static final Pattern URL = Pattern.compile("https?://[^\\s]+");
    private static final Pattern EMAIL = Pattern.compile("[\\w.+-]+@[\\w.-]+\\.[A-Za-z]{2,}");
    private static final Pattern PROTECTED = buildPattern();

    public record Prepared(String original, String text, Map<String, String> tokens,
                           Set<String> placeholders) {
    }

    public boolean shouldSkip(String text) {
        if (text == null || text.isBlank()) {
            return true;
        }
        if (!Pattern.compile("\\p{L}").matcher(text).find()) {
            return true;
        }
        String trimmed = text.trim();
        if (TECHNICAL_TOKENS.contains(trimmed)) {
            return true;
        }
        return URL.matcher(trimmed).matches() || EMAIL.matcher(trimmed).matches();
    }

    public Prepared protect(String text) {
        Set<String> placeholders = new TreeSet<>();
        Matcher placeholderMatcher = PLACEHOLDER.matcher(text);
        while (placeholderMatcher.find()) {
            placeholders.add(placeholderMatcher.group(1));
        }
        Map<String, String> tokens = new LinkedHashMap<>();
        Matcher matcher = PROTECTED.matcher(text);
        StringBuffer protectedText = new StringBuffer();
        int index = 0;
        while (matcher.find()) {
            String token = "TRPH" + index + "QX";
            tokens.put(token, matcher.group());
            matcher.appendReplacement(protectedText, Matcher.quoteReplacement(token));
            index++;
        }
        matcher.appendTail(protectedText);
        return new Prepared(text, protectedText.toString(),
                Map.copyOf(tokens), Set.copyOf(placeholders));
    }

    public String restoreAndValidate(Prepared prepared, String translated) {
        if (translated == null || translated.isBlank()) {
            throw new UiTextTranslationException("Translation returned an empty value");
        }
        String restored = translated;
        for (Map.Entry<String, String> entry : prepared.tokens().entrySet()) {
            if (!restored.contains(entry.getKey())) {
                throw new UiTextTranslationException(
                        "Translation lost a protected token or placeholder");
            }
            restored = restored.replace(entry.getKey(), entry.getValue());
        }
        Set<String> translatedPlaceholders = new TreeSet<>();
        Matcher matcher = PLACEHOLDER.matcher(restored);
        while (matcher.find()) {
            translatedPlaceholders.add(matcher.group(1));
        }
        if (!translatedPlaceholders.equals(prepared.placeholders())) {
            throw new UiTextTranslationException(
                    "Translation changed the placeholder set");
        }
        return restored;
    }

    private static Pattern buildPattern() {
        List<String> alternatives = new ArrayList<>();
        alternatives.add(PLACEHOLDER.pattern());
        alternatives.add(URL.pattern());
        alternatives.add(EMAIL.pattern());
        List<String> tokens = new ArrayList<>(TECHNICAL_TOKENS);
        tokens.sort((left, right) -> Integer.compare(right.length(), left.length()));
        for (String token : tokens) {
            alternatives.add("(?<![\\p{L}\\p{N}_])"
                    + Pattern.quote(token)
                    + "(?![\\p{L}\\p{N}_])");
        }
        return Pattern.compile(String.join("|", alternatives));
    }
}
