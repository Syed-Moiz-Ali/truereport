package com.truereport.masterdata;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GuideImageRepository extends JpaRepository<GuideImage, UUID> {
    List<GuideImage> findAllByOrderByCreatedAtDesc();
}
