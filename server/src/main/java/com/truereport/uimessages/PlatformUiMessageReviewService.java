package com.truereport.uimessages;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.security.CurrentUser;
import com.truereport.uimessages.UiMessageLanguageGateway.Language;
import com.truereport.uimessages.api.UiMessageReviewDtos.ApproveReviewResponseDto;
import com.truereport.uimessages.api.UiMessageReviewDtos.ReviewEntryDto;
import com.truereport.uimessages.api.UiMessageReviewDtos.ReviewEntryInput;
import com.truereport.uimessages.api.UiMessageReviewDtos.ReviewResponseDto;
import com.truereport.uimessages.api.UiMessageReviewDtos.SaveReviewRequest;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class PlatformUiMessageReviewService {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");
    private static final String REVIEW = "REVIEW";

    private final PlatformUiMessageCatalog catalog;
    private final UiMessageLanguageGateway languages;
    private final FieldAuditService audit;
    private final ObjectMapper objectMapper;

    public PlatformUiMessageReviewService(PlatformUiMessageCatalog catalog,
                                          UiMessageLanguageGateway languages,
                                          FieldAuditService audit,
                                          ObjectMapper objectMapper) {
        this.catalog = catalog;
        this.languages = languages;
        this.audit = audit;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public ReviewResponseDto review(String code) {
        Language language = requireLanguage(code);
        String path = requirePath(language);
        Map<String, String> source = catalog.loadFlat(
                PlatformUiMessageCatalog.SOURCE_PATH);
        Map<String, String> target = loadTarget(path);

        List<ReviewEntryDto> entries = new ArrayList<>();
        int changedKeys = 0;
        int missingKeys = 0;
        for (Map.Entry<String, String> sourceEntry : new TreeMap<>(source).entrySet()) {
            String key = sourceEntry.getKey();
            String sourceText = sourceEntry.getValue();
            String targetText = target.get(key);
            boolean missing = targetText == null;
            boolean untranslated = targetText == null || targetText.isBlank();
            boolean changed = !untranslated && !sourceText.equals(targetText);
            boolean placeholderMismatch = !untranslated
                    && !placeholders(sourceText).equals(placeholders(targetText));
            if (changed) {
                changedKeys++;
            }
            if (missing) {
                missingKeys++;
            }
            entries.add(new ReviewEntryDto(key, sourceText, targetText,
                    changed, missing, untranslated, placeholderMismatch));
        }
        return new ReviewResponseDto(language.code(), language.status(), path,
                entries.size(), changedKeys, missingKeys, entries);
    }

    @Transactional
    public ReviewResponseDto save(CurrentUser actor, String code,
                                  SaveReviewRequest request, HttpServletRequest http) {
        Language language = requireLanguage(code);
        String path = writablePath(language);
        Map<String, String> source = catalog.loadFlat(
                PlatformUiMessageCatalog.SOURCE_PATH);
        Map<String, String> target = loadTarget(path);

        Map<String, String> updates = new LinkedHashMap<>();
        if (request != null && request.translations() != null) {
            updates.putAll(request.translations());
        }
        if (request != null && request.entries() != null) {
            for (ReviewEntryInput entry : request.entries()) {
                if (entry == null || entry.key() == null) {
                    continue;
                }
                updates.put(entry.key(), entry.targetText());
            }
        }
        List<FieldIssue> issues = new ArrayList<>();
        for (String key : updates.keySet()) {
            if (!source.containsKey(key)) {
                issues.add(FieldIssue.of(key, "UI_MESSAGE_KEY_UNKNOWN",
                        "error.validation.failed"));
            }
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("UI_MESSAGE_UNKNOWN_KEY",
                    "Review contains unknown UI message keys", issues);
        }
        updates.forEach((key, value) ->
                target.put(key, value == null ? "" : value.trim()));

        List<String> missing = new ArrayList<>();
        List<String> blank = new ArrayList<>();
        List<String> placeholderMismatch = new ArrayList<>();
        for (String key : source.keySet()) {
            String value = target.get(key);
            if (value == null) {
                missing.add(key);
            } else if (value.isBlank()) {
                blank.add(key);
            } else if (!placeholders(source.get(key)).equals(placeholders(value))) {
                placeholderMismatch.add(key);
            }
        }
        for (String key : missing) {
            issues.add(FieldIssue.of(key, "TRANSLATION_REQUIRED",
                    "error.translation.required"));
        }
        for (String key : blank) {
            issues.add(FieldIssue.of(key, "TRANSLATION_REQUIRED",
                    "error.translation.required"));
        }
        for (String key : placeholderMismatch) {
            issues.add(FieldIssue.of(key, "UI_MESSAGE_PLACEHOLDER_MISMATCH",
                    "error.validation.failed"));
        }
        if (issues.size() > 200) {
            issues = new ArrayList<>(issues.subList(0, 200));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "UI message review is incomplete for " + language.code(), issues);
        }

        catalog.writeAtomic(path, target);
        String hash = hash(catalog.readBytes(path));
        languages.setUiMessagesReview(language.code(), hash,
                actor == null || actor.userId() == null
                        ? null : actor.userId().toString());
        audit.record(actor, "UI_MESSAGES_REVIEW_SAVED", "LANGUAGE", language.code(),
                null, Map.of("path", path, "keys", target.size(), "hash", hash),
                null, http);
        return review(language.code());
    }

    @Transactional
    public ApproveReviewResponseDto approve(CurrentUser actor, String code,
                                            HttpServletRequest http) {
        Language language = requireLanguage(code);
        String path = requirePath(language);
        String defaultPath = defaultPath();
        catalog.requirePublishable(language.code(), path, defaultPath);
        Map<String, String> target = catalog.loadFlat(path);
        String hash = hash(catalog.readBytes(path));
        languages.setUiMessagesReview(language.code(), hash,
                actor == null || actor.userId() == null
                        ? null : actor.userId().toString());
        languages.setStatus(language.code(), REVIEW);
        audit.record(actor, "UI_MESSAGES_REVIEW_APPROVED", "LANGUAGE", language.code(),
                Map.of("status", language.status()),
                Map.of("status", REVIEW, "path", path, "keys", target.size(),
                        "hash", hash),
                null, http);
        return new ApproveReviewResponseDto(language.code(), REVIEW, path, hash,
                target.size());
    }

    @Transactional(readOnly = true)
    public byte[] download(String code) {
        Language language = requireLanguage(code);
        return catalog.readBytes(requirePath(language));
    }

    public String pathFor(String code) {
        return requirePath(requireLanguage(code));
    }

    private Map<String, String> loadTarget(String path) {
        try {
            return new LinkedHashMap<>(catalog.loadFlat(path));
        } catch (RuntimeException missing) {
            return new LinkedHashMap<>();
        }
    }

    private Language requireLanguage(String code) {
        return languages.find(code)
                .orElseThrow(() -> validation("language", "LANGUAGE_UNKNOWN",
                        "error.locale.invalid"));
    }

    private String requirePath(Language language) {
        if (language.uiMessagesPath() == null
                || language.uiMessagesPath().isBlank()) {
            throw validation("uiMessagesPath", "UI_MESSAGES_REQUIRED",
                    "error.translation.required");
        }
        return PlatformUiMessageCatalog.validateRelativePath(
                language.uiMessagesPath());
    }

    private String writablePath(Language language) {
        if (language.uiMessagesPath() == null
                || language.uiMessagesPath().isBlank()) {
            String path = "platform_admin/" + language.code() + ".json";
            languages.setUiMessagesPath(language.code(), path);
            return path;
        }
        return PlatformUiMessageCatalog.validateRelativePath(
                language.uiMessagesPath());
    }

    private String defaultPath() {
        String code = languages.defaultCode();
        if (code == null) {
            return PlatformUiMessageCatalog.SOURCE_PATH;
        }
        return languages.find(code)
                .map(Language::uiMessagesPath)
                .filter(path -> path != null && !path.isBlank())
                .orElse(PlatformUiMessageCatalog.SOURCE_PATH);
    }

    private static Set<String> placeholders(String value) {
        Set<String> names = new TreeSet<>();
        if (value == null) {
            return names;
        }
        Matcher matcher = PLACEHOLDER.matcher(value);
        while (matcher.find()) {
            names.add(matcher.group(1));
        }
        return names;
    }

    private static String hash(byte[] bytes) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte value : digest) {
                hex.append(Character.forDigit((value >> 4) & 0xF, 16));
                hex.append(Character.forDigit(value & 0xF, 16));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException(error);
        }
    }

    @SuppressWarnings("unused")
    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException error) {
            throw new IllegalStateException(error);
        }
    }

    private static ApiException validation(String field, String code,
                                           String messageKey) {
        return ApiException.validation(code, "Invalid UI message review request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
