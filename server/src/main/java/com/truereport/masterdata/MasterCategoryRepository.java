package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MasterCategoryRepository extends JpaRepository<MasterCategory, UUID> {
    List<MasterCategory> findAllByOrderBySortOrderAsc();

    Optional<MasterCategory> findBySlug(String slug);
}
