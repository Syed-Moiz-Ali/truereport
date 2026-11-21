package com.truereport.localization.api;

import com.truereport.localization.LanguageReadinessService;
import com.truereport.localization.LocalizationService;
import com.truereport.localization.TranslationBacklogService;
import com.truereport.localization.api.LanguageDtos.CreateLanguageRequest;
import com.truereport.localization.api.LanguageDtos.LanguageBacklogDto;
import com.truereport.localization.api.LanguageDtos.LanguageCoverageDto;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.LanguageReadinessDto;
import com.truereport.localization.api.LanguageDtos.TranslationCoverageDto;
import com.truereport.localization.api.LanguageDtos.TranslationItemDto;
import com.truereport.localization.api.LanguageDtos.UpsertTranslationRequest;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
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
 * Platform Admin language registry plus the dynamic content translation queue.
 *
 * <p>Manifest languages are seeded at startup. Platform Admin may add a new
 * language or reactivate a retired one; retiring is soft so translation rows
 * survive and a later re-create restores the language.</p>
 */
@RestController
@RequestMapping("/api/v1/platform/i18n")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformLanguageController {

    private final LocalizationService localization;
    private final TranslationBacklogService backlog;
    private final LanguageReadinessService readiness;
    private final CurrentUserService currentUserService;

    public PlatformLanguageController(LocalizationService localization,
                                      TranslationBacklogService backlog,
                                      LanguageReadinessService readiness,
                                      CurrentUserService currentUserService) {
        this.localization = localization;
        this.backlog = backlog;
        this.readiness = readiness;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/languages")
    public List<LanguageDto> languages() {
        return localization.allLanguages();
    }

    @PostMapping("/languages")
    public ResponseEntity<LanguageDto> createLanguage(
            @RequestBody(required = false) CreateLanguageRequest request) {
        LocalizationService.LanguageCreationResult result = localization.createLanguage(
                request == null ? null : request.code(),
                request == null ? null : request.nativeName(),
                request == null ? null : request.direction());
        return ResponseEntity.status(result.created() ? HttpStatus.CREATED : HttpStatus.OK)
                .body(result.language());
    }

    @DeleteMapping("/languages/{code}")
    public LanguageDto retireLanguage(@PathVariable String code) {
        return localization.retireLanguage(code);
    }

    @GetMapping("/coverage")
    public TranslationCoverageDto coverage() {
        return localization.coverage();
    }

    @GetMapping(value = "/coverage", params = "language")
    public LanguageCoverageDto coverageForLanguage(@RequestParam("language") String language) {
        return backlog.coverage(language);
    }

    @PutMapping("/translations")
    public TranslationItemDto upsertTranslation(JwtAuthenticationToken authentication,
                                                @RequestBody UpsertTranslationRequest request,
                                                HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return backlog.upsert(actor, request, http);
    }

    @GetMapping("/languages/{code}/backlog")
    public LanguageBacklogDto backlog(@PathVariable String code) {
        return backlog.backlog(code);
    }

    @GetMapping("/languages/{code}/readiness")
    public LanguageReadinessDto readiness(@PathVariable String code) {
        return readiness.readiness(code);
    }

    @PostMapping("/languages/{code}/go-live")
    public LanguageDto goLive(@PathVariable String code) {
        return localization.goLive(code);
    }
}
