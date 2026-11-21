package com.truereport.localization.api;

import com.truereport.shared.i18n.TranslationGlossaryService;
import com.truereport.shared.i18n.TranslationGlossaryStore;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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

@RestController
@RequestMapping("/api/v1/platform/i18n/glossary")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class TranslationGlossaryController {

    public record GlossaryEntryDto(String id, String sourceLang, String targetLang, String term,
                                   String translation, boolean caseSensitive, boolean locked) {
    }

    public record GlossaryRequest(String sourceLang, String targetLang, String term,
                                  String translation, Boolean caseSensitive, Boolean locked) {
    }

    private final TranslationGlossaryService service;

    public TranslationGlossaryController(TranslationGlossaryService service) {
        this.service = service;
    }

    @GetMapping
    public List<GlossaryEntryDto> list(@RequestParam(required = false) String sourceLang,
                                       @RequestParam(required = false) String targetLang) {
        return service.list(sourceLang, targetLang).stream().map(this::dto).toList();
    }

    @PostMapping
    public ResponseEntity<GlossaryEntryDto> create(@RequestBody GlossaryRequest request) {
        return ResponseEntity.status(201).body(dto(service.create(toService(request))));
    }

    @PutMapping("/{id}")
    public GlossaryEntryDto update(@PathVariable String id, @RequestBody GlossaryRequest request) {
        return dto(service.update(id, toService(request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    private GlossaryEntryDto dto(TranslationGlossaryStore.Entry entry) {
        return new GlossaryEntryDto(entry.id(), entry.sourceLang(), entry.targetLang(),
                entry.term(), entry.translation(), entry.caseSensitive(), entry.locked());
    }

    private TranslationGlossaryService.Request toService(GlossaryRequest request) {
        return request == null ? null : new TranslationGlossaryService.Request(
                request.sourceLang(), request.targetLang(), request.term(), request.translation(),
                request.caseSensitive(), request.locked());
    }
}
