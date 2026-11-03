package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LocalizedContentRepository extends JpaRepository<LocalizedContent, UUID> {
    List<LocalizedContent> findByEntityTypeAndEntityId(String entityType, UUID entityId);

    List<LocalizedContent> findByEntityTypeAndEntityIdAndLocale(String entityType, UUID entityId, String locale);

    Optional<LocalizedContent> findByEntityTypeAndEntityIdAndLocaleAndFieldKey(
            String entityType, UUID entityId, String locale, String fieldKey);

    void deleteByEntityTypeAndEntityId(String entityType, UUID entityId);
}
