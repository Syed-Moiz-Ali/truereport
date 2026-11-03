package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MasterInspectionItemRepository extends JpaRepository<MasterInspectionItem, UUID> {
    List<MasterInspectionItem> findAllByOrderByStableCodeAsc();

    List<MasterInspectionItem> findByCategoryIdOrderByStableCodeAsc(UUID categoryId);

    List<MasterInspectionItem> findByStatusOrderByStableCodeAsc(String status);

    Optional<MasterInspectionItem> findByStableCode(String stableCode);

    long countByCategoryId(UUID categoryId);
}
