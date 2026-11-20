package com.truereport.reference.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.reference.ReferenceService;
import com.truereport.reference.api.ReferenceDtos.DropdownValueDto;
import com.truereport.reference.api.ReferenceDtos.ImpactDto;
import com.truereport.reference.api.ReferenceDtos.ReferenceRecordDto;
import com.truereport.reference.api.ReferenceDtos.TransitionDto;
import com.truereport.reference.api.ReferenceWriteDtos.ReferenceWriteRequest;
import com.truereport.reference.api.ReferenceWriteDtos.ReorderEntry;
import com.truereport.reference.api.ReferenceWriteDtos.TransitionEntry;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.List;

/**
 * Reference taxonomy API. Reads are available to every authenticated role;
 * writes are Platform Admin only. Drafts are returned only when a Platform
 * Admin asks for {@code includeDraft=true}.
 */
@RestController
@RequestMapping("/api/v1/reference")
@PreAuthorize("isAuthenticated()")
public class ReferenceController {

    private static final String CACHE_CONTROL = "private, max-age=60, must-revalidate";
    private static final String PLATFORM_ADMIN = "hasRole('PLATFORM_ADMIN')";

    private final ReferenceService service;
    private final CurrentUserService currentUserService;
    private final ObjectMapper objectMapper;

    public ReferenceController(ReferenceService service,
                               CurrentUserService currentUserService,
                               ObjectMapper objectMapper) {
        this.service = service;
        this.currentUserService = currentUserService;
        this.objectMapper = objectMapper;
    }

    // ------------------------------------------------------------------ reads

    @GetMapping("/statuses/{statusType}")
    public ResponseEntity<List<ReferenceRecordDto>> statuses(
            JwtAuthenticationToken authentication,
            @PathVariable String statusType,
            @RequestParam(value = "includeDraft", defaultValue = "false") boolean includeDraft,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch)
            throws Exception {
        return respond(service.statuses(statusType, currentUserService.require(authentication),
                includeDraft), ifNoneMatch);
    }

    @GetMapping("/enums/{enumCode}")
    public ResponseEntity<List<ReferenceRecordDto>> enums(
            JwtAuthenticationToken authentication,
            @PathVariable String enumCode,
            @RequestParam(value = "includeDraft", defaultValue = "false") boolean includeDraft,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch)
            throws Exception {
        return respond(service.enums(enumCode, currentUserService.require(authentication),
                includeDraft), ifNoneMatch);
    }

    @GetMapping("/transitions/{entity}")
    public ResponseEntity<List<TransitionDto>> transitions(
            JwtAuthenticationToken authentication,
            @PathVariable String entity,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch)
            throws Exception {
        return respond(service.transitions(entity, currentUserService.require(authentication)),
                ifNoneMatch);
    }

    @GetMapping("/dropdowns/{setCode}")
    public ResponseEntity<List<DropdownValueDto>> dropdowns(
            JwtAuthenticationToken authentication,
            @PathVariable String setCode,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch)
            throws Exception {
        return respond(service.dropdowns(setCode, currentUserService.require(authentication)),
                ifNoneMatch);
    }

    @GetMapping("/{domain}/{key}/impact")
    public ResponseEntity<ImpactDto> impact(JwtAuthenticationToken authentication,
                                            @PathVariable String domain,
                                            @PathVariable String key) {
        return ResponseEntity.ok().header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                .body(service.impact(domain, key));
    }

    // ----------------------------------------------------------------- writes

    @PostMapping("/statuses/{statusType}")
    @PreAuthorize(PLATFORM_ADMIN)
    public ResponseEntity<ReferenceRecordDto> createStatus(
            JwtAuthenticationToken authentication,
            @PathVariable String statusType,
            @RequestBody ReferenceWriteRequest request) {
        return ResponseEntity.status(201).body(service.createStatus(statusType, request,
                currentUserService.require(authentication)));
    }

    @PutMapping("/statuses/{statusType}/{code}")
    @PreAuthorize(PLATFORM_ADMIN)
    public ReferenceRecordDto updateStatus(JwtAuthenticationToken authentication,
                                           @PathVariable String statusType,
                                           @PathVariable String code,
                                           @RequestBody ReferenceWriteRequest request) {
        return service.updateStatus(statusType, code, request,
                currentUserService.require(authentication));
    }

