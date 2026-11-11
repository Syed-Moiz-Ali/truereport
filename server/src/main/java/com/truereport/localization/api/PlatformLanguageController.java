package com.truereport.localization.api;

import com.truereport.localization.LocalizationService;
import com.truereport.localization.api.LanguageDtos.CreateLanguageRequest;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.ReorderLanguagesRequest;
import com.truereport.localization.api.LanguageDtos.TranslationCoverageDto;
import com.truereport.localization.api.LanguageDtos.UpdateLanguageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform/i18n")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformLanguageController {

    private final LocalizationService localization;

    public PlatformLanguageController(LocalizationService localization) {
        this.localization = localization;
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
}
