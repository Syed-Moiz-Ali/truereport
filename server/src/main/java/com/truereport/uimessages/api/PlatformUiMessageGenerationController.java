package com.truereport.uimessages.api;

import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.uimessages.PlatformUiMessagesGenerationService;
import com.truereport.uimessages.PlatformUiMessagesGenerationService.StartResult;
import com.truereport.uimessages.api.UiMessageGenerationDtos.GenerateUiMessagesRequest;
import com.truereport.uimessages.api.UiMessageGenerationDtos.UiMessageGenerationDto;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/platform/i18n/languages")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformUiMessageGenerationController {

    private final PlatformUiMessagesGenerationService service;
    private final CurrentUserService currentUserService;

    public PlatformUiMessageGenerationController(PlatformUiMessagesGenerationService service,
                                                 CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/{code}/ui-messages/generate")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public ResponseEntity<UiMessageGenerationDto> generate(
            JwtAuthenticationToken authentication,
            @PathVariable String code,
            @RequestBody(required = false) GenerateUiMessagesRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        StartResult result = service.generate(actor, code, request);
        return ResponseEntity.status(result.accepted() ? 202 : 200)
                .body(result.generation());
    }

    @GetMapping("/{code}/ui-messages/generation")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public UiMessageGenerationDto generation(@PathVariable String code) {
        return service.status(code);
    }

    @PostMapping("/{code}/ui-messages/generation/cancel")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public UiMessageGenerationDto cancel(JwtAuthenticationToken authentication,
                                         @PathVariable String code) {
        CurrentUser actor = currentUserService.require(authentication);
        return service.cancel(actor, code);
    }

    @PostMapping("/{code}/ui-messages/generation/retry-failed")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public ResponseEntity<UiMessageGenerationDto> retryFailed(
            JwtAuthenticationToken authentication,
            @PathVariable String code) {
        CurrentUser actor = currentUserService.require(authentication);
        return ResponseEntity.status(202).body(service.retryFailed(actor, code));
    }
}
