package com.truereport.localization.api;

import com.truereport.localization.LocalizationService;
import com.truereport.localization.TranslationBacklogService;
import com.truereport.localization.api.LanguageDtos.CreateLanguageRequest;
import com.truereport.localization.api.LanguageDtos.LanguageBacklogDto;
import com.truereport.localization.api.LanguageDtos.LanguageCoverageDto;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.PublishLanguageResultDto;
import com.truereport.localization.api.LanguageDtos.ReorderLanguagesRequest;
import com.truereport.localization.api.LanguageDtos.SetLanguageStatusRequest;
import com.truereport.localization.api.LanguageDtos.TranslationCoverageDto;
import com.truereport.localization.api.LanguageDtos.TranslationItemDto;
import com.truereport.localization.api.LanguageDtos.UpdateLanguageRequest;
import com.truereport.localization.api.LanguageDtos.UpsertTranslationRequest;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform/i18n")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformLanguageController {

    private final LocalizationService localization;
    private final TranslationBacklogService backlog;
    private final CurrentUserService currentUserService;

    public PlatformLanguageController(LocalizationService localization,
                                      TranslationBacklogService backlog,
                                      CurrentUserService currentUserService) {
        this.localization = localization;
        this.backlog = backlog;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/languages")
    public List<LanguageDto> languages() {
        return localization.allLanguages();
    }

    @PostMapping("/languages")
    public ResponseEntity<LanguageDto> create(@RequestBody CreateLanguageRequest request) {
        return ResponseEntity.status(201).body(localization.create(request));
    }

    @PutMapping("/languages/{code}")
    public LanguageDto update(@PathVariable String code,
                              @RequestBody UpdateLanguageRequest request) {
        return localization.update(code, request);
    }

    @PostMapping("/languages/{code}/status")
    public LanguageDto setStatus(@PathVariable String code,
                                 @RequestBody SetLanguageStatusRequest request) {
        return localization.setStatus(code, request == null ? null : request.status());
    }

    @PostMapping("/languages/{code}/activate")
    public LanguageDto activate(@PathVariable String code) {
        return localization.setActive(code, true);
    }

    @PostMapping("/languages/{code}/deactivate")
    public LanguageDto deactivate(@PathVariable String code) {
        return localization.setActive(code, false);
    }

    @PutMapping("/languages/reorder")
    public List<LanguageDto> reorder(@RequestBody ReorderLanguagesRequest request) {
        return localization.reorder(request == null ? List.of() : request.orderedCodes());
    }

    @PutMapping("/languages/default")
    public LanguageDto setDefault(@RequestBody com.truereport.localization.api.LanguageDtos.SetLanguageRequest request) {
        return localization.setDefault(request == null ? null : request.language());
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

    @PostMapping("/languages/{code}/publish")
    public PublishLanguageResultDto publish(JwtAuthenticationToken authentication,
                                            @PathVariable String code,
                                            HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return backlog.publish(actor, code, http);
    }
}
