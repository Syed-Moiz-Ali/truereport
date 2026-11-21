package com.truereport.localization.api;

import com.truereport.localization.ContentLanguageService;
import com.truereport.shared.i18n.ContentTranslationService;
import com.truereport.shared.i18n.ContentTranslationService.Coverage;
import com.truereport.shared.i18n.ContentTranslationService.Translation;
import com.truereport.localization.api.ContentTranslationDtos.CoverageItemDto;
import com.truereport.localization.api.ContentTranslationDtos.PlatformLanguageDto;
import com.truereport.localization.api.ContentTranslationDtos.TranslationBodyRequest;
import com.truereport.localization.api.ContentTranslationDtos.TranslationDto;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Manual authoring surface for dynamic content translations (no machine
 * translation in Phase A).
 */
@RestController
@RequestMapping("/api/v1/platform/i18n/content")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformContentTranslationController {

    public record ReviewItemDto(String entityType, String entityId, String field, String lang,
                                String body, String origin, String status, String provider,
                                String sourceText, boolean safetyCritical, String reviewNote) {
    }

    public record ReviewRequest(String action, String body, String note) {
    }

    public record BackfillRequest(List<String> languages, List<String> entityTypes, Boolean dryRun) {
    }

    public record BackfillResultDto(int enqueued, int skipped, List<String> languages,
                                    List<String> entityTypes) {
    }

    private final ContentTranslationService service;
    private final CurrentUserService currentUserService;
    private final com.truereport.shared.i18n.ContentReviewService reviewService;
    private final com.truereport.shared.i18n.ContentBackfillService backfillService;
    private final ContentLanguageService contentLanguages;
    private final com.truereport.localization.ContentUnitsService unitsService;

    public PlatformContentTranslationController(ContentTranslationService service,
                                                CurrentUserService currentUserService,
                                                com.truereport.shared.i18n.ContentReviewService reviewService,
                                                com.truereport.shared.i18n.ContentBackfillService backfillService,
                                                ContentLanguageService contentLanguages,
                                                com.truereport.localization.ContentUnitsService unitsService) {
        this.service = service;
        this.currentUserService = currentUserService;
        this.reviewService = reviewService;
        this.backfillService = backfillService;
        this.contentLanguages = contentLanguages;
        this.unitsService = unitsService;
    }

    /**
     * Languages that have content translations to review. This is the selector
     * source for the Content review screen; the UI message registry
     * ({@code /platform/i18n/languages}) is intentionally a different list.
     */
    @GetMapping("/languages")
    public List<PlatformLanguageDto> languages() {
        return contentLanguages.contentLanguages();
    }

    /**
     * Explicitly enqueue machine translation for content that predates the
     * pipeline. Idempotent: only jobs that actually became pending are counted.
     */
    @PostMapping("/backfill")
    public BackfillResultDto backfill(@RequestBody(required = false) BackfillRequest request) {
        com.truereport.shared.i18n.ContentBackfillService.Result result = backfillService.backfill(
                request == null ? null : request.languages(),
                request == null ? null : request.entityTypes(),
                request != null && Boolean.TRUE.equals(request.dryRun()));
        return new BackfillResultDto(result.enqueued(), result.skipped(),
                result.languages(), result.entityTypes());
    }

    @GetMapping("/review")
    public List<ReviewItemDto> reviewQueue(@RequestParam String lang,
                                           @RequestParam(required = false) String state,
                                           @RequestParam(required = false) String entityType,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "50") int size) {
        return reviewService.queue(lang, state, entityType, page, size).stream()
                .map(this::toDto).toList();
    }

    @GetMapping("/review/summary")
    public com.truereport.shared.i18n.ContentReviewService.Summary reviewSummary(
            @RequestParam String lang) {
        return reviewService.summary(lang);
    }

    @PostMapping("/{entityType}/{entityId}/{field}/review")
    public ReviewItemDto review(JwtAuthenticationToken authentication,
                                @PathVariable String entityType,
                                @PathVariable String entityId,
                                @PathVariable String field,
                                @RequestParam String lang,
                                @RequestBody ReviewRequest request) {
        return toDto(reviewService.review(entityType, entityId, field, lang,
                request == null ? null : request.action(),
                request == null ? null : request.body(),
                request == null ? null : request.note(),
                currentUserService.require(authentication).userId().toString()));
    }

    private ReviewItemDto toDto(com.truereport.shared.i18n.ContentReviewService.ReviewItem item) {
        return new ReviewItemDto(item.entityType(), item.entityId(), item.field(), item.lang(),
                item.body(), item.origin(), item.status(), item.provider(), item.sourceText(),
                item.safetyCritical(), item.reviewNote());
    }

    /**
     * Canonical text units for one writable language, including units that have
     * no translation row yet. This is the authoring list for a newly added
     * language; {@code /review} only returns rows that already exist.
     *
     * <p>Read-only: it never enqueues jobs and never calls the provider.</p>
     */
    @GetMapping("/units")
    public ContentTranslationDtos.ContentUnitsPageDto units(
            @RequestParam(required = false) String lang,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) String filter,
            @RequestParam(required = false) String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return unitsService.units(lang, entityType, filter, query, page, size);
    }

    @GetMapping("/coverage")
    public List<CoverageItemDto> coverage(@RequestParam String lang,
                                          @RequestParam(required = false) String entityType) {
        return service.coverage(lang, entityType).stream()
                .map(this::toDto)
                .toList();
    }

    @PutMapping("/{entityType}/{entityId}/{field}")
    public TranslationDto write(JwtAuthenticationToken authentication,
                                @PathVariable String entityType,
                                @PathVariable String entityId,
                                @PathVariable String field,
                                @RequestParam String lang,
                                @RequestBody TranslationBodyRequest request) {
        Translation translation = service.write(entityType, entityId, field, lang,
                request == null ? null : request.body(),
                currentUserService.require(authentication).userId().toString());
        return toDto(translation);
    }

    @DeleteMapping("/{entityType}/{entityId}/{field}")
    public ResponseEntity<Void> delete(@PathVariable String entityType,
                                       @PathVariable String entityId,
                                       @PathVariable String field,
                                       @RequestParam String lang) {
        service.delete(entityType, entityId, field, lang);
        return ResponseEntity.noContent().build();
    }

    private CoverageItemDto toDto(Coverage coverage) {
        return new CoverageItemDto(coverage.entityType(), coverage.field(), coverage.total(),
                coverage.translated(), coverage.missing(), coverage.stale(),
                coverage.pendingReview(), coverage.blocked(), coverage.safetyCritical());
    }

    private TranslationDto toDto(Translation translation) {
        return new TranslationDto(translation.entityType(), translation.entityId(),
                translation.field(), translation.lang(), translation.body(), translation.origin(),
                translation.status(), translation.sourceLang(), translation.sourceHash(),
                translation.provider());
    }
}
