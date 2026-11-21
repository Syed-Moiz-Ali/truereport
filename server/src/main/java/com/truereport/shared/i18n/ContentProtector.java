package com.truereport.shared.i18n;

import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Protects non-translatable fragments before a provider call and restores them
 * afterwards. A lost token is a hard failure: callers must reject the machine
 * output rather than store corrupted copy.
 *
 * <p>Tokens look like {@code #1000123#}: a globally unique number, so a batch
 * of texts never shares token names. Plain digits are used because
 * LibreTranslate preserves {@code #123#}/{@code {123}} but mangles longer
 * random bodies and square-bracket wrappers. Restore is always per text (each
 * call takes its own {@link Protection}); a provider that returns another
 * text's token makes the expected token missing and fails loudly.</p>
 */
@Service
public class ContentProtector {

    public static final String PLACEHOLDER_LOST = "PLACEHOLDER_LOST";

    public record Protection(String text, Map<String, String> replacements) {
    }

    public static class PlaceholderLostException extends RuntimeException {
        public PlaceholderLostException(String message) {
            super(message);
        }
    }

    private static final List<Pattern> DEFAULT_PATTERNS = List.of(
            Pattern.compile("\\{[A-Za-z0-9_]+\\}"),
            Pattern.compile("%[sdf]|\\$\\d+"),
            Pattern.compile("https?://[^\\s]+"),
            Pattern.compile("[\\w.+-]+@[\\w.-]+\\.[A-Za-z]{2,}"),
            Pattern.compile("\\b[A-HJ-NPR-Z0-9]{17}\\b"),
            // LibreTranslate drops "<"/">" with the value after them
            // ("Temperature >50 C" -> "Temperatura C"). "&" is normalized to
            // "and" by the worker instead of being tokenized.
            Pattern.compile("[<>]=?"),
            Pattern.compile("\\b\\d+(?:[.,]\\d+)?\\s?(?:mm|cm|km|V|A|psi|bar|rpm|Nm|°C|°F|%)\\b"),
            Pattern.compile("\\b\\d+(?:[.,]\\d+)?\\s?[–-]\\s?\\d+(?:[.,]\\d+)?\\b"),
            Pattern.compile("\\b[A-Z]{2,4}[- ]\\d{2,5}\\b"),
            Pattern.compile("\\b\\d{2,5}[- ][A-Z]{2,4}\\b")
    );

    private static final AtomicLong TOKEN_SEQUENCE = new AtomicLong(1_000_000L);

    public Protection protect(String text, String protectPatterns, List<GlossaryTerm> lockedTerms) {
        String value = text == null ? "" : text;
        Map<String, String> replacements = new LinkedHashMap<>();
        String protectedText = value;

        // Locked glossary terms must never reach the provider as translatable text.
        if (lockedTerms != null) {
            for (GlossaryTerm term : lockedTerms) {
                protectedText = replaceTerm(protectedText, term.term(), term.caseSensitive(),
                        value, replacements, term.translation());
            }
        }

        for (Pattern pattern : DEFAULT_PATTERNS) {
            protectedText = replacePattern(protectedText, pattern, value, replacements);
        }

        for (Pattern pattern : customPatterns(protectPatterns)) {
            protectedText = replacePattern(protectedText, pattern, value, replacements);
        }
        return new Protection(protectedText, replacements);
    }

    public String restore(String translated, Protection protection) {
        String value = translated == null ? "" : translated;
        List<String> lost = new ArrayList<>();
        for (String token : protection.replacements().keySet()) {
            if (!value.contains(token)) {
                lost.add(token + (containsAlteredWrapper(value, token) ? " (wrapper altered)" : ""));
            }
        }
        if (!lost.isEmpty()) {
            throw new PlaceholderLostException(PLACEHOLDER_LOST + ": " + String.join(", ", lost));
        }
        String restored = value;
        for (Map.Entry<String, String> entry : protection.replacements().entrySet()) {
            restored = restored.replace(entry.getKey(), entry.getValue());
        }
        return restored;
    }

    /**
     * The token's identity survived but its wrapper changed. We must still fail:
     * restoring around a mangled wrapper would silently keep junk.
     */
    private static boolean containsAlteredWrapper(String value, String token) {
        String signature = token.substring(1, token.length() - 1);
        return !signature.isBlank() && Pattern.compile("(?<!\\d)" + signature + "(?!\\d)")
                .matcher(value).find();
    }

    private static String replacePattern(String text, Pattern pattern, String original,
                                         Map<String, String> replacements) {
        Matcher matcher = pattern.matcher(text);
        StringBuilder result = new StringBuilder();
        int last = 0;
        while (matcher.find()) {
            result.append(text, last, matcher.start());
            String token = nextToken(original);
            replacements.put(token, matcher.group());
            result.append(token);
            last = matcher.end();
        }
        result.append(text.substring(last));
        return result.toString();
    }

    private static String replaceTerm(String text, String term, boolean caseSensitive,
                                      String original, Map<String, String> replacements,
                                      String replacement) {
        if (term == null || term.isBlank()) {
            return text;
        }
        Pattern pattern = Pattern.compile("\\b" + Pattern.quote(term) + "\\b",
                caseSensitive ? 0 : Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
        Matcher matcher = pattern.matcher(text);
        StringBuilder result = new StringBuilder();
        int last = 0;
        while (matcher.find()) {
            result.append(text, last, matcher.start());
            String token = nextToken(original);
            replacements.put(token, replacement);
            result.append(token);
            last = matcher.end();
        }
        result.append(text.substring(last));
        return result.toString();
    }

    private static List<Pattern> customPatterns(String protectPatterns) {
        if (protectPatterns == null || protectPatterns.isBlank()) {
            return List.of();
        }
        List<Pattern> patterns = new ArrayList<>();
        for (String raw : protectPatterns.split("[;\\n]")) {
            String value = raw.trim();
            if (value.isEmpty()) {
                continue;
            }
            try {
                patterns.add(Pattern.compile(value));
            } catch (RuntimeException ignored) {
                // A bad admin pattern must not block translation.
            }
        }
        return patterns;
    }

    /**
     * Globally unique, short numeric token. The sequence starts high enough that
     * ordinary content never collides, and we skip a number the text already
     * contains so restore cannot rewrite user text.
     */
    private static String nextToken(String original) {
        while (true) {
            String candidate = "#" + TOKEN_SEQUENCE.getAndIncrement() + "#";
            if (!original.contains(candidate)) {
                return candidate;
            }
        }
    }

    public record GlossaryTerm(String term, String translation, boolean caseSensitive,
                               boolean locked) {
    }
}
