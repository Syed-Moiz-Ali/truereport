package com.truereport.localization.api;

import com.truereport.localization.LanguageReadinessService;
import com.truereport.localization.LocalizationService;
import com.truereport.localization.TranslationBacklogService;
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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Read-only language registry plus the dynamic content translation queue.
 *
 * <p>Static UI languages are added by editing the JSON manifest and
 * restarting; there is intentionally no create, generate, review, approve,
 * publish or status endpoint here.</p>
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
}
