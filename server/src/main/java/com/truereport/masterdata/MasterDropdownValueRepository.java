package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MasterDropdownValueRepository extends JpaRepository<MasterDropdownValue, UUID> {
    List<MasterDropdownValue> findByDropdownIdOrderBySortOrderAsc(UUID dropdownId);
}
