package com.truereport.templates.api;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.templates.WorkshopTemplateService;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/technician/templates")
public class TechnicianTemplateController {

    private final WorkshopTemplateService service;
    private final CurrentUserService currentUserService;

    public TechnicianTemplateController(WorkshopTemplateService service,
                                        CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/versions")
    public List<TemplateVersionOptionDto> versions(JwtAuthenticationToken authentication) {
        var caller = currentUserService.require(authentication);
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        return service.publishedVersionsForWorkshop(caller.workshopId());
    }
}