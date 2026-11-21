package com.truereport.media.api;

import com.truereport.media.VehiclePhotoService;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoCompleteResponse;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoDto;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoInitRequest;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoInitResponse;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoUploadResponse;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The pre-inspection vehicle hero photo. One photo per job; init declares the
 * size and sha256, the bytes are uploaded separately, then completed.
 */
@RestController
@RequestMapping("/api/v1/technician/jobs/{jobId}/vehicle-photo")
@PreAuthorize("hasRole('TECHNICIAN')")
public class VehiclePhotoController {

    private final VehiclePhotoService service;
    private final CurrentUserService currentUserService;

    public VehiclePhotoController(VehiclePhotoService service,
                                  CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    public ResponseEntity<VehiclePhotoInitResponse> init(
            JwtAuthenticationToken authentication, @PathVariable String jobId,
            @RequestBody(required = false) VehiclePhotoInitRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.init(
                currentUserService.require(authentication), jobId, request));
    }

    @PutMapping(value = "/{photoId}/content",
            consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE)
    public VehiclePhotoUploadResponse upload(JwtAuthenticationToken authentication,
                                             @PathVariable String jobId,
                                             @PathVariable String photoId,
                                             @RequestBody(required = false) byte[] content) {
        return service.upload(currentUserService.require(authentication), jobId, photoId,
                content);
    }

    @PostMapping("/{photoId}/complete")
    public VehiclePhotoCompleteResponse complete(JwtAuthenticationToken authentication,
                                                 @PathVariable String jobId,
                                                 @PathVariable String photoId) {
        return service.complete(currentUserService.require(authentication), jobId, photoId);
    }

    @GetMapping
    public ResponseEntity<VehiclePhotoDto> get(JwtAuthenticationToken authentication,
                                               @PathVariable String jobId) {
        return ResponseEntity.of(service.get(
                currentUserService.require(authentication), jobId));
    }

    @GetMapping("/content")
    public ResponseEntity<byte[]> content(JwtAuthenticationToken authentication,
                                          @PathVariable String jobId) {
        return service.content(currentUserService.require(authentication), jobId)
                .map(content -> ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(content.mime()))
                        .cacheControl(CacheControl.noStore())
                        .body(content.bytes()))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping
    public ResponseEntity<Void> delete(JwtAuthenticationToken authentication,
                                       @PathVariable String jobId) {
        service.delete(currentUserService.require(authentication), jobId);
        return ResponseEntity.noContent().build();
    }
}
