package com.truereport.shared.i18n;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class TranslationGlossaryService {

    public record Request(String sourceLang, String targetLang, String term, String translation,
                          Boolean caseSensitive, Boolean locked) {
    }

    private final TranslationGlossaryStore store;
    private final LanguageCatalog languages;

    public TranslationGlossaryService(TranslationGlossaryStore store, LanguageCatalog languages) {
        this.store = store;
        this.languages = languages;
    }

    @Transactional(readOnly = true)
    public List<TranslationGlossaryStore.Entry> list(String sourceLang, String targetLang) {
        return store.findAll(language(sourceLang, false), language(targetLang, false));
    }

    @Transactional
    public TranslationGlossaryStore.Entry create(Request request) {
        validate(request, false);
        try {
            return store.insert(language(request.sourceLang(), true),
                    language(request.targetLang(), true), request.term().trim(),
                    request.translation().trim(),
                    Boolean.TRUE.equals(request.caseSensitive()),
                    Boolean.TRUE.equals(request.locked()));
        } catch (DataIntegrityViolationException exception) {
            throw ApiException.conflict("GLOSSARY_EXISTS",
                    "A glossary entry already exists for this term");
        }
    }

    @Transactional
    public TranslationGlossaryStore.Entry update(String id, Request request) {
        TranslationGlossaryStore.Entry existing = store.findById(id)
                .orElseThrow(ApiException::notFound);
        validate(request, true);
        String term = request.term() == null || request.term().isBlank()
                ? existing.term() : request.term().trim();
        String translation = request.translation() == null || request.translation().isBlank()
                ? existing.translation() : request.translation().trim();
        boolean caseSensitive = request.caseSensitive() == null
                ? existing.caseSensitive() : request.caseSensitive();
        boolean locked = request.locked() == null ? existing.locked() : request.locked();
        try {
            store.update(id, term, translation, caseSensitive, locked);
        } catch (DataIntegrityViolationException exception) {
            throw ApiException.conflict("GLOSSARY_EXISTS",
                    "A glossary entry already exists for this term");
        }
        return store.findById(id).orElse(existing);
    }

    @Transactional
    public void delete(String id) {
        if (store.delete(id) == 0) {
            throw ApiException.notFound();
        }
    }

    private void validate(Request request, boolean partial) {
        if (request == null) {
            throw validation("request", "Request is required");
        }
        if (partial) {
            return;
        }
        if (request.term() == null || request.term().isBlank()) {
            throw validation("term", "Term is required");
        }
        if (request.translation() == null || request.translation().isBlank()) {
            throw validation("translation", "Translation is required");
        }
        if (language(request.sourceLang(), true).equals(language(request.targetLang(), true))) {
            throw validation("targetLang", "Source and target language must differ");
        }
    }

    private String language(String code, boolean required) {
        if (code == null || code.isBlank()) {
            if (required) {
                throw validation("lang", "Language is required");
            }
            return null;
        }
        if (!languages.isSupported(code)) {
            throw validation("lang", "Unsupported language: " + code);
        }
        return languages.normalize(code);
    }

    private static ApiException validation(String field, String message) {
        return ApiException.validation("GLOSSARY_INVALID", message,
                List.of(FieldIssue.of(field, "INVALID", "error.field.invalid")));
    }
}
