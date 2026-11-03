package com.truereport.identity;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditEvent;
import com.truereport.audit.AuditEventRepository;
import com.truereport.audit.AuditService;
import com.truereport.identity.RefreshToken;
import com.truereport.identity.RefreshTokenRepository;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.identity.UserStatus;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.tenancy.Invitation;
import com.truereport.tenancy.InvitationProperties;
import com.truereport.tenancy.InvitationRepository;
import com.truereport.tenancy.InvitationStatus;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.tenancy.WorkshopRole;
import com.truereport.identity.api.AuditEventDto;
import com.truereport.identity.api.HierarchyResponse;
import com.truereport.identity.api.HierarchyWorkshopDto;
import com.truereport.identity.api.InvitationResponse;
import com.truereport.identity.api.PlatformAccountDto;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class HierarchyService {

    private final WorkshopRepository workshops;
    private final WorkshopMembershipRepository memberships;
    private final UserRepository users;
    private final InvitationRepository invitations;
    private final RefreshTokenRepository refreshTokens;
    private final AuditEventRepository auditEvents;
    private final AuditService auditService;
    private final PasswordEncoder passwordEncoder;
    private final InvitationProperties invitationProperties;
    private final ObjectMapper objectMapper;
    private final SecureRandom random = new SecureRandom();

    public HierarchyService(WorkshopRepository workshops,
                            WorkshopMembershipRepository memberships,
                            UserRepository users,
                            InvitationRepository invitations,
                            RefreshTokenRepository refreshTokens,
                            AuditEventRepository auditEvents,
                            AuditService auditService,
                            PasswordEncoder passwordEncoder,
                            InvitationProperties invitationProperties,
                            ObjectMapper objectMapper) {
        this.workshops = workshops;
        this.memberships = memberships;
        this.users = users;
        this.invitations = invitations;
        this.refreshTokens = refreshTokens;
        this.auditEvents = auditEvents;
        this.auditService = auditService;
        this.passwordEncoder = passwordEncoder;
        this.invitationProperties = invitationProperties;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public HierarchyResponse hierarchy(String search, String status) {
        String query = search == null ? "" : search.trim().toLowerCase();
        String filter = status == null ? "" : status.trim().toUpperCase();
        if (!filter.isEmpty() && !List.of("ACTIVE", "DISABLED", "PENDING").contains(filter)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_FILTER", "error.filter.invalid", "Invalid status filter");
        }
        List<HierarchyWorkshopDto> result = new ArrayList<>();
        int totalAccounts = 0;
        for (Workshop workshop : workshops.findAllByOrderByNameAsc()) {
            HierarchyWorkshopDto dto = buildWorkshop(workshop, filter);
            boolean workshopMatches = query.isEmpty()
                    || contains(workshop.getName(), query)
                    || contains(workshop.getBranchName(), query);
            boolean accountMatches = dto.admins().stream().anyMatch(a -> accountMatches(a, query))
                    || dto.technicians().stream().anyMatch(a -> accountMatches(a, query))
                    || dto.pendingInvitations().stream().anyMatch(a -> accountMatches(a, query));
            if (!query.isEmpty() && !workshopMatches && !accountMatches) {
                continue;
            }
            if (!filter.isEmpty() && dto.admins().isEmpty() && dto.technicians().isEmpty()
                    && dto.pendingInvitations().isEmpty()) {
                continue;
            }
            result.add(dto);
            totalAccounts += dto.admins().size() + dto.technicians().size() + dto.pendingInvitations().size();
        }
        return new HierarchyResponse(result, result.size(), totalAccounts);
    }

    @Transactional(readOnly = true)
    public HierarchyWorkshopDto workshopDetail(UUID workshopId) {
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        return buildWorkshop(workshop, "");
    }

    @Transactional
    public PlatformAccountDto createUser(CurrentUser actor, String email, String displayName,
                                         String temporaryPassword, String role, UUID workshopId) {
        Workshop workshop = requireWorkshop(workshopId);
        WorkshopRole workshopRole = parseRole(role);
        String normalized = User.normalizeEmail(email);
        if (users.findByEmailNormalized(normalized).isPresent()) {
            throw ApiException.conflict("EMAIL_EXISTS", "An account with this email already exists");
        }
        User user = new User(email, passwordEncoder.encode(temporaryPassword), displayName);
        user.setStatus(UserStatus.ACTIVE);
        user = users.save(user);
        WorkshopMembership membership = memberships.save(
                new WorkshopMembership(workshop.getId(), user.getId(), workshopRole, true));
        audit(actor, workshop.getId(), user.getId(), "ACCOUNT_CREATED", null,
                Map.of("role", workshopRole.name(), "workshopId", workshop.getId().toString()));
        return account(user, membership, null);
    }

    @Transactional
    public InvitationResponse invite(CurrentUser actor, String email, String displayName,
                                     String role, UUID workshopId) {
        Workshop workshop = requireWorkshop(workshopId);
        WorkshopRole workshopRole = parseRole(role);
        String normalized = User.normalizeEmail(email);
        if (users.findByEmailNormalized(normalized).isPresent()) {
            throw ApiException.conflict("EMAIL_EXISTS", "An account with this email already exists");
        }
        User user = new User(email, passwordEncoder.encode(randomToken()), displayName);
        user.setStatus(UserStatus.PENDING_INVITATION);
        user = users.save(user);
        String rawToken = randomToken();
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        Invitation invitation = invitations.save(new Invitation(
                workshop.getId(),
                user.getId(),
                normalized,
                workshopRole,
                hash(rawToken),
                now.plus(invitationProperties.ttl()),
                actor.userId()
        ));
        audit(actor, workshop.getId(), user.getId(), "ACCOUNT_INVITED", null,
                Map.of("role", workshopRole.name(), "invitationId", invitation.getId().toString()));
        return new InvitationResponse(invitation.getId(), user.getId(), workshop.getId(),
                user.getEmail(), workshopRole.name(), invitation.getStatus().name(),
                invitation.getExpiresAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME), rawToken);
    }

    @Transactional
    public void acceptInvitation(String rawToken, String password) {
        Invitation invitation = invitations.findByTokenHash(hash(rawToken))
                .orElseThrow(() -> ApiException.unauthorized("INVITATION_INVALID", "Invitation is invalid"));
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        if (!invitation.isPending(now)) {
            throw ApiException.conflict("INVITATION_EXPIRED", "Invitation is no longer valid");
        }
        User user = users.findById(invitation.getUserId()).orElseThrow(ApiException::notFound);
        if (user.getStatus() != UserStatus.PENDING_INVITATION) {
            throw ApiException.conflict("INVITATION_ALREADY_ACCEPTED", "Invitation was already accepted");
        }
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setStatus(UserStatus.ACTIVE);
        users.save(user);
        if (memberships.findByWorkshopIdAndUserId(invitation.getWorkshopId(), user.getId()).isEmpty()) {
            memberships.save(new WorkshopMembership(
                    invitation.getWorkshopId(), user.getId(), invitation.getRole(), true));
        }
        invitation.accept(now);
        invitations.save(invitation);
        auditService.record(invitation.getWorkshopId(), user.getId(), invitation.getRole().name(),
                "INVITATION_ACCEPTED", "USER", user.getId(), null, null);
    }

    @Transactional
    public PlatformAccountDto disableUser(CurrentUser actor, UUID userId, String reason) {
        User user = requireUser(userId);
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw ApiException.conflict("ACCOUNT_NOT_ACTIVE", "Account is not active");
        }
        if (user.isPlatformAdmin() && users.countByPlatformAdminTrueAndStatus(UserStatus.ACTIVE) <= 1) {
            throw ApiException.conflict("LAST_PLATFORM_ADMIN", "Cannot disable the last Platform Admin");
        }
        WorkshopMembership primary = memberships.findFirstByUserIdAndStatusAndPrimaryTrue(userId, "ACTIVE")
                .orElse(null);
        if (primary != null && primary.getRole() == WorkshopRole.WORKSHOP_ADMIN
                && memberships.countByWorkshopIdAndRoleAndStatus(primary.getWorkshopId(),
                WorkshopRole.WORKSHOP_ADMIN, "ACTIVE") <= 1) {
            throw ApiException.conflict("LAST_WORKSHOP_ADMIN", "Cannot disable the last Workshop Admin");
        }
        user.setStatus(UserStatus.DISABLED);
        users.save(user);
        memberships.findByUserIdAndStatus(userId, "ACTIVE").forEach(membership -> {
            membership.setStatus("DISABLED");
            memberships.save(membership);
        });
        revokeSessions(userId);
        audit(actor, primary == null ? null : primary.getWorkshopId(), userId,
                "ACCOUNT_DISABLED", reason, Map.of("userId", userId.toString()));
        return account(user, primary, null);
    }

    @Transactional
    public PlatformAccountDto reactivateUser(CurrentUser actor, UUID userId, String reason) {
        User user = requireUser(userId);
        if (user.getStatus() != UserStatus.DISABLED) {
            throw ApiException.conflict("ACCOUNT_NOT_DISABLED", "Account is not disabled");
        }
        user.setStatus(UserStatus.ACTIVE);
        users.save(user);
        memberships.findByUserIdAndStatus(userId, "DISABLED").forEach(membership -> {
            membership.setStatus("ACTIVE");
            memberships.save(membership);
        });
        WorkshopMembership primary = memberships.findFirstByUserIdAndStatusAndPrimaryTrue(userId, "ACTIVE")
                .orElse(null);
        audit(actor, primary == null ? null : primary.getWorkshopId(), userId,
                "ACCOUNT_REACTIVATED", reason, Map.of("userId", userId.toString()));
        return account(user, primary, null);
    }

    @Transactional
    public PlatformAccountDto transferUser(CurrentUser actor, UUID userId, UUID targetWorkshopId, String reason) {
        User user = requireUser(userId);
        if (user.isPlatformAdmin()) {
            throw ApiException.conflict("PLATFORM_ADMIN_TRANSFER", "Platform Admin accounts do not belong to a workshop");
        }
        Workshop target = requireWorkshop(targetWorkshopId);
        WorkshopMembership membership = memberships.findFirstByUserIdAndStatusAndPrimaryTrue(userId, "ACTIVE")
                .orElseThrow(() -> ApiException.conflict("NO_ACTIVE_MEMBERSHIP", "Account has no active workshop"));
        UUID oldWorkshopId = membership.getWorkshopId();
        if (oldWorkshopId.equals(target.getId())) {
            throw ApiException.conflict("ALREADY_IN_WORKSHOP", "Account already belongs to this workshop");
        }
        if (memberships.findByWorkshopIdAndUserId(target.getId(), userId).isPresent()) {
            throw ApiException.conflict("MEMBERSHIP_EXISTS", "Account already has a membership in the target workshop");
        }
        membership.setWorkshopId(target.getId());
        membership.setPrimary(true);
        memberships.save(membership);
        revokeSessions(userId);
        audit(actor, target.getId(), userId, "ACCOUNT_TRANSFERRED", reason,
                Map.of("fromWorkshopId", oldWorkshopId.toString(),
                        "toWorkshopId", target.getId().toString()));
        return account(user, membership, null);
    }

    @Transactional(readOnly = true)
    public List<AuditEventDto> auditEvents(int limit) {
        int bounded = Math.max(1, Math.min(limit, 200));
        return auditEvents.findTop100ByOrderByOccurredAtDesc().stream()
                .limit(bounded)
                .map(this::toAuditDto)
                .toList();
    }

    private HierarchyWorkshopDto buildWorkshop(Workshop workshop, String filter) {
        List<WorkshopMembership> members = memberships.findByWorkshopIdOrderByRoleAsc(workshop.getId());
        List<PlatformAccountDto> admins = new ArrayList<>();
        List<PlatformAccountDto> technicians = new ArrayList<>();
        for (WorkshopMembership membership : members) {
            if (!filter.isEmpty() && !membership.getStatus().equals(filter)) {
                continue;
            }
            User user = users.findById(membership.getUserId()).orElse(null);
            if (user == null) {
                continue;
            }
            PlatformAccountDto dto = account(user, membership, null);
            if (membership.getRole() == WorkshopRole.WORKSHOP_ADMIN) {
                admins.add(dto);
            } else {
                technicians.add(dto);
            }
        }
        List<PlatformAccountDto> pending = new ArrayList<>();
        if (filter.isEmpty() || filter.equals("PENDING")) {
            for (Invitation invitation : invitations.findByWorkshopIdAndStatus(
                    workshop.getId(), InvitationStatus.PENDING)) {
                User user = users.findById(invitation.getUserId()).orElse(null);
                if (user == null) {
                    continue;
                }
                pending.add(new PlatformAccountDto(user.getId(), user.getDisplayName(), user.getEmail(),
                        maskEmail(user.getEmail()), invitation.getRole().name(), "PENDING_INVITATION",
                        workshop.getId(), false, invitation.getExpiresAt().toString()));
            }
        }
        long memberCount = members.stream().filter(m -> m.getStatus().equals("ACTIVE")).count();
        return new HierarchyWorkshopDto(workshop.getId(), workshop.getName(), workshop.getBranchName(),
                workshop.getStatus(), memberCount, admins, technicians, pending);
    }

    private PlatformAccountDto account(User user, WorkshopMembership membership, String invitationExpiry) {
        return new PlatformAccountDto(user.getId(), user.getDisplayName(), user.getEmail(),
                maskEmail(user.getEmail()),
                membership == null ? "UNKNOWN" : membership.getRole().name(),
                membership == null ? user.getStatus().name() : membership.getStatus(),
                membership == null ? null : membership.getWorkshopId(),
                membership != null && membership.isPrimary(),
                invitationExpiry);
    }

    private AuditEventDto toAuditDto(AuditEvent event) {
        return new AuditEventDto(event.getId(), event.getWorkshopId(), event.getActorUserId(),
                event.getActorRole(), event.getAction(), event.getEntityType(), event.getEntityId(),
                event.getOccurredAt().toString(), event.getReasonCode(), event.getMetadataJson());
    }

    private void audit(CurrentUser actor, UUID workshopId, UUID entityId, String action,
                       String reason, Map<String, String> metadata) {
        auditService.record(workshopId, actor.userId(), actor.role(), action, "USER", entityId, reason,
                json(metadata));
    }

    private String json(Map<String, String> metadata) {
        try {
            return objectMapper.writeValueAsString(metadata);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private Workshop requireWorkshop(UUID workshopId) {
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        if (!workshop.getStatus().equals("ACTIVE")) {
            throw ApiException.conflict("WORKSHOP_DISABLED", "Workshop is not active");
        }
        return workshop;
    }

    private User requireUser(UUID userId) {
        return users.findById(userId).orElseThrow(ApiException::notFound);
    }

    private WorkshopRole parseRole(String role) {
        try {
            WorkshopRole parsed = WorkshopRole.valueOf(role == null ? "" : role.trim().toUpperCase());
            return parsed;
        } catch (IllegalArgumentException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_ROLE", "error.role.invalid", "Invalid role");
        }
    }

    private void revokeSessions(UUID userId) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        for (RefreshToken token : refreshTokens.findByUserIdAndRevokedAtIsNull(userId)) {
            token.revoke(now, null);
            refreshTokens.save(token);
        }
    }

    private boolean contains(String value, String query) {
        return value != null && value.toLowerCase().contains(query);
    }

    private boolean accountMatches(PlatformAccountDto account, String query) {
        return query.isEmpty()
                || contains(account.displayName(), query)
                || contains(account.email(), query)
                || contains(account.role(), query);
    }

    private String randomToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private byte[] hash(String raw) {
        try {
            return MessageDigest.getInstance("SHA-256")
                    .digest(raw.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    private String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return "***" + (at >= 0 ? email.substring(at) : "");
        }
        return email.charAt(0) + "***" + email.substring(at);
    }
}
