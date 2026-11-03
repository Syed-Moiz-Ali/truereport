package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MasterDropdownRepository extends JpaRepository<MasterDropdown, UUID> {
    List<MasterDropdown> findAllByOrderBySortOrderAsc();

    Optional<MasterDropdown> findByCode(String code);
}
