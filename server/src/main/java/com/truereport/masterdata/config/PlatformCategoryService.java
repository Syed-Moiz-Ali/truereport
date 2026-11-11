package com.truereport.masterdata.config;

import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.config.PlatformMasterDtos.CategoryWeightCheck;
import com.truereport.masterdata.config.PlatformMasterDtos.CategoryWeightRow;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class PlatformCategoryService {

    private final PlatformContentStore content;

    public PlatformCategoryService(PlatformContentStore content) {
        this.content = content;
    }

    @Transactional(readOnly = true)
    public CategoryWeightCheck weightCheck() {
        List<CategoryWeightRow> rows = content.categories().stream()
                .map(this::row)
                .toList();
        BigDecimal total = rows.stream()
                .filter(row -> "ACTIVE".equals(row.status()))
                .map(CategoryWeightRow::weight)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return new CategoryWeightCheck(total.compareTo(new BigDecimal("100")) == 0,
                total, new BigDecimal("100"), rows);
    }

    @Transactional
    public List<CategoryWeightRow> reorder(List<String> orderedIds) {
        if (orderedIds != null && !orderedIds.isEmpty()) {
            content.reorderCategories(orderedIds);
        }
        return weightCheck().categories();
    }

    private CategoryWeightRow row(CategoryDto category) {
        return new CategoryWeightRow(category.id().toString(), category.code(),
                category.labelEn(), category.labelAr(), category.status(),
                category.weightPercentage() == null ? BigDecimal.ZERO : category.weightPercentage());
    }
}
