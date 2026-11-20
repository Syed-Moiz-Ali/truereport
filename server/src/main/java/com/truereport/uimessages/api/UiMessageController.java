package com.truereport.uimessages.api;

import com.truereport.uimessages.UiMessageService;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageBundleDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageManifestDto;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * The single UI-text API used by all three apps.
 *
 * <p>{@code /{client}/manifest|bundle} are the contract routes. The legacy
 * {@code /manifest|bundle} routes are thin delegates to {@code platform_admin}
 * and return exactly the same shape.</p>
 */
@RestController
@RequestMapping("/api/v1/i18n/ui-messages")
@PreAuthorize("permitAll()")
public class UiMessageController {

    private static final String LEGACY_CLIENT = "platform_admin";

    private final UiMessageService service;

    public UiMessageController(UiMessageService service) {
        this.service = service;
    }

    @GetMapping("/{client}/manifest")
    @PreAuthorize("permitAll()")
    public ResponseEntity<UiMessageManifestDto> clientManifest(
            @PathVariable String client,
            @RequestParam(value = "namespaces", required = false) List<String> namespaces) {
        return noStore(service.manifest(client, namespaces));
    }

    @GetMapping("/{client}/bundle")
    @PreAuthorize("permitAll()")
    public ResponseEntity<UiMessageBundleDto> clientBundle(
            @PathVariable String client,
            @RequestParam(value = "lang", required = false) String lang,
            @RequestParam(value = "namespaces", required = false) List<String> namespaces) {
        return noStore(service.bundle(client, lang, namespaces));
    }

    @GetMapping("/manifest")
    @PreAuthorize("permitAll()")
    public ResponseEntity<UiMessageManifestDto> manifest(
            @RequestParam(value = "namespaces", required = false) List<String> namespaces) {
        return noStore(service.manifest(LEGACY_CLIENT, namespaces));
    }

    @GetMapping("/bundle")
    @PreAuthorize("permitAll()")
    public ResponseEntity<UiMessageBundleDto> bundle(
            @RequestParam(value = "lang", required = false) String lang,
            @RequestParam(value = "namespaces", required = false) List<String> namespaces) {
        return noStore(service.bundle(LEGACY_CLIENT, lang, namespaces));
    }

    private static <T> ResponseEntity<T> noStore(T body) {
        // Catalogs are edited at runtime: never let a browser or proxy pin them.
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(body);
    }
}
