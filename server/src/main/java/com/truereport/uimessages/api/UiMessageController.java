package com.truereport.uimessages.api;

import com.truereport.uimessages.UiMessageService;
import com.truereport.uimessages.UiMessageService.BundleResult;
import com.truereport.uimessages.UiMessageService.ManifestResult;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageBundleDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageManifestDto;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/v1/i18n/ui-messages")
@PreAuthorize("permitAll()")
public class UiMessageController {

    private final UiMessageService service;

    public UiMessageController(UiMessageService service) {
        this.service = service;
    }

    @GetMapping("/manifest")
    @PreAuthorize("permitAll()")
    public ResponseEntity<UiMessageManifestDto> manifest(
            @RequestParam(value = "namespaces", required = false) List<String> namespaces,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        ManifestResult result = service.manifest(namespaces);
        if (result.etag().equals(ifNoneMatch)) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                    .eTag(result.etag())
                    .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES).cachePrivate())
                    .header(HttpHeaders.VARY, HttpHeaders.ORIGIN)
                    .build();
        }
        return ResponseEntity.ok()
                .eTag(result.etag())
                .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES).cachePrivate())
                .header(HttpHeaders.VARY, HttpHeaders.ORIGIN)
                .body(result.manifest());
    }

    @GetMapping("/bundle")
    @PreAuthorize("permitAll()")
    public ResponseEntity<UiMessageBundleDto> bundle(
            @RequestParam(value = "lang", required = false) String lang,
            @RequestParam(value = "namespaces", required = false) List<String> namespaces,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        BundleResult result = service.bundle(lang, namespaces);
        if (result.etag().equals(ifNoneMatch)) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED)
                    .eTag(result.etag())
                    .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES).cachePrivate())
                    .header(HttpHeaders.VARY, HttpHeaders.ORIGIN)
                    .build();
        }
        return ResponseEntity.ok()
                .eTag(result.etag())
                .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES).cachePrivate())
                .header(HttpHeaders.VARY, HttpHeaders.ORIGIN)
                .body(result.bundle());
    }
}
