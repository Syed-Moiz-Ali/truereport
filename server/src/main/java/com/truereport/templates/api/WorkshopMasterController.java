package com.truereport.templates.api;

import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.PublishedItemDto;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workshop/master")
@PreAuthorize("hasRole('WORKSHOP_ADMIN')")
public class WorkshopMasterController {

    private final MasterContentService masterContent;

    public WorkshopMasterController(MasterContentService masterContent) {
        this.masterContent = masterContent;
    }

    @GetMapping("/categories")
    public List<CategoryDto> categories() {
        return masterContent.listActiveCategories();
    }

    @GetMapping("/items")
    public List<PublishedItemDto> items(@RequestParam(required = false) String search,
                                        @RequestParam(required = false) UUID categoryId) {
        return masterContent.listPublishedItems(search, categoryId);
    }

    @GetMapping("/items/{versionId}")
    public PublishedItemDto item(@PathVariable UUID versionId) {
        return masterContent.publishedItem(versionId);
    }
}
