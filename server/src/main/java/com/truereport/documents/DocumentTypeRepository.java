package com.truereport.documents;

import com.truereport.documents.DocumentTypeDtos.DocumentTypeDto;
import com.truereport.localization.DynamicContentTranslations;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class DocumentTypeRepository {

    private record Row(String id, String code, String name, String status,
                       boolean required, int sortOrder) {
    }

    private static final RowMapper<Row> MAPPER = (rs, i) -> new Row(
            rs.getString("id"), rs.getString("code"), rs.getString("name"),
            rs.getString("status"), rs.getBoolean("is_required"), rs.getInt("sort_order"));

    private final JdbcTemplate jdbc;
    private final DynamicContentTranslations translations;

    public DocumentTypeRepository(JdbcTemplate jdbc, DynamicContentTranslations translations) {
        this.jdbc = jdbc;
        this.translations = translations;
    }

    public List<DocumentTypeDto> findAllOrdered() {
        return jdbc.query("""
                SELECT id, code, name, status, is_required, sort_order
                FROM platform_document_types
                ORDER BY sort_order, code
                """, MAPPER).stream().map(this::dto).toList();
    }

    public Optional<DocumentTypeDto> findById(String id) {
        return jdbc.query("""
                SELECT id, code, name, status, is_required, sort_order
                FROM platform_document_types WHERE id = ?
                """, MAPPER, id).stream().findFirst().map(this::dto);
    }

    public Optional<DocumentTypeDto> findByCode(String code) {
        return jdbc.query("""
                SELECT id, code, name, status, is_required, sort_order
                FROM platform_document_types WHERE code = ?
                """, MAPPER, code).stream().findFirst().map(this::dto);
    }

    public DocumentTypeDto insert(String code, String name,
                                  Map<String, Map<String, String>> fieldTranslations,
                                  boolean required, int sortOrder, String status) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_document_types
                    (id, code, name, status, is_required, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name, status, required, sortOrder);
        translations.saveOverlays("DOCUMENT_TYPE", id, fieldTranslations, "APPROVED");
        return findById(id).orElseThrow();
    }

    public void update(String id, String name,
                       Map<String, Map<String, String>> fieldTranslations,
                       Boolean required, Integer sortOrder, String status) {
        jdbc.update("""
                UPDATE platform_document_types
                SET name = COALESCE(?, name),
                    is_required = COALESCE(?, is_required), sort_order = COALESCE(?, sort_order),
                    status = COALESCE(?, status), updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE id = ?
                """, blankToNull(name), required, sortOrder, status, id);
        translations.saveOverlays("DOCUMENT_TYPE", id, fieldTranslations, "APPROVED");
    }

    public void retire(String id) {
        jdbc.update("""
                UPDATE platform_document_types
                SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, id);
    }

    public void reorder(List<String> orderedIds) {
        int order = 1;
        for (String id : orderedIds) {
            jdbc.update("""
                    UPDATE platform_document_types
                    SET sort_order = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                    WHERE id = ?
                    """, order++, id);
        }
    }

    private DocumentTypeDto dto(Row row) {
        Map<String, Map<String, String>> fields =
                translations.view("DOCUMENT_TYPE", row.id(), Map.of("name", safe(row.name())));
        String nameAr = translations.resolve("DOCUMENT_TYPE", row.id(), "name", "ar",
                safe(row.name()));
        return new DocumentTypeDto(row.id(), row.code(), row.name(), row.status(),
                row.required(), row.sortOrder(), fields, row.name(), nameAr);
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    @SuppressWarnings("unused")
    private static Map<String, Map<String, String>> empty() {
        return new LinkedHashMap<>();
    }
}
