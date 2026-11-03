package com.truereport.identity.api;

import com.truereport.identity.HierarchyService;
import com.truereport.identity.api.AcceptInvitationRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth/invitations")
public class InvitationAcceptController {

    private final HierarchyService hierarchyService;

    public InvitationAcceptController(HierarchyService hierarchyService) {
        this.hierarchyService = hierarchyService;
    }

    @PostMapping("/accept")
    public ResponseEntity<Void> accept(@Valid @RequestBody AcceptInvitationRequest request) {
        hierarchyService.acceptInvitation(request.token(), request.password());
        return ResponseEntity.noContent().build();
    }
}
