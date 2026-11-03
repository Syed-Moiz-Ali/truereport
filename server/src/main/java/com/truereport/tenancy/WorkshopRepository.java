package com.truereport.tenancy;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface WorkshopRepository extends JpaRepository<Workshop, UUID> {
    List<Workshop> findAllByOrderByNameAsc();
}
