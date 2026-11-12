package com.truereport.governance;

import com.truereport.governance.GovernanceDtos.ConfigHealthDto;
import com.truereport.governance.GovernanceDtos.CreateReleaseRequest;
import com.truereport.governance.GovernanceDtos.HealthCheckDto;
import com.truereport.governance.GovernanceDtos.ImpactDto;
import com.truereport.governance.GovernanceDtos.ReleaseDto;
import com.truereport.localization.LocalizationService;
import com.truereport.masterdata.config.ItemConfigRepository;
import com.truereport.masterdata.config.PlatformContentStore;
import com.truereport.masterdata.config.PlatformContentStore.ItemRow;
import com.truereport.masterdata.config.PlatformContentStore.VersionRow;
import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRuleDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class GovernanceService {

    private final JdbcTemplate jdbc;
    private final LocalizationService localizationService;
    private final ItemConfigRepository itemConfig;
    private final PlatformContentStore content;

    public GovernanceService(JdbcTemplate jdbc,
                             LocalizationService localizationService,
                             ItemConfigRepository itemConfig,
                             PlatformContentStore content) {
        this.jdbc = jdbc;
        this.localizationService = localizationService;
        this.itemConfig = itemConfig;
        this.content = content;
    }

    @Transactional(readOnly = true)
    public ConfigHealthDto configHealth() {
        List<HealthCheckDto> checks = new ArrayList<>();
        checks.add(translationCheck());
        checks.add(measurementBandCheck());
        checks.add(retiredOptionCheck());
        checks.add(safetyEvidenceCheck());
        checks.add(templateItemCheck());
        checks.add(numericMeasurementCheck());
        boolean healthy = checks.stream()
                .allMatch(check -> "OK".equals(check.severity()));
        return new ConfigHealthDto(healthy, checks);
    }

    @Transactional(readOnly = true)
    public ConfigHealthDto configHealth(String entityType) {
        ConfigHealthDto all = configHealth();
        String normalized = entityType == null ? "" : entityType.toUpperCase();
        List<HealthCheckDto> filtered = all.checks().stream()
                .filter(check -> check.code().toUpperCase().contains(normalized))
                .toList();
        boolean healthy = filtered.stream().allMatch(check -> "OK".equals(check.severity()));
        return new ConfigHealthDto(healthy, filtered);
    }

    @Transactional(readOnly = true)
    public ImpactDto impact(String entityType, String entityId) {
        String type = entityType == null ? "" : entityType.toUpperCase();
        return switch (type) {
            case "CATEGORY" -> categoryImpact(entityId);
            case "ITEM" -> itemImpact(entityId);
            case "TEMPLATE" -> templateImpact(entityId);
            default -> throw ApiException.unprocessable("IMPACT_ENTITY_UNSUPPORTED",
                    "Impact analysis supports CATEGORY, ITEM and TEMPLATE");
        };
    }

    @Transactional(readOnly = true)
    public List<ReleaseDto> releases() {
        return jdbc.query("""
                SELECT id, entity_type, entity_id, version_id, status, effective_from, notes,
                       created_by, approved_by, approved_at, created_at
                FROM platform_releases ORDER BY created_at DESC
                """, (rs, i) -> new ReleaseDto(
                rs.getString("id"), rs.getString("entity_type"), rs.getString("entity_id"),
                rs.getString("version_id"), rs.getString("status"),
                stringOf(rs.getObject("effective_from")), rs.getString("notes"),
                rs.getString("created_by"), rs.getString("approved_by"),
                stringOf(rs.getObject("approved_at")), stringOf(rs.getObject("created_at"))));
    }

    @Transactional
    public ReleaseDto createRelease(CurrentUser actor, CreateReleaseRequest request) {
        if (request == null || request.entityType() == null || request.entityId() == null) {
            throw ApiException.unprocessable("RELEASE_INVALID", "Entity type and id are required");
        }
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_releases
                    (id, entity_type, entity_id, version_id, status, effective_from, notes,
                     created_by, created_at, updated_at)
                VALUES (?, ?, ?, ?, 'DRAFT', ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, id, request.entityType().toUpperCase(), request.entityId(), request.versionId(),
                request.effectiveFrom() == null ? null : LocalDateTime.parse(request.effectiveFrom()),
                request.notes(), actor.userId().toString());
        return releases().stream().filter(r -> r.id().equals(id)).findFirst().orElseThrow();
    }

    @Transactional
    public ReleaseDto transition(CurrentUser actor, String id, String targetStatus, String reason) {
        ReleaseDto existing = releases().stream().filter(r -> r.id().equals(id)).findFirst()
                .orElseThrow(ApiException::notFound);
        String status = targetStatus == null ? "" : targetStatus.toUpperCase();
        String current = existing.status();
        boolean allowed = switch (status) {
            case "REVIEW" -> "DRAFT".equals(current);
            case "APPROVED" -> "REVIEW".equals(current);
            case "PUBLISHED" -> "APPROVED".equals(current);
            case "DEPRECATED" -> "PUBLISHED".equals(current);
            default -> false;
        };
        if (!allowed) {
            throw ApiException.conflict("RELEASE_TRANSITION_INVALID",
                    "Invalid release transition from " + current + " to " + status);
        }
        if ("APPROVED".equals(status)
                && existing.createdBy() != null
                && existing.createdBy().equals(actor.userId().toString())) {
            throw ApiException.conflict("MAKER_CHECKER_SELF_APPROVAL",
                    "You cannot approve your own change");
        }
        jdbc.update("""
                UPDATE platform_releases
                SET status = ?, approved_by = CASE WHEN ? = 'APPROVED' THEN ? ELSE approved_by END,
                    approved_at = CASE WHEN ? = 'APPROVED' THEN CURRENT_TIMESTAMP ELSE approved_at END,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, status, status, actor.userId().toString(), status, id);
        return releases().stream().filter(r -> r.id().equals(id)).findFirst().orElse(existing);
    }

    // --------------------------------------------------------------- checks

    private HealthCheckDto translationCheck() {
        var coverage = localizationService.coverage();
        int missing = coverage.namespaces().values().stream()
                .mapToInt(namespace -> namespace.missing().size()).sum();
        List<String> references = coverage.namespaces().entrySet().stream()
                .flatMap(entry -> entry.getValue().missing().stream()
                        .map(name -> entry.getKey() + "." + name))
                .limit(50).toList();
        return new HealthCheckDto("TRANSLATIONS", missing == 0 ? "OK" : "ERROR",
                missing == 0 ? "English and Arabic content is complete"
                        : missing + " translation(s) missing",
                missing == 0 ? "المحتوى الإنجليزي والعربي مكتمل"
                        : "عدد الترجمات الناقصة " + missing,
                missing, references);
    }

    private HealthCheckDto measurementBandCheck() {
        List<String> versionIds = jdbc.queryForList(
                "SELECT DISTINCT item_version_id FROM platform_measurement_bands", String.class);
        List<String> broken = versionIds.stream()
                .filter(versionId -> !nonOverlapping(itemConfig.measurementBands(versionId)))
                .toList();
        return new HealthCheckDto("MEASUREMENT_BANDS", broken.isEmpty() ? "OK" : "ERROR",
                broken.isEmpty() ? "Measurement bands are contiguous and non-overlapping"
                        : broken.size() + " item version(s) have overlapping measurement bands",
                broken.isEmpty() ? "نطاقات القياس متصلة وغير متداخلة"
                        : "عدد إصدارات العناصر ذات نطاقات قياس متداخلة " + broken.size(),
                broken.size(), broken);
    }

    private HealthCheckDto retiredOptionCheck() {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(DISTINCT v.id) FROM platform_issue_field_options fo
                JOIN platform_option_values v ON v.id = fo.option_value_id
                WHERE v.status = 'RETIRED'
                """, Integer.class);
        int affected = count == null ? 0 : count;
        return new HealthCheckDto("RETIRED_OPTIONS", affected == 0 ? "OK" : "ERROR",
                affected == 0 ? "No retired option values are referenced by active items"
                        : affected + " retired option value(s) are still referenced",
                affected == 0 ? "لا توجد قيم خيارات موقوفة مستخدمة"
                        : "عدد قيم الخيارات الموقوفة المستخدمة " + affected,
                affected, List.of());
    }

    private HealthCheckDto safetyEvidenceCheck() {
        List<String> safetyItemIds = jdbc.queryForList("""
                SELECT DISTINCT item_id FROM platform_item_versions WHERE safety_critical = TRUE
                """, String.class);
        List<String> missing = new ArrayList<>();
        for (String itemId : safetyItemIds) {
            boolean ok = content.versions(itemId).stream().anyMatch(version -> {
                List<EvidenceRuleDto> rules = itemConfig.evidenceRules(version.id());
                return rules.stream().anyMatch(rule -> "DEFECT_FOUND".equals(rule.resultCode())
                        && rule.minPhotos() >= 2 && rule.minVideos() >= 1);
            });
            if (!ok) {
                missing.add(content.item(itemId).map(ItemRow::stableCode).orElse(itemId));
            }
        }
        return new HealthCheckDto("SAFETY_EVIDENCE", missing.isEmpty() ? "OK" : "ERROR",
                missing.isEmpty() ? "Safety-critical items have FAIL evidence rules"
                        : missing.size() + " safety-critical item(s) missing FAIL evidence rules",
                missing.isEmpty() ? "العناصر الحرجة لديها قواعد أدلة للفشل"
                        : "عدد العناصر الحرجة الناقصة لقواعد أدلة الفشل " + missing.size(),
                missing.size(), missing);
    }

    private HealthCheckDto templateItemCheck() {
        List<String> empty = jdbc.query("""
                SELECT t.code FROM platform_templates t
                JOIN platform_template_versions tv ON tv.template_id = t.id
                LEFT JOIN platform_template_items ti ON ti.template_version_id = tv.id
                WHERE tv.status IN ('DRAFT', 'PUBLISHED')
                GROUP BY t.code, tv.id
                HAVING COUNT(ti.id) = 0
                """, (rs, i) -> rs.getString(1));
        return new HealthCheckDto("TEMPLATE_ITEMS", empty.isEmpty() ? "OK" : "ERROR",
                empty.isEmpty() ? "All active template versions contain items"
                        : empty.size() + " template version(s) contain zero items",
                empty.isEmpty() ? "جميع إصدارات القوالب النشطة تحتوي على عناصر"
                        : "عدد إصدارات القوالب الفارغة " + empty.size(),
                empty.size(), empty);
    }

    private HealthCheckDto numericMeasurementCheck() {
        List<String> numericItemIds = jdbc.queryForList("""
                SELECT DISTINCT item_id FROM platform_item_versions
                WHERE measurement_unit IS NOT NULL AND TRIM(measurement_unit) <> ''
                """, String.class);
        List<String> missing = new ArrayList<>();
        for (String itemId : numericItemIds) {
            boolean hasBands = content.versions(itemId).stream()
                    .anyMatch(version -> !itemConfig.measurementBands(version.id()).isEmpty());
            if (!hasBands) {
                missing.add(content.item(itemId).map(ItemRow::stableCode).orElse(itemId));
            }
        }
        return new HealthCheckDto("NUMERIC_MEASUREMENTS", missing.isEmpty() ? "OK" : "ERROR",
                missing.isEmpty() ? "Numeric items have measurement bands"
                        : missing.size() + " numeric item(s) lack measurement bands",
                missing.isEmpty() ? "العناصر الرقمية لديها نطاقات قياس"
                        : "عدد العناصر الرقمية الناقصة لنطاقات القياس " + missing.size(),
                missing.size(), missing);
    }

    private boolean nonOverlapping(List<MeasurementBandDto> bands) {
        if (bands == null || bands.isEmpty()) {
            return true;
        }
        Map<String, List<MeasurementBandDto>> grouped = bands.stream()
                .collect(Collectors.groupingBy(b -> b.fieldCode() + "|" + b.unitCode() + "|" + b.direction()));
        for (List<MeasurementBandDto> group : grouped.values()) {
            List<MeasurementBandDto> sorted = group.stream()
                    .sorted(Comparator.comparing(MeasurementBandDto::minValue)).toList();
            for (int i = 1; i < sorted.size(); i++) {
                if (sorted.get(i - 1).maxValue().compareTo(sorted.get(i).minValue()) > 0) {
                    return false;
                }
            }
        }
        return true;
    }

    // --------------------------------------------------------------- impact

    private ImpactDto categoryImpact(String categoryId) {
        UUID id;
        try {
            id = UUID.fromString(categoryId);
        } catch (IllegalArgumentException ex) {
            throw ApiException.notFound();
        }
        List<ItemRow> categoryItems = content.items().stream()
                .filter(item -> item.categoryId().equals(id.toString()))
                .toList();
        List<String> itemCodes = categoryItems.stream().map(ItemRow::stableCode).toList();
        Set<String> templateCodes = templateCodesForItems(categoryItems);
        boolean blocked = !templateCodes.isEmpty();
        return new ImpactDto("CATEGORY", categoryId, blocked, templateCodes.size(),
                categoryItems.size(), 0, List.copyOf(templateCodes), itemCodes,
                blocked ? "Category is referenced by published templates and cannot be deleted"
                        : "Category is not referenced by templates",
                blocked ? "التصنيف مستخدم في قوالب منشورة ولا يمكن حذفه"
                        : "التصنيف غير مستخدم في القوالب");
    }

    private ImpactDto itemImpact(String itemId) {
        ItemRow item = content.item(itemId).orElseThrow(ApiException::notFound);
        Set<String> templateCodes = templateCodesForItems(List.of(item));
        return new ImpactDto("ITEM", itemId, false, templateCodes.size(), 1, 0,
                List.copyOf(templateCodes), List.of(item.stableCode()),
                templateCodes.isEmpty() ? "Item is not referenced by templates"
                        : "Item is referenced by " + templateCodes.size() + " template(s)",
                templateCodes.isEmpty() ? "العنصر غير مستخدم في القوالب"
                        : "العنصر مستخدم في " + templateCodes.size() + " قالب");
    }

    private ImpactDto templateImpact(String templateId) {
        String code = jdbc.query("SELECT code FROM platform_templates WHERE id = ?",
                (rs, i) -> rs.getString(1), templateId).stream().findFirst()
                .orElseThrow(ApiException::notFound);
        Integer versionCount = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_versions WHERE template_id = ?
                """, Integer.class, templateId);
        Integer itemCount = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_items ti
                JOIN platform_template_versions tv ON tv.id = ti.template_version_id
                WHERE tv.template_id = ?
                """, Integer.class, templateId);
        return new ImpactDto("TEMPLATE", templateId, false, 1,
                itemCount == null ? 0 : itemCount, 0, List.of(code), List.of(),
                "Template has " + (versionCount == null ? 0 : versionCount) + " version(s)",
                "القالب لديه " + (versionCount == null ? 0 : versionCount) + " إصدار");
    }

    private Set<String> templateCodesForItems(List<ItemRow> sourceItems) {
        List<String> versionIds = new ArrayList<>();
        for (ItemRow item : sourceItems) {
            for (VersionRow version : content.versions(item.id())) {
                versionIds.add(version.id());
            }
        }
        if (versionIds.isEmpty()) {
            return new LinkedHashSet<>();
        }
        String placeholders = String.join(",", java.util.Collections.nCopies(versionIds.size(), "?"));
        return new LinkedHashSet<>(jdbc.query("""
                SELECT DISTINCT t.code FROM platform_template_items ti
                JOIN platform_template_versions tv ON tv.id = ti.template_version_id
                JOIN platform_templates t ON t.id = tv.template_id
                WHERE ti.item_version_id IN (%s)
                ORDER BY t.code
                """.formatted(placeholders), (rs, i) -> rs.getString(1), versionIds.toArray()));
    }

    private static String stringOf(Object value) {
        return value == null ? null : value.toString();
    }

    @SuppressWarnings("unused")
    private static List<String> empty() {
        return List.of();
    }
}
