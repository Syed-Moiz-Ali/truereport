package com.truereport.templates;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TemplateVersionRepository extends JpaRepository<TemplateVersion, UUID> {
    List<TemplateVersion> findByTemplateIdOrderByVersionNoDesc(UUID templateId);

    Optional<TemplateVersion> findFirstByTemplateIdOrderByVersionNoDesc(UUID templateId);

    Optional<TemplateVersion> findByIdAndWorkshopId(UUID id, UUID workshopId);

    List<TemplateVersion> findByWorkshopIdAndStatusOrderByPublishedAtDesc(UUID workshopId, String status);
}
