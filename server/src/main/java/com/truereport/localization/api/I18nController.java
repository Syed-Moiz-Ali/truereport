package com.truereport.localization.api;

import com.truereport.localization.LocalizationService;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.MeLanguageDto;
import com.truereport.localization.api.LanguageDtos.SetLanguageRequest;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/i18n")
public class I18nController {

    private final LocalizationService localization;
    private final CurrentUserService currentUserService;

    public I18nController(LocalizationService localization, CurrentUserService currentUserService) {
        this.localization = localization;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/languages")
    @PreAuthorize("permitAll()")
    public List<LanguageDto> languages() {
        return localization.activeLanguages();
    }

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public MeLanguageDto me(JwtAuthenticationToken authentication) {
        return localization.me(currentUserService.require(authentication).userId().toString());
    }

    @PutMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public MeLanguageDto setMe(JwtAuthenticationToken authentication,
                               @RequestBody SetLanguageRequest request) {
        return localization.setMyLanguage(
                currentUserService.require(authentication).userId().toString(),
                request == null ? null : request.language());
    }
}
