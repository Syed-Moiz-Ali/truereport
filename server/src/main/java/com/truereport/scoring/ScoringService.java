package com.truereport.scoring;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.scoring.ScoringDtos.ChangeRequestInfo;
import com.truereport.scoring.ScoringDtos.GradeBoundaryDto;
import com.truereport.scoring.ScoringDtos.ScoringRuleDetail;
import com.truereport.scoring.ScoringDtos.ScoringRuleDto;
import com.truereport.scoring.ScoringDtos.UpdateScoringRuleRequest;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class ScoringService {

    private static final Set<String> CATEGORY_WEIGHT_MODES = Set.of("CONFIGURED", "EQUAL");
    private static final Set<String> CAP_GRADES = Set.of("A", "B", "C", "D");

    private static final String DEFAULT_CODE = "SCORING-DEFAULT";
    private static final String DEFAULT_NAME_EN = "Default scoring";
    private static final String DEFAULT_NAME_AR = "التقييم الافتراضي";

    private static final String ENTITY_SCORING_RULE = "SCORING_RULE";
    private static final String ENTITY_GRADE_BOUNDARIES = "GRADE_BOUNDARIES";

    private final ScoringRepository repository;
    private final FieldAuditService audit;
    private final OutboxService outbox;
    private final ObjectMapper objectMapper;

    public ScoringService(ScoringRepository repository, FieldAuditService audit,
                          OutboxService outbox, ObjectMapper objectMapper) {
        this.repository = repository;
        this.audit = audit;
        this.outbox = outbox;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public ScoringRuleDetail getActive() {
        ScoringRuleDto rule = repository.findActiveOptional()
                .or(() -> repository.insertDefaultIfAbsent(DEFAULT_CODE, DEFAULT_NAME_EN, DEFAULT_NAME_AR,
                        "CONFIGURED", true, "B"))
                .orElseThrow(() -> new IllegalStateException("Unable to create the default scoring rule"));
        return new ScoringRuleDetail(rule, repository.boundaries(rule.id()));
    }

    @Transactional
    public ScoringRuleDto updateRule(CurrentUser actor, String id, UpdateScoringRuleRequest request) {
        return updateRule(actor, id, request, null);
    }

    @Transactional
    public ScoringRuleDto updateRule(CurrentUser actor, String id, UpdateScoringRuleRequest request,
                                     HttpServletRequest http) {
        ScoringRuleDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        if (request == null) {
            throw invalidRule(List.of(FieldIssue.of("request", "SCORING_RULE_INVALID", "error.rule.invalid")));
        }
        if (repository.findPendingChange(ENTITY_SCORING_RULE, id).isPresent()) {
            throw makerCheckerPending();
        }

        String mode = request.categoryWeightMode() == null
                ? existing.categoryWeightMode()
                : request.categoryWeightMode().trim().toUpperCase(Locale.ROOT);
        boolean capEnabled = request.hardFailCapEnabled() == null
                ? existing.hardFailCapEnabled()
                : request.hardFailCapEnabled();
        String capGrade = request.hardFailCapGrade() == null
                ? existing.hardFailCapGrade()
                : request.hardFailCapGrade().trim().toUpperCase(Locale.ROOT);
        String nameEn = request.nameEn() == null ? existing.nameEn() : request.nameEn().trim();
        String nameAr = request.nameAr() == null ? existing.nameAr() : request.nameAr().trim();

        List<FieldIssue> issues = new ArrayList<>();
        if (mode == null || !CATEGORY_WEIGHT_MODES.contains(mode)) {
            issues.add(FieldIssue.of("categoryWeightMode", "CATEGORY_WEIGHT_MODE_INVALID", "error.rule.invalid"));
        }
        if (capEnabled && (capGrade == null || !CAP_GRADES.contains(capGrade))) {
            issues.add(FieldIssue.of("hardFailCapGrade", "HARD_FAIL_CAP_GRADE_INVALID", "error.rule.invalid"));
        }
        if (nameEn == null || nameEn.isBlank()) {
            issues.add(FieldIssue.of("nameEn", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (nameAr == null || nameAr.isBlank()) {
            issues.add(FieldIssue.of("nameAr", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (!issues.isEmpty()) {
            throw invalidRule(issues);
        }

        repository.updateRule(id, mode, capEnabled, capGrade, nameEn, nameAr, true);
        repository.createChangeRequest(ENTITY_SCORING_RULE, id, "UPDATE", toJson(request),
                actor.userId().toString());
        ScoringRuleDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "SCORING_RULE_UPDATE_PROPOSED", ENTITY_SCORING_RULE, id,
                existing, updated, null, http);
        return updated;
    }

    @Transactional
    public ScoringRuleDto approveRule(CurrentUser actor, String id) {
        return approveRule(actor, id, null);
    }

    @Transactional
    public ScoringRuleDto approveRule(CurrentUser actor, String id, HttpServletRequest http) {
        ScoringRuleDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        ChangeRequestInfo change = requirePending(ENTITY_SCORING_RULE, id);
        requireDifferentApprover(actor, change);

        repository.markPending(id, false);
        repository.approveChange(change.id(), actor.userId().toString());
        ScoringRuleDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "SCORING_RULE_APPROVED", ENTITY_SCORING_RULE, id,
                existing, updated, null, http);
        outbox.publish(ENTITY_SCORING_RULE, id, "SCORING_RULE_APPROVED",
                Map.of("ruleId", id, "code", updated.code()));
        return updated;
    }

    @Transactional
    public ScoringRuleDto rejectRule(CurrentUser actor, String id, String reason) {
        return rejectRule(actor, id, reason, null);
    }

    @Transactional
    public ScoringRuleDto rejectRule(CurrentUser actor, String id, String reason, HttpServletRequest http) {
        ScoringRuleDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        ChangeRequestInfo change = requirePending(ENTITY_SCORING_RULE, id);

        repository.rejectChange(change.id(), actor.userId().toString(), reason);
        repository.markPending(id, false);
        ScoringRuleDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "SCORING_RULE_REJECTED", ENTITY_SCORING_RULE, id,
                existing, updated, reason, http);
        return updated;
    }

    @Transactional
    public List<GradeBoundaryDto> replaceBoundaries(CurrentUser actor, String id,
                                                    List<GradeBoundaryDto> boundaries) {
        return replaceBoundaries(actor, id, boundaries, null);
    }

    @Transactional
    public List<GradeBoundaryDto> replaceBoundaries(CurrentUser actor, String id,
                                                    List<GradeBoundaryDto> boundaries,
                                                    HttpServletRequest http) {
        repository.findById(id).orElseThrow(ApiException::notFound);
        List<GradeBoundaryDto> sorted = validateBoundaries(boundaries);
        if (repository.findPendingChange(ENTITY_GRADE_BOUNDARIES, id).isPresent()) {
            throw makerCheckerPending();
        }

        List<GradeBoundaryDto> before = repository.boundaries(id);
        repository.replaceBoundaries(id, sorted, false);
        repository.createChangeRequest(ENTITY_GRADE_BOUNDARIES, id, "REPLACE", toJson(sorted),
                actor.userId().toString());
        List<GradeBoundaryDto> stored = repository.boundaries(id);
        audit.record(actor, "GRADE_BOUNDARIES_REPLACE_PROPOSED", ENTITY_GRADE_BOUNDARIES, id,
                before, stored, null, http);
        return stored;
    }

    @Transactional
    public List<GradeBoundaryDto> approveBoundaries(CurrentUser actor, String id) {
        return approveBoundaries(actor, id, null);
    }

    @Transactional
    public List<GradeBoundaryDto> approveBoundaries(CurrentUser actor, String id, HttpServletRequest http) {
        repository.findById(id).orElseThrow(ApiException::notFound);
        ChangeRequestInfo change = requirePending(ENTITY_GRADE_BOUNDARIES, id);
        requireDifferentApprover(actor, change);

        List<GradeBoundaryDto> current = repository.boundaries(id);
        repository.replaceBoundaries(id, current, true);
        repository.approveChange(change.id(), actor.userId().toString());
        List<GradeBoundaryDto> updated = repository.boundaries(id);
        audit.record(actor, "GRADE_BOUNDARIES_APPROVED", ENTITY_GRADE_BOUNDARIES, id,
                current, updated, null, http);
        return updated;
    }

    @Transactional(readOnly = true)
    public List<GradeBoundaryDto> boundaries(String ruleId) {
        repository.findById(ruleId).orElseThrow(ApiException::notFound);
        return repository.boundaries(ruleId);
    }

    private ChangeRequestInfo requirePending(String entityType, String entityId) {
        return repository.findPendingChange(entityType, entityId)
                .orElseThrow(() -> ApiException.unprocessable("MAKER_CHECKER_NOT_PENDING",
                        "No change request is pending approval"));
    }

    private static void requireDifferentApprover(CurrentUser actor, ChangeRequestInfo change) {
        if (change.proposedBy() != null && change.proposedBy().equals(actor.userId().toString())) {
            throw new ApiException(HttpStatus.CONFLICT, "MAKER_CHECKER_SELF_APPROVAL",
                    "error.makerChecker.selfApproval", "You cannot approve your own change.");
        }
    }

    private static List<GradeBoundaryDto> validateBoundaries(List<GradeBoundaryDto> boundaries) {
        if (boundaries == null || boundaries.isEmpty()) {
            throw invalidBoundaries(List.of(genericBoundaryIssue()));
        }
        List<FieldIssue> issues = new ArrayList<>();
        for (GradeBoundaryDto boundary : boundaries) {
            if (boundary == null) {
                throw invalidBoundaries(List.of(genericBoundaryIssue()));
            }
        }
        List<GradeBoundaryDto> sorted = new ArrayList<>(boundaries);
        sorted.sort(Comparator.comparingInt(GradeBoundaryDto::minScore));

        Set<String> codes = new HashSet<>();
        int expected = 0;
        for (GradeBoundaryDto boundary : sorted) {
            String code = boundary.gradeCode() == null ? null : boundary.gradeCode().trim();
            if (code == null || code.isBlank()) {
                issues.add(genericBoundaryIssue());
            } else if (!codes.add(code)) {
                issues.add(genericBoundaryIssue());
            }
            if (boundary.minScore() < 0 || boundary.maxScore() > 100
                    || boundary.minScore() > boundary.maxScore()) {
                issues.add(genericBoundaryIssue());
            }
            if (boundary.minScore() != expected) {
                issues.add(genericBoundaryIssue());
            }
            if (boundary.labelEn() == null || boundary.labelEn().isBlank()) {
                issues.add(FieldIssue.of("labelEn", "TRANSLATION_REQUIRED", "error.translation.required"));
            }
            if (boundary.labelAr() == null || boundary.labelAr().isBlank()) {
                issues.add(FieldIssue.of("labelAr", "TRANSLATION_REQUIRED", "error.translation.required"));
            }
            expected = boundary.maxScore() + 1;
        }
        if (expected != 101) {
            issues.add(genericBoundaryIssue());
        }
        if (!issues.isEmpty()) {
            if (issues.stream().noneMatch(issue -> "error.gradeBoundaries.invalid".equals(issue.messageKey()))) {
                issues.add(genericBoundaryIssue());
            }
            throw invalidBoundaries(issues);
        }
        return sorted;
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            return String.valueOf(value);
        }
    }

    private static FieldIssue genericBoundaryIssue() {
        return FieldIssue.of("boundaries", "GRADE_BOUNDARIES_INVALID", "error.gradeBoundaries.invalid");
    }

    private static ApiException invalidBoundaries(List<FieldIssue> issues) {
        return ApiException.validation("GRADE_BOUNDARIES_INVALID",
                "Grade boundaries must cover 0-100 without gaps or overlaps", issues);
    }

    private static ApiException invalidRule(List<FieldIssue> issues) {
        return ApiException.validation("SCORING_RULE_INVALID",
                "Scoring rule configuration is invalid", issues);
    }

    private static ApiException makerCheckerPending() {
        return new ApiException(HttpStatus.CONFLICT, "MAKER_CHECKER_PENDING",
                "error.makerChecker.pending", "A change is already pending approval.");
    }
}
