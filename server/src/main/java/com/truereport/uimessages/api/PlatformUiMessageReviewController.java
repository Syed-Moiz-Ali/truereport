package com.truereport.uimessages.api;

import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.uimessages.PlatformUiMessageReviewService;
import com.truereport.uimessages.api.UiMessageReviewDtos.ApproveReviewResponseDto;
import com.truereport.uimessages.api.UiMessageReviewDtos.ReviewResponseDto;
import com.truereport.uimessages.api.UiMessageReviewDtos.SaveReviewRequest;
import jakarta.servlet.http.HttpServletRequest;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/platform/i18n/languages/{code}/ui-messages")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformUiMessageReviewController {

    private final PlatformUiMessageReviewService service;
    private final CurrentUserService currentUserService;

    public PlatformUiMessageReviewController(PlatformUiMessageReviewService service,
                                             CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/review")
    public ReviewResponseDto review(@PathVariable String code) {
        return service.review(code);
    }

    @PutMapping("/review")
    public ReviewResponseDto save(JwtAuthenticationToken authentication,
                                  @PathVariable String code,
                                  @RequestBody SaveReviewRequest request,
                                  HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return service.save(actor, code, request, http);
    }

    @PostMapping("/approve")
    public ApproveReviewResponseDto approve(JwtAuthenticationToken authentication,
                                            @PathVariable String code,
                                            HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return service.approve(actor, code, http);
    }

    @GetMapping("/download")
    public ResponseEntity<byte[]> download(@PathVariable String code) {
        byte[] body = service.download(code);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + code + ".json\"")
                .body(body);
    }
}
