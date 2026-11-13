package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.EntityCoverageDto;
import com.truereport.localization.api.LanguageDtos.LanguageCoverageDto;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.LanguageReadinessDto;
import com.truereport.localization.api.LanguageDtos.ReadinessBlockerDto;
import com.truereport.localization.api.LanguageDtos.UiMessageCoverageDto;
import com.truereport.shared.error.ApiException;
import com.truereport.uimessages.PlatformUiMessageReviewService;
import com.truereport.uimessages.api.UiMessageReviewDtos.ReviewEntryDto;
import com.truereport.uimessages.api.UiMessageReviewDtos.ReviewResponseDto;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Aggregates the UI-text review and master-content translation backlog into a
 * single publish-readiness view for a dynamically registered language.
 */
@Service
public class LanguageReadinessService {

    private static final Map<String, String> CONTENT_TABS = Map.of(
            "CATEGORY", "categories",
            "ITEM", "items",
            "OPTION_SET", "option-sets",
            "OPTION_VALUE", "option-values",
            "TEMPLATE", "templates",
            "DOCUMENT_TYPE", "document-types",
            "ISSUE_FIELD", "issue-fields");

    private final LanguageRepository languages;
    private final PlatformUiMessageReviewService uiReview;
    private final TranslationBacklogService backlog;

    public LanguageReadinessService(LanguageRepository languages,
                                    PlatformUiMessageReviewService uiReview,
                                    TranslationBacklogService backlog) {
        this.languages = languages;
        this.uiReview = uiReview;
        this.backlog = backlog;
    }

    @Transactional(readOnly = true)
    public LanguageReadinessDto readiness(String code) {
        String normalized = code == null ? "" : code.trim().toLowerCase(Locale.ROOT);
        LanguageDto language = languages.find(normalized)
                .orElseThrow(() -> ApiException.validation("language", "LANGUAGE_UNKNOWN",
                        List.of(com.truereport.shared.error.FieldIssue.of("language",
                                "LANGUAGE_UNKNOWN", "error.locale.invalid"))));

        List<ReadinessBlockerDto> blockers = new ArrayList<>();

        UiMessageCoverageDto ui = uiCoverage(language, blockers);
        Map<String, EntityCoverageDto> content = contentCoverage(language, blockers);

        long approvedTotal = ui.approved();
        long requiredTotal = ui.total();
        for (EntityCoverageDto entity : content.values()) {
            approvedTotal += entity.approved();
            requiredTotal += entity.total();
        }
        int readinessPercent = requiredTotal <= 0
                ? 0 : (int) Math.round(approvedTotal * 100.0 / requiredTotal);

        return new LanguageReadinessDto(language.code(), language.status(),
                language.nativeName(), language.direction(), language.isDefault(),
                language.uiMessagesPath(), readinessPercent, ui, content, blockers);
    }

    private UiMessageCoverageDto uiCoverage(LanguageDto language,
                                            List<ReadinessBlockerDto> blockers) {
        if (language.uiMessagesPath() == null || language.uiMessagesPath().isBlank()) {
            return new UiMessageCoverageDto(0, 0, 0, 0, null, null);
        }
        ReviewResponseDto review = uiReview.review(language.code());
        int total = review.totalKeys();
        int missing = review.missingKeys();
        int approved = Math.max(0, total - missing);
        int changed = review.changedKeys();
        int placeholderMismatch = (int) review.entries().stream()
                .filter(ReviewEntryDto::placeholderMismatch)
                .count();
        if (missing > 0) {
            blockers.add(new ReadinessBlockerDto("UI_TEXT_MISSING", "ui-text", missing,
                    missing + " UI message key(s) are missing"));
        }
        if (placeholderMismatch > 0) {
            blockers.add(new ReadinessBlockerDto("UI_TEXT_PLACEHOLDER_MISMATCH", "ui-text",
                    placeholderMismatch,
                    placeholderMismatch + " UI message key(s) have placeholder mismatches"));
        }
        return new UiMessageCoverageDto(total, approved, missing, changed,
                language.uiMessagesPath(), null);
    }

    private Map<String, EntityCoverageDto> contentCoverage(LanguageDto language,
                                                           List<ReadinessBlockerDto> blockers) {
        LanguageCoverageDto coverage = backlog.coverage(language.code());
        Map<String, EntityCoverageDto> ordered = new LinkedHashMap<>();
        for (Map.Entry<String, EntityCoverageDto> entry : coverage.byEntity().entrySet()) {
            EntityCoverageDto value = entry.getValue() == null
                    ? new EntityCoverageDto(0, 0) : entry.getValue();
            ordered.put(entry.getKey(), value);
            int missing = value.total() - value.approved();
            if (missing > 0) {
                String tab = CONTENT_TABS.getOrDefault(entry.getKey(), entry.getKey().toLowerCase(Locale.ROOT));
                blockers.add(new ReadinessBlockerDto(entry.getKey() + "_TRANSLATION_MISSING",
                        tab, missing, missing + " " + entry.getKey() + " translation(s) missing"));
            }
        }
        return ordered;
    }
}
