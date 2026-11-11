package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.CoverageNamespace;
import com.truereport.localization.api.LanguageDtos.CreateLanguageRequest;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.MeLanguageDto;
import com.truereport.localization.api.LanguageDtos.TranslationCoverageDto;
import com.truereport.localization.api.LanguageDtos.UpdateLanguageRequest;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class LocalizationService {

    private static final Set<String> DIRECTIONS = Set.of("ltr", "rtl");

    private final LanguageRepository languages;
    private final JdbcTemplate jdbc;

    public LocalizationService(LanguageRepository languages, JdbcTemplate jdbc) {
        this.languages = languages;
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<LanguageDto> activeLanguages() {
        List<LanguageDto> active = new ArrayList<>(languages.findActive());
        String fallback = languages.defaultCode();
        if (fallback != null && active.stream().noneMatch(l -> l.code().equals(fallback))) {
            languages.find(fallback).ifPresent(active::add);
        }
        return active;
    }

    @Transactional(readOnly = true)
    public List<LanguageDto> allLanguages() {
        return languages.findAll();
    }

    @Transactional(readOnly = true)
    public MeLanguageDto me(String userId) {
        String fallback = languages.defaultCode() == null ? "en" : languages.defaultCode();
        String language = languages.preferredLanguage(userId).orElse(fallback);
        LanguageDto dto = languages.find(language).orElse(null);
        if (dto == null || !dto.active()) {
            language = fallback;
            dto = languages.find(language).orElse(null);
        }
        String direction = dto == null ? "ltr" : dto.direction();
        return new MeLanguageDto(language, direction, fallback);
    }

    @Transactional
    public MeLanguageDto setMyLanguage(String userId, String code) {
        if (code == null || code.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        LanguageDto language = languages.find(code.trim())
                .orElseThrow(() -> validation("language", "LANGUAGE_UNKNOWN", "error.locale.invalid"));
        if (!language.active()) {
            throw validation("language", "LANGUAGE_INACTIVE", "error.locale.invalid");
        }
        languages.savePreference(userId, language.code());
        return new MeLanguageDto(language.code(), language.direction(),
                languages.defaultCode() == null ? "en" : languages.defaultCode());
    }

    @Transactional
    public LanguageDto create(CreateLanguageRequest request) {
        if (request.code() == null || request.code().isBlank()) {
            throw validation("code", "LANGUAGE_CODE_REQUIRED", "error.validation.failed");
        }
        String code = request.code().trim().toLowerCase(Locale.ROOT);
        if (languages.find(code).isPresent()) {
            throw ApiException.conflict("LANGUAGE_EXISTS", "Language already exists");
        }
        validateNames(request.nameEn(), request.nameAr());
        String direction = normalizeDirection(request.direction());
        LanguageDto dto = new LanguageDto(code, request.nameEn().trim(), request.nameAr().trim(),
                blankTo(request.nativeName(), request.nameEn().trim()), direction,
                request.active() == null || request.active(),
                false, request.sortOrder() == null ? 99 : request.sortOrder());
        languages.insert(dto);
        return languages.find(code).orElse(dto);
    }

    @Transactional
    public LanguageDto update(String code, UpdateLanguageRequest request) {
        LanguageDto existing = languages.find(code)
                .orElseThrow(() -> validation("code", "LANGUAGE_UNKNOWN", "error.locale.invalid"));
        if (request.active() != null && !request.active()) {
            assertCanDeactivate(existing);
        }
        LanguageDto updated = new LanguageDto(existing.code(),
                blankTo(request.nameEn(), existing.nameEn()),
                blankTo(request.nameAr(), existing.nameAr()),
                blankTo(request.nativeName(), existing.nativeName()),
                normalizeDirection(request.direction() == null ? existing.direction() : request.direction()),
                request.active() == null ? existing.active() : request.active(),
                existing.isDefault(),
                request.sortOrder() == null ? existing.sortOrder() : request.sortOrder());
        languages.update(updated);
        return languages.find(updated.code()).orElse(updated);
    }

    @Transactional
    public LanguageDto setActive(String code, boolean active) {
        LanguageDto existing = languages.find(code)
                .orElseThrow(() -> validation("code", "LANGUAGE_UNKNOWN", "error.locale.invalid"));
        if (!active) {
            assertCanDeactivate(existing);
        }
        languages.update(new LanguageDto(existing.code(), existing.nameEn(), existing.nameAr(),
                existing.nativeName(), existing.direction(), active, existing.isDefault(),
                existing.sortOrder()));
        return languages.find(code).orElse(existing);
    }

    @Transactional
    public List<LanguageDto> reorder(List<String> orderedCodes) {
        if (orderedCodes != null && !orderedCodes.isEmpty()) {
            languages.reorder(orderedCodes);
        }
        return languages.findAll();
    }

    @Transactional
    public LanguageDto setDefault(String code) {
        LanguageDto existing = languages.find(code)
                .orElseThrow(() -> validation("code", "LANGUAGE_UNKNOWN", "error.locale.invalid"));
        if (!existing.active()) {
            throw validation("code", "LANGUAGE_INACTIVE", "error.locale.invalid");
        }
        languages.setDefault(code);
        return languages.find(code).orElse(existing);
    }

    @Transactional(readOnly = true)
    public TranslationCoverageDto coverage() {
        List<String> codes = languages.findAll().stream().map(LanguageDto::code).toList();
        Map<String, CoverageNamespace> namespaces = new LinkedHashMap<>();
        namespaces.put("master.categories", categoryCoverage());
        namespaces.put("master.items", itemCoverage());
        namespaces.put("master.options", optionCoverage());
        namespaces.put("master.templates", templateCoverage());
        namespaces.put("master.documentTypes", documentTypeCoverage());
        return new TranslationCoverageDto(codes, namespaces);
    }

    private CoverageNamespace categoryCoverage() {
        Integer total = jdbc.queryForObject("SELECT COUNT(*) FROM platform_categories", Integer.class);
        List<String> missing = jdbc.query("""
                SELECT code FROM platform_categories
                WHERE name_ar IS NULL OR TRIM(name_ar) = ''
                ORDER BY sort_order
                """, (rs, i) -> rs.getString(1));
        return new CoverageNamespace(total == null ? 0 : total, missing);
    }

    private CoverageNamespace itemCoverage() {
        Integer total = jdbc.queryForObject("SELECT COUNT(*) FROM platform_items", Integer.class);
        List<String> missing = jdbc.query("""
                SELECT i.stable_code FROM platform_items i
                LEFT JOIN platform_item_versions v ON v.id = i.current_published_version_id
                WHERE v.id IS NULL OR v.instruction_ar IS NULL OR TRIM(v.instruction_ar) = ''
                ORDER BY i.stable_code
                """, (rs, i) -> rs.getString(1));
        return new CoverageNamespace(total == null ? 0 : total, missing);
    }

    private CoverageNamespace optionCoverage() {
        Integer total = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_option_values WHERE status = 'ACTIVE'", Integer.class);
        List<String> missing = jdbc.query("""
                SELECT CONCAT(s.code, '.', v.code) FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE v.status = 'ACTIVE' AND (v.label_ar IS NULL OR TRIM(v.label_ar) = '')
                ORDER BY s.code, v.sort_order
                """, (rs, i) -> rs.getString(1));
        return new CoverageNamespace(total == null ? 0 : total, missing);
    }

    private CoverageNamespace templateCoverage() {
        Integer total = jdbc.queryForObject("SELECT COUNT(*) FROM platform_templates", Integer.class);
        List<String> missing = jdbc.query("""
                SELECT code FROM platform_templates
                WHERE name_ar IS NULL OR TRIM(name_ar) = ''
                ORDER BY code
                """, (rs, i) -> rs.getString(1));
        return new CoverageNamespace(total == null ? 0 : total, missing);
    }

    private CoverageNamespace documentTypeCoverage() {
        Integer total = jdbc.queryForObject("SELECT COUNT(*) FROM platform_document_types", Integer.class);
        List<String> missing = jdbc.query("""
                SELECT code FROM platform_document_types
                WHERE name_ar IS NULL OR TRIM(name_ar) = ''
                ORDER BY code
                """, (rs, i) -> rs.getString(1));
        return new CoverageNamespace(total == null ? 0 : total, missing);
    }

    private void assertCanDeactivate(LanguageDto language) {
        if (language.isDefault()) {
            throw ApiException.conflict("LANGUAGE_IS_DEFAULT", "The default language cannot be deactivated");
        }
        if (languages.countActive() <= 1) {
            throw ApiException.conflict("LANGUAGE_LAST_ACTIVE", "At least one language must remain active");
        }
        if (languages.countJobsUsing(language.code()) > 0) {
            throw ApiException.conflict("LANGUAGE_IN_USE", "Language is used by a job preference");
        }
    }

    private void validateNames(String nameEn, String nameAr) {
        List<FieldIssue> issues = new ArrayList<>();
        if (nameEn == null || nameEn.isBlank()) {
            issues.add(FieldIssue.of("nameEn", "REQUIRED", "error.field.invalid"));
        }
        if (nameAr == null || nameAr.isBlank()) {
            issues.add(FieldIssue.of("nameAr", "REQUIRED", "error.field.invalid"));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("LANGUAGE_INVALID", "Language names are required", issues);
        }
    }

    private String normalizeDirection(String direction) {
        String normalized = direction == null || direction.isBlank() ? "ltr" : direction.trim().toLowerCase(Locale.ROOT);
        if (!DIRECTIONS.contains(normalized)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "DIRECTION_INVALID",
                    "error.validation.failed", "Direction must be ltr or rtl");
        }
        return normalized;
    }

    private static String blankTo(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid language request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