    @PostMapping("/statuses/{statusType}/{code}/publish")
    @PreAuthorize(PLATFORM_ADMIN)
    public ReferenceRecordDto publishStatus(JwtAuthenticationToken authentication,
                                            @PathVariable String statusType,
                                            @PathVariable String code) {
        return service.publishStatus(statusType, code,
                currentUserService.require(authentication));
    }

    @PostMapping("/statuses/{statusType}/{code}/retire")
    @PreAuthorize(PLATFORM_ADMIN)
    public ReferenceRecordDto retireStatus(JwtAuthenticationToken authentication,
                                           @PathVariable String statusType,
                                           @PathVariable String code) {
        return service.retireStatus(statusType, code,
                currentUserService.require(authentication));
    }

    @PutMapping("/statuses/{statusType}/reorder")
    @PreAuthorize(PLATFORM_ADMIN)
    public List<ReferenceRecordDto> reorderStatuses(JwtAuthenticationToken authentication,
                                                    @PathVariable String statusType,
                                                    @RequestBody List<ReorderEntry> entries) {
        return service.reorderStatuses(statusType, entries,
                currentUserService.require(authentication));
    }

    @PutMapping("/enums/{enumCode}/reorder")
    @PreAuthorize(PLATFORM_ADMIN)
    public List<ReferenceRecordDto> reorderEnums(JwtAuthenticationToken authentication,
                                                 @PathVariable String enumCode,
                                                 @RequestBody List<ReorderEntry> entries) {
        return service.reorderEnums(enumCode, entries,
                currentUserService.require(authentication));
    }

    @PostMapping("/enums/{enumCode}")
    @PreAuthorize(PLATFORM_ADMIN)
    public ResponseEntity<ReferenceRecordDto> createEnum(
            JwtAuthenticationToken authentication,
            @PathVariable String enumCode,
            @RequestBody ReferenceWriteRequest request) {
        return ResponseEntity.status(201).body(service.createEnum(enumCode, request,
                currentUserService.require(authentication)));
    }

    @PutMapping("/enums/{enumCode}/{code}")
    @PreAuthorize(PLATFORM_ADMIN)
    public ReferenceRecordDto updateEnum(JwtAuthenticationToken authentication,
                                         @PathVariable String enumCode,
                                         @PathVariable String code,
                                         @RequestBody ReferenceWriteRequest request) {
        return service.updateEnum(enumCode, code, request,
                currentUserService.require(authentication));
    }

    @PostMapping("/enums/{enumCode}/{code}/publish")
    @PreAuthorize(PLATFORM_ADMIN)
    public ReferenceRecordDto publishEnum(JwtAuthenticationToken authentication,
                                          @PathVariable String enumCode,
                                          @PathVariable String code) {
        return service.publishEnum(enumCode, code,
                currentUserService.require(authentication));
    }

    @PostMapping("/enums/{enumCode}/{code}/retire")
    @PreAuthorize(PLATFORM_ADMIN)
    public ReferenceRecordDto retireEnum(JwtAuthenticationToken authentication,
                                         @PathVariable String enumCode,
                                         @PathVariable String code) {
        return service.retireEnum(enumCode, code,
                currentUserService.require(authentication));
    }

    @PutMapping("/transitions/{entity}")
    @PreAuthorize(PLATFORM_ADMIN)
    public List<TransitionDto> replaceTransitions(JwtAuthenticationToken authentication,
                                                  @PathVariable String entity,
                                                  @RequestBody List<TransitionEntry> entries) {
        return service.replaceTransitions(entity, entries,
                currentUserService.require(authentication));
    }

    private <T> ResponseEntity<T> respond(T body, String ifNoneMatch) throws Exception {
        String etag = "\"" + sha256(objectMapper.writeValueAsBytes(body)) + "\"";
        if (etag.equals(ifNoneMatch)) {
            return ResponseEntity.status(304)
                    .eTag(etag)
                    .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                    .build();
        }
        return ResponseEntity.ok()
                .eTag(etag)
                .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body);
    }

    private static String sha256(byte[] value) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(value);
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16));
                hex.append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(exception);
        }
    }
}
