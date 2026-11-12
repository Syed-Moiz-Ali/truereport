package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueUpdateRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.ReorderCodesRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.RetireOptionValueRequest;
import com.truereport.shared.security.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform/master/option-sets")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformOptionSetController {

    private final PlatformOptionSetService service;
    private final CurrentUserService currentUserService;

    public PlatformOptionSetController(PlatformOptionSetService service,
                                       CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public List<OptionSetDto> list() {
        return service.list();
    }

    @PostMapping
    public ResponseEntity<OptionSetDto> create(JwtAuthenticationToken authentication,
                                               @RequestBody OptionSetRequest request,
                                               HttpServletRequest http) {
        return ResponseEntity.status(201).body(service.create(
                currentUserService.require(authentication), request, http));
    }

    @PutMapping("/{id}")
    public OptionSetDto update(JwtAuthenticationToken authentication, @PathVariable String id,
                               @RequestBody OptionSetRequest request, HttpServletRequest http) {
        return service.update(currentUserService.require(authentication), id, request, http);
    }

    @PostMapping("/{id}/retire")
    public OptionSetDto retire(JwtAuthenticationToken authentication, @PathVariable String id,
                               HttpServletRequest http) {
        return service.retire(currentUserService.require(authentication), id, http);
    }

    @PostMapping("/{id}/values")
    public ResponseEntity<OptionValueDto> addValue(JwtAuthenticationToken authentication,
                                                   @PathVariable String id,
                                                   @RequestBody OptionValueRequest request,
                                                   HttpServletRequest http) {
        return ResponseEntity.status(201).body(service.addValue(
                currentUserService.require(authentication), id, request, http));
    }

    @PutMapping("/{id}/values/{valueId}")
    public OptionValueDto updateValue(JwtAuthenticationToken authentication, @PathVariable String id,
                                      @PathVariable String valueId,
                                      @RequestBody OptionValueUpdateRequest request,
                                      HttpServletRequest http) {
        return service.updateValue(currentUserService.require(authentication), id, valueId, request, http);
    }

    @PostMapping("/{id}/values/{valueId}/retire")
    public OptionValueDto retireValue(JwtAuthenticationToken authentication, @PathVariable String id,
                                      @PathVariable String valueId,
                                      @RequestBody(required = false) RetireOptionValueRequest request,
                                      HttpServletRequest http) {
        return service.retireValue(currentUserService.require(authentication), id, valueId,
                request == null ? null : request.replacementCode(), http);
    }

    @PutMapping("/{id}/values/reorder")
    public List<OptionValueDto> reorderValues(JwtAuthenticationToken authentication,
                                              @PathVariable String id,
                                              @RequestBody ReorderCodesRequest request) {
        return service.reorderValues(id, request == null ? List.of() : request.orderedCodes());
    }
}
