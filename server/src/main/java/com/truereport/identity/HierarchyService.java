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
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.tenancy.WorkshopRole;
import com.truereport.identity.api.AuditEventDto;
import com.truereport.identity.api.HierarchyResponse;
import com.truereport.identity.api.HierarchyWorkshopDto;
import com.truereport.identity.api.PlatformAccountDto;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class HierarchyService {

    static final String IDEMPOTENCY_CREATE_WORKSHOP_ADMIN = "CREATE_WORKSHOP_ADMIN";
    static final String IDEMPOTENCY_CREATE_TECHNICIAN = "CREATE_TECHNICIAN";
    static final String IDEMPOTENCY_RESET_PLATFORM = "RESET_PASSWORD_PLATFORM";
    static final String IDEMPOTENCY_RESET_WORKSHOP = "RESET_PASSWORD_WORKSHOP";

    private final WorkshopRepository workshops;
    private final WorkshopMembershipRepository memberships;
    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final AccountIdempotencyKeyRepository idempotencyKeys;
    private final AuditEventRepository auditEvents;
    private final AuditService auditService;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;

    public HierarchyService(WorkshopRepository workshops,
                            WorkshopMembershipRepository memberships,
                            UserRepository users,
                            RefreshTokenRepository refreshTokens,
                            AccountIdempotencyKeyRepository idempotencyKeys,
                            AuditEventRepository auditEvents,
                            AuditService auditService,
                            PasswordEncoder passwordEncoder,
                            ObjectMapper objectMapper) {
        this.workshops = workshops;
        this.memberships = memberships;
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.idempotencyKeys = idempotencyKeys;
        this.auditEvents = auditEvents;
        this.auditService = auditService;
        this.passwordEncoder = passwordEncoder;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public HierarchyResponse hierarchy(String search, String status) {
        String query = search == null ? "" : search.trim().toLowerCase();
        String filter = status == null ? "" : status.trim().toUpperCase();
        if (!filter.isEmpty() && !List.of("ACTIVE", "DISABLED").contains(filter)) {
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
                    || dto.technicians().stream().anyMatch(a -> accountMatches(a, query));
            if (!query.isEmpty() && !workshopMatches && !accountMatches) {
                continue;
            }
            if (!filter.isEmpty() && dto.admins().isEmpty() && dto.technicians().isEmpty()) {
                continue;
            }
            result.add(dto);
            totalAccounts += dto.admins().size() + dto.technicians().size();
        }
        return new HierarchyResponse(result, result.size(), totalAccounts);
    }

    @Transactional(readOnly = true)
    public HierarchyWorkshopDto workshopDetail(UUID workshopId) {
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        return buildWorkshop(workshop, "");
    }

    /**
     * Platform Admin creates a Workshop Admin (strict chain A1: Platform Admins
     * cannot create technicians).
     */
    @Transactional
    public PlatformAccountDto createUser(CurrentUser actor, String email, String displayName,
                                         String temporaryPassword, String role, UUID workshopId,
                                         String idempotencyKey) {
        requirePlatformAdmin(actor);
        WorkshopRole workshopRole = parseRole(role);
        if (workshopRole != WorkshopRole.WORKSHOP_ADMIN) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ROLE_NOT_PERMITTED",
                    "error.role.notPermitted", "Platform Admins can only create Workshop Admin accounts");
        }
        Workshop workshop = requireWorkshop(workshopId);
        PasswordPolicy.requireValid(temporaryPassword);
        String key = requireIdempotencyKey(idempotencyKey);
        String normalized = User.normalizeEmail(email);
        String canonical = "CREATE|WORKSHOP_ADMIN|" + normalized + "|"
                + displayName + "|" + workshop.getId();
        UUID replayed = checkIdempotency(key, actor.userId(), IDEMPOTENCY_CREATE_WORKSHOP_ADMIN, canonical);
        if (replayed != null) {
            return currentAccountState(replayed);
        }
        if (users.findByEmailNormalized(normalized).isPresent()) {
            throw ApiException.conflict("EMAIL_EXISTS", "Unable to create account with this email address");
        }
        User user = new User(email, passwordEncoder.encode(temporaryPassword), displayName);
        user.setStatus(UserStatus.ACTIVE);
        user = users.save(user);
        WorkshopMembership membership = memberships.save(
                new WorkshopMembership(workshop.getId(), user.getId(), WorkshopRole.WORKSHOP_ADMIN, true));
        audit(actor, workshop.getId(), user.getId(), "ACCOUNT_CREATED", null,
                Map.of("role", WorkshopRole.WORKSHOP_ADMIN.name(), "workshopId", workshop.getId().toString()));
        rememberIdempotency(key, actor.userId(), IDEMPOTENCY_CREATE_WORKSHOP_ADMIN, canonical, user.getId());
        return account(user, membership);
    }

    /**
     * Workshop Admin creates a Technician in their own workshop
     * (strict chain A2: workshop derived from the caller, never from the request).
     */
    @Transactional
    public PlatformAccountDto createTechnician(CurrentUser caller, String email, String displayName,
                                               String initialPassword, String idempotencyKey) {
        UUID workshopId = requireWorkshopAdmin(caller);
        Workshop workshop = requireWorkshop(workshopId);
        PasswordPolicy.requireValid(initialPassword);
        String key = requireIdempotencyKey(idempotencyKey);
        String normalized = User.normalizeEmail(email);
        String canonical = "CREATE|TECHNICIAN|" + normalized + "|"
                + displayName + "|" + workshop.getId();
        UUID replayed = checkIdempotency(key, caller.userId(), IDEMPOTENCY_CREATE_TECHNICIAN, canonical);
        if (replayed != null) {
            return currentAccountState(replayed);
        }
        if (users.findByEmailNormalized(normalized).isPresent()) {
            throw ApiException.conflict("EMAIL_EXISTS", "Unable to create account with this email address");
        }
        User user = new User(email, passwordEncoder.encode(initialPassword), displayName);
        user.setStatus(UserStatus.ACTIVE);
        user = users.save(user);
        WorkshopMembership membership = memberships.save(
                new WorkshopMembership(workshop.getId(), user.getId(), WorkshopRole.TECHNICIAN, true));
        audit(caller, workshop.getId(), user.getId(), "ACCOUNT_CREATED", null,
                Map.of("role", WorkshopRole.TECHNICIAN.name(), "workshopId", workshop.getId().toString()));
        rememberIdempotency(key, caller.userId(), IDEMPOTENCY_CREATE_TECHNICIAN, canonical, user.getId());
        return account(user, membership);
    }

    /**
     * Platform Admin resets a Workshop Admin (or Platform Admin) password.
     * Technicians are never reset through this endpoint (strict chain A1).
     */
    @Transactional
    public PlatformAccountDto resetPasswordByPlatform(CurrentUser actor, UUID userId,
                                                      String newPassword, String idempotencyKey) {
        requirePlatformAdmin(actor);
        User user = requireUser(userId);
        PasswordPolicy.requireValid(newPassword);
        String key = requireIdempotencyKey(idempotencyKey);
        UUID scopeWorkshopId = resolveAdminScopeWorkshop(user);
        if (scopeWorkshopId == null && !user.isPlatformAdmin()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ROLE_NOT_PERMITTED",
                    "error.role.notPermitted", "This account cannot be reset through this endpoint");
        }
        if (user.getStatus() != UserStatus.ACTIVE && user.getStatus() != UserStatus.DISABLED) {
            throw ApiException.conflict("ACCOUNT_NOT_ACTIVE", "Account is not active");
        }
        String canonical = "RESET|" + user.getId();
        UUID replayed = checkIdempotency(key, actor.userId(), IDEMPOTENCY_RESET_PLATFORM, canonical);
        if (replayed != null) {
            return currentAccountState(replayed);
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        users.save(user);
        revokeSessions(user.getId());
        audit(actor, scopeWorkshopId, user.getId(), "ACCOUNT_PASSWORD_RESET", null,
                Map.of("userId", user.getId().toString()));
        rememberIdempotency(key, actor.userId(), IDEMPOTENCY_RESET_PLATFORM, canonical, user.getId());
        WorkshopMembership primary = memberships.findFirstByUserIdAndStatusAndPrimaryTrue(userId, "ACTIVE")
                .orElse(null);
        return account(user, primary);
    }

    /**
     * Workshop Admin resets a Technician password in their own workshop.
     * Any other target (including cross-workshop technicians) yields a neutral 404.
     */
    @Transactional
    public PlatformAccountDto resetPasswordByWorkshopAdmin(CurrentUser caller, UUID userId,
                                                           String newPassword, String idempotencyKey) {
        UUID workshopId = requireWorkshopAdmin(caller);
        PasswordPolicy.requireValid(newPassword);
        String key = requireIdempotencyKey(idempotencyKey);
        WorkshopMembership membership = memberships.findByWorkshopIdAndUserId(workshopId, userId)
                .orElseThrow(ApiException::notFound);
        if (membership.getRole() != WorkshopRole.TECHNICIAN) {
            throw ApiException.notFound();
        }
        User user = requireUser(userId);
        if (user.getStatus() != UserStatus.ACTIVE && user.getStatus() != UserStatus.DISABLED) {
            throw ApiException.conflict("ACCOUNT_NOT_ACTIVE", "Account is not active");
        }
        String canonical = "RESET|" + user.getId();
        UUID replayed = checkIdempotency(key, caller.userId(), IDEMPOTENCY_RESET_WORKSHOP, canonical);
        if (replayed != null) {
            return currentAccountState(replayed);
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        users.save(user);
        revokeSessions(user.getId());
        audit(caller, workshopId, user.getId(), "ACCOUNT_PASSWORD_RESET", null,
                Map.of("userId", user.getId().toString()));
        rememberIdempotency(key, caller.userId(), IDEMPOTENCY_RESET_WORKSHOP, canonical, user.getId());
        return account(user, membership);
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
        return account(user, primary);
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
        return account(user, primary);
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
        if (membership.getRole() == WorkshopRole.WORKSHOP_ADMIN
                && memberships.countByWorkshopIdAndRoleAndStatus(oldWorkshopId,
                WorkshopRole.WORKSHOP_ADMIN, "ACTIVE") <= 1) {
            throw ApiException.conflict("LAST_WORKSHOP_ADMIN", "Cannot transfer the last Workshop Admin");
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
        return account(user, membership);
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
            PlatformAccountDto dto = account(user, membership);
            if (membership.getRole() == WorkshopRole.WORKSHOP_ADMIN) {
                admins.add(dto);
            } else {
                technicians.add(dto);
            }
        }
        long memberCount = members.stream().filter(m -> m.getStatus().equals("ACTIVE")).count();
        return new HierarchyWorkshopDto(workshop.getId(), workshop.getName(), workshop.getBranchName(),
                workshop.getStatus(), memberCount, admins, technicians);
    }

    private PlatformAccountDto account(User user, WorkshopMembership membership) {
        return new PlatformAccountDto(user.getId(), user.getDisplayName(), user.getEmail(),
                maskEmail(user.getEmail()),
                membership == null ? "UNKNOWN" : membership.getRole().name(),
                membership == null ? user.getStatus().name() : membership.getStatus(),
                membership == null ? null : membership.getWorkshopId(),
                membership != null && membership.isPrimary());
    }

    private PlatformAccountDto currentAccountState(UUID userId) {
        User user = requireUser(userId);
        WorkshopMembership primary = memberships.findFirstByUserIdAndStatusAndPrimaryTrue(userId, "ACTIVE")
                .orElse(null);
        return account(user, primary);
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
            return WorkshopRole.valueOf(role == null ? "" : role.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_ROLE", "error.role.invalid", "Invalid role");
        }
    }

    private void requirePlatformAdmin(CurrentUser actor) {
        if (actor == null || !actor.isPlatformAdmin()) {
            throw ApiException.forbidden();
        }
    }

    private UUID requireWorkshopAdmin(CurrentUser caller) {
        if (caller == null || !caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.forbidden();
        }
        return caller.workshopId();
    }

    /**
     * Resolves the workshop scope for a platform password reset. Returns the
     * primary workshop for Workshop Admin targets, {@code null} for Platform
     * Admin targets, and throws for Technician targets (strict chain A1).
     */
    private UUID resolveAdminScopeWorkshop(User user) {
        if (user.isPlatformAdmin()) {
            return null;
        }
        WorkshopMembership primary = memberships.findFirstByUserIdAndStatusAndPrimaryTrue(user.getId(), "ACTIVE")
                .orElse(null);
        if (primary == null || primary.getRole() != WorkshopRole.WORKSHOP_ADMIN) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ROLE_NOT_PERMITTED",
                    "error.role.notPermitted", "This account cannot be reset through this endpoint");
        }
        return primary.getWorkshopId();
    }

    private String requireIdempotencyKey(String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "IDEMPOTENCY_KEY_REQUIRED",
                    "error.idempotency.required", "Idempotency-Key is required");
        }
        return idempotencyKey.trim();
    }

    private UUID checkIdempotency(String idempotencyKey, UUID actorUserId, String endpoint, String canonical) {
        byte[] keyHash = sha256(idempotencyKey);
        byte[] requestHash = sha256(canonical);
        return idempotencyKeys.findByKeyHashAndActorUserIdAndEndpoint(keyHash, actorUserId, endpoint)
                .map(existing -> {
                    if (!Arrays.equals(existing.getRequestHash(), requestHash)) {
                        throw ApiException.conflict("IDEMPOTENCY_KEY_REUSED",
                                "Idempotency key was reused with a different request");
                    }
                    return existing.getUserId();
                })
                .orElse(null);
    }

    private void rememberIdempotency(String idempotencyKey, UUID actorUserId, String endpoint,
                                     String canonical, UUID userId) {
        byte[] keyHash = sha256(idempotencyKey);
        byte[] requestHash = sha256(canonical);
        try {
            idempotencyKeys.save(new AccountIdempotencyKey(keyHash, actorUserId, endpoint, requestHash, userId));
        } catch (DataIntegrityViolationException e) {
            UUID replayed = checkIdempotency(idempotencyKey, actorUserId, endpoint, canonical);
            if (replayed == null || !replayed.equals(userId)) {
                throw ApiException.conflict("IDEMPOTENCY_KEY_REUSED",
                        "Idempotency key was reused with a different request");
            }
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

    private byte[] sha256(String raw) {
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
