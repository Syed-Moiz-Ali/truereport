package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MasterItemVersionRepository extends JpaRepository<MasterItemVersion, UUID> {
    List<MasterItemVersion> findByItemIdOrderByVersionNoDesc(UUID itemId);

    Optional<MasterItemVersion> findFirstByItemIdOrderByVersionNoDesc(UUID itemId);

    Optional<MasterItemVersion> findFirstByItemIdAndStatusOrderByVersionNoDesc(UUID itemId, String status);

    long countByItemId(UUID itemId);
}
