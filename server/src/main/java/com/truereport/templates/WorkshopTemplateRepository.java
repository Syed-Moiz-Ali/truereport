package com.truereport.templates;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WorkshopTemplateRepository extends JpaRepository<WorkshopTemplate, UUID> {
    List<WorkshopTemplate> findByWorkshopIdOrderByUpdatedAtDesc(UUID workshopId);

    Optional<WorkshopTemplate> findByIdAndWorkshopId(UUID id, UUID workshopId);

    Optional<WorkshopTemplate> findByWorkshopIdAndName(UUID workshopId, String name);

    long countByWorkshopId(UUID workshopId);
}
