package com.truereport.documents;

import com.truereport.documents.DocumentTypeDtos.DocumentTypeDto;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class DocumentTypeRepository {

    private static final RowMapper<DocumentTypeDto> MAPPER = (rs, i) -> new DocumentTypeDto(
            rs.getString("id"),
            rs.getString("code"),
            rs.getString("name_en"),
            rs.getString("name_ar"),
            rs.getString("status"),
            rs.getBoolean("is_required"),
            rs.getInt("sort_order")
    );

    private final JdbcTemplate jdbc;

    public DocumentTypeRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<DocumentTypeDto> findAllOrdered() {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, status, is_required, sort_order
                FROM platform_document_types
                ORDER BY sort_order, code
                """, MAPPER);
    }

    public Optional<DocumentTypeDto> findById(String id) {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, status, is_required, sort_order
                FROM platform_document_types
                WHERE id = ?
                """, MAPPER, id).stream().findFirst();
    }

    public Optional<DocumentTypeDto> findByCode(String code) {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, status, is_required, sort_order
                FROM platform_document_types
                WHERE code = ?
                """, MAPPER, code).stream().findFirst();
    }

    public DocumentTypeDto insert(String code, String nameEn, String nameAr, boolean required,
                                  int sortOrder) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_document_types
                    (id, code, name_en, name_ar, status, is_required, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, nameEn, nameAr, required, sortOrder);
        return findById(id).orElseThrow();
    }

    public void update(String id, String nameEn, String nameAr, Boolean required, Integer sortOrder,
                       String status) {
        jdbc.update("""
                UPDATE platform_document_types
                SET name_en = COALESCE(?, name_en), name_ar = COALESCE(?, name_ar),
                    is_required = COALESCE(?, is_required), sort_order = COALESCE(?, sort_order),
                    status = COALESCE(?, status), updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE id = ?
                """, nameEn, nameAr, required, sortOrder, status, id);
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
}
