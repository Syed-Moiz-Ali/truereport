package com.truereport.templates;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TemplateItemRepository extends JpaRepository<TemplateItem, UUID> {
    List<TemplateItem> findByTemplateVersionIdOrderBySortOrderAsc(UUID templateVersionId);

    void deleteByTemplateVersionId(UUID templateVersionId);

    long countByTemplateVersionId(UUID templateVersionId);
}
