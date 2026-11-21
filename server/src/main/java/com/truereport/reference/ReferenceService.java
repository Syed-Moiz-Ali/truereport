package com.truereport.reference;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.reference.ReferenceRepository.ReferenceRow;
import com.truereport.reference.ReferenceRepository.TransitionRow;
import com.truereport.reference.api.ReferenceDtos.DropdownValueDto;
import com.truereport.reference.api.ReferenceDtos.ImpactDto;
import com.truereport.reference.api.ReferenceDtos.ReferenceRecordDto;
import com.truereport.reference.api.ReferenceDtos.TransitionDto;
import com.truereport.reference.api.ReferenceWriteDtos.ReferenceWriteRequest;
import com.truereport.reference.api.ReferenceWriteDtos.ReorderEntry;
import com.truereport.reference.api.ReferenceWriteDtos.TransitionEntry;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.uimessages.PlatformUiMessageCatalog;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class ReferenceService {

    private static final Set<String> DROPDOWN_SETS = Set.of(
            "ISSUE_TYPE", "LOCATION", "COMPONENT", "ACTION", "URGENCY", "REASON", "UNIT");
    private static final Set<String> TONES = Set.of(
            "neutral", "info", "success", "warning", "danger");
    private static final Set<String> CLIENTS = Set.of(
            "platform_admin", "workshop_admin", "technician");
    private static final Set<String> TRANSITION_ROLES = Set.of(
            "PLATFORM_ADMIN", "WORKSHOP_ADMIN", "TECHNICIAN");

    private final ReferenceRepository repository;
    private final PlatformUiMessageCatalog uiMessages;
    private final FieldAuditService audit;
    private final ObjectMapper objectMapper;

    public ReferenceService(ReferenceRepository repository,
                            PlatformUiMessageCatalog uiMessages,
                            FieldAuditService audit,
                            ObjectMapper objectMapper) {
        this.repository = repository;
        this.uiMessages = uiMessages;
        this.audit = audit;
        this.objectMapper = objectMapper;
    }

    // ------------------------------------------------------------------ reads

    @Transactional(readOnly = true)
    public List<ReferenceRecordDto> statuses(String statusType, CurrentUser caller,
                                             boolean includeDraft) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return records(domainKey, caller, includeDraft);
    }

    @Transactional(readOnly = true)
    public List<ReferenceRecordDto> enums(String enumCode, CurrentUser caller,
                                          boolean includeDraft) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return records(domainKey, caller, includeDraft);
    }

    @Transactional(readOnly = true)
    public List<TransitionDto> transitions(String entity, CurrentUser caller) {
        if (!ReferenceTaxonomy.TRANSITION_ENTITIES.containsKey(entity)) {
            throw ApiException.notFound();
        }
        List<TransitionDto> result = new ArrayList<>();
        for (TransitionRow row : repository.findTransitions(entity)) {
            result.add(new TransitionDto(row.fromCode(), row.toCode(), row.role(),
                    object(row.guardJson()), row.version()));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<DropdownValueDto> dropdowns(String setCode, CurrentUser caller) {
        if (setCode == null || !DROPDOWN_SETS.contains(setCode)) {
            throw ApiException.notFound();
        }
        ReferenceRepository.OptionSetRow set = repository.findOptionSet(setCode).orElse(null);
        if (set == null) {
            return List.of();
        }
        List<DropdownValueDto> result = new ArrayList<>();
        for (ReferenceRepository.OptionValueRow row : repository.findOptionValues(set.id())) {
            String label = row.label() == null ? "" : row.label().trim();
            boolean isKey = isCatalogKey(label);
            result.add(new DropdownValueDto(row.code(), isKey ? label : "",
                    isKey ? null : label, row.sortOrder(),
                    "ACTIVE".equals(row.status()), parentCode(row.metadataJson()),
                    row.version()));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public ImpactDto impact(String domain, String code) {
        String domainKey = statusOrEnumDomain(domain);
        requireRow(domainKey, code);
        return repository.impact(domainKey, code);
    }

    // ----------------------------------------------------------------- writes

    /**
     * Reference codes are backend-owned after the option-set merge. The route
     * is kept for API compatibility but never creates a value.
     */
    @Transactional
    public ReferenceRecordDto createStatus(String statusType, ReferenceWriteRequest request,
                                           CurrentUser actor) {
        requireDomain(statusType);
        throw backendDefinedCodes();
    }

    @Transactional
    public ReferenceRecordDto updateStatus(String statusType, String code,
                                           ReferenceWriteRequest request, CurrentUser actor) {
        String domainKey = requireDomain(statusType);
        return update(domainKey, code, request, actor);
    }

    @Transactional
    public ReferenceRecordDto publishStatus(String statusType, String code, CurrentUser actor) {
        String domainKey = requireDomain(statusType);
        return publish(domainKey, code, actor);
    }

    /**
     * Retiring a system code would break clients and stored rows; admins can
     * only edit its presentation. Kept as a route for contract compatibility.
     */
    @Transactional
    public ReferenceRecordDto retireStatus(String statusType, String code, CurrentUser actor) {
        requireDomain(statusType);
        throw backendDefinedCodes();
    }

    @Transactional
    public List<ReferenceRecordDto> reorderStatuses(String statusType, List<ReorderEntry> entries,
                                                    CurrentUser actor) {
        String domainKey = requireDomain(statusType);
        return reorder(domainKey, entries, actor);
    }

    @Transactional
    public List<ReferenceRecordDto> reorderEnums(String enumCode, List<ReorderEntry> entries,
                                                 CurrentUser actor) {
        String domainKey = requireEnum(enumCode);
        return reorder(domainKey, entries, actor);
    }

    @Transactional
    public ReferenceRecordDto createEnum(String enumCode, ReferenceWriteRequest request,
                                         CurrentUser actor) {
        requireEnum(enumCode);
        throw backendDefinedCodes();
    }

    @Transactional
    public ReferenceRecordDto updateEnum(String enumCode, String code,
                                         ReferenceWriteRequest request, CurrentUser actor) {
        String domainKey = requireEnum(enumCode);
        return update(domainKey, code, request, actor);
    }

    @Transactional
    public ReferenceRecordDto publishEnum(String enumCode, String code, CurrentUser actor) {
        String domainKey = requireEnum(enumCode);
        return publish(domainKey, code, actor);
    }

    @Transactional
    public ReferenceRecordDto retireEnum(String enumCode, String code, CurrentUser actor) {
        requireEnum(enumCode);
        throw backendDefinedCodes();
    }

    @Transactional
    public List<TransitionDto> replaceTransitions(String entity, List<TransitionEntry> entries,
                                                  CurrentUser actor) {
        if (!ReferenceTaxonomy.TRANSITION_ENTITIES.containsKey(entity)) {
            throw ApiException.notFound();
        }
        List<TransitionEntry> safe = entries == null ? List.of() : entries;
        for (TransitionEntry entry : safe) {
            if (entry == null || blank(entry.fromCode()) || blank(entry.toCode())
                    || blank(entry.role()) || !TRANSITION_ROLES.contains(entry.role())) {
                throw ApiException.unprocessable("TRANSITION_INVALID",
                        "Transitions need fromCode, toCode and a known role");
            }
        }
        repository.deleteTransitions(entity);
        for (TransitionEntry entry : safe) {
            repository.insertTransition(entity, entry.fromCode().trim(), entry.toCode().trim(),
                    entry.role().trim(), entry.guard() == null ? "{}" : json(entry.guard()));
        }
        syncAllowedNext(entity, safe);
        audit(actor, "reference.transition.updated", entity, null,
                Map.of("count", safe.size()));
        return transitions(entity, actor);
    }

    private ReferenceRecordDto update(String domainKey, String code,
                                      ReferenceWriteRequest request, CurrentUser actor) {
        ReferenceRow before = requireRow(domainKey, code);
        if (!blank(request.code()) && !request.code().trim().equals(code)) {
            throw ApiException.unprocessable("CODE_IMMUTABLE",
                    "Reference code is immutable after create");
        }
        if ("RETIRED".equals(referenceStatus(before.status()))) {
            throw ApiException.conflict("REFERENCE_RETIRED",
                    "Retired reference records cannot be edited");
        }
        WriteValues values = validate(domainKey, request, code);
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("tone", values.tone);
        metadata.put("icon", values.icon);
        metadata.put("selectable", values.selectable);
        metadata.put("visibleFor", values.visibleFor);
        metadata.put("allowedNext", values.allowedNext);
        metadata.put("legacyDomain", domainKey);
        repository.updateValue(domainKey, code, catalogLabel(values.labelKey), values.labelKey,
                values.order, json(metadata));
        audit(actor, "reference." + family(domainKey) + ".updated", domainKey, code,
                values.asMap());
        return dto(requireRow(domainKey, code));
    }

    private ReferenceRecordDto publish(String domainKey, String code, CurrentUser actor) {
        ReferenceRow row = requireRow(domainKey, code);
        if (!"DRAFT".equals(referenceStatus(row.status()))) {
            throw ApiException.conflict("REFERENCE_STATE_INVALID",
                    "Only DRAFT references can be published");
        }
        repository.updateValueStatus(domainKey, code, "ACTIVE");
        audit(actor, "reference." + family(domainKey) + ".published", domainKey, code,
                Map.of("code", code));
        return dto(requireRow(domainKey, code));
    }

    private List<ReferenceRecordDto> reorder(String domainKey, List<ReorderEntry> entries,
                                             CurrentUser actor) {
        List<ReorderEntry> safe = entries == null ? List.of() : entries;
        for (ReorderEntry entry : safe) {
            if (entry == null || blank(entry.code()) || entry.order() == null
                    || entry.order() < 0) {
                throw ApiException.unprocessable("REORDER_INVALID",
                        "Reorder entries need code and a non-negative order");
            }
            requireRow(domainKey, entry.code());
        }
        for (ReorderEntry entry : safe) {
            repository.updateValueOrder(domainKey, entry.code(), entry.order());
        }
        audit(actor, "reference." + family(domainKey) + ".reordered", domainKey, null,
                Map.of("count", safe.size()));
        return records(domainKey, actor, true);
    }

    /**
     * Mirrors the transition graph onto the status values so the legacy
     * {@code allowedNext} field of {@code /reference/statuses} stays in sync.
     */
    private void syncAllowedNext(String entity, List<TransitionEntry> entries) {
        String domainKey = switch (entity) {
            case "job" -> ReferenceTaxonomy.JOB_STATUS;
            case "review" -> ReferenceTaxonomy.REVIEW_STATUS;
            case "publication" -> ReferenceTaxonomy.PUBLICATION_STATUS;
            default -> null;
        };
        if (domainKey == null) {
            return;
        }
        Map<String, List<String>> next = new LinkedHashMap<>();
        for (TransitionEntry entry : entries) {
            List<String> targets = next.computeIfAbsent(entry.fromCode().trim(),
                    ignored -> new ArrayList<>());
            String target = entry.toCode().trim();
            if (!targets.contains(target)) {
                targets.add(target);
            }
        }
        for (ReferenceRow row : repository.findDomain(domainKey, true)) {
            Map<String, Object> metadata = object(row.metadataJson());
            metadata.put("allowedNext", next.getOrDefault(row.code(), List.of()));
            repository.updateValueMetadata(domainKey, row.code(), json(metadata));
        }
    }

    // --------------------------------------------------------------- helpers

    private record WriteValues(String labelKey, String tone, String icon, int order,
                               boolean selectable, List<String> visibleFor,
                               List<String> allowedNext) {
        Map<String, Object> asMap() {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("labelKey", labelKey);
            map.put("tone", tone);
            map.put("icon", icon);
            map.put("order", order);
            map.put("selectable", selectable);
            map.put("visibleFor", visibleFor);
            map.put("allowedNext", allowedNext);
            return map;
        }
    }

    private WriteValues validate(String domainKey, ReferenceWriteRequest request, String code) {
        if (request == null) {
            throw ApiException.unprocessable("REFERENCE_INVALID", "A request body is required");
        }
        String labelKey = request.labelKey() == null ? "" : request.labelKey().trim();
        if (labelKey.isEmpty() || !isCatalogKey(labelKey)) {
            throw ApiException.unprocessable("LABEL_KEY_UNKNOWN",
                    "labelKey is not present in the UI catalogs: " + labelKey);
        }
        String tone = blank(request.tone()) ? "neutral" : request.tone().trim();
        if (!TONES.contains(tone)) {
            throw ApiException.unprocessable("TONE_INVALID", "Unknown tone: " + tone);
        }
        int order = request.order() == null ? 0 : request.order();
        if (order < 0) {
            throw ApiException.unprocessable("ORDER_INVALID", "order must be >= 0");
        }
        List<String> visibleFor = request.visibleFor() == null ? List.of()
                : request.visibleFor().stream().filter(value -> !blank(value))
                .map(String::trim).distinct().toList();
        if (visibleFor.isEmpty() || !CLIENTS.containsAll(visibleFor)) {
            throw ApiException.unprocessable("VISIBLE_FOR_INVALID",
                    "visibleFor must be a non-empty subset of " + CLIENTS);
        }
        List<String> allowedNext = request.allowedNext() == null ? List.of()
                : request.allowedNext().stream().filter(value -> !blank(value))
                .map(String::trim).distinct().toList();
        String icon = blank(request.icon()) ? "circle" : request.icon().trim();
        return new WriteValues(labelKey, tone, icon, order,
                request.selectable() == null || request.selectable(), visibleFor, allowedNext);
    }

    private List<ReferenceRecordDto> records(String domainKey, CurrentUser caller,
                                             boolean includeDraft) {
        if (includeDraft && !caller.isPlatformAdmin()) {
            throw ApiException.forbidden();
        }
        String client = clientName(caller);
        List<ReferenceRecordDto> result = new ArrayList<>();
        for (ReferenceRow row : repository.findDomain(domainKey, includeDraft)) {
            List<String> visibleFor = strings(object(row.metadataJson()).get("visibleFor"));
            if (!visibleFor.isEmpty() && !visibleFor.contains(client)) {
                continue;
            }
            result.add(dto(row));
        }
        return result;
    }

    private ReferenceRecordDto dto(ReferenceRow row) {
        Map<String, Object> metadata = object(row.metadataJson());
        return new ReferenceRecordDto(row.code(), row.labelKey(),
                text(metadata, "tone", "neutral"), text(metadata, "icon", "circle"),
                row.sortOrder(), flag(metadata, "selectable", true),
                strings(metadata.get("visibleFor")), strings(metadata.get("allowedNext")),
                row.version(), referenceStatus(row.status()));
    }

    private ReferenceRow requireRow(String domainKey, String code) {
        return repository.find(domainKey, code).orElseThrow(ApiException::notFound);
    }

    private String requireDomain(String statusType) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return domainKey;
    }

    private String requireEnum(String enumCode) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return domainKey;
    }

    private static ApiException backendDefinedCodes() {
        return ApiException.unprocessable("REFERENCE_CODES_BACKEND_DEFINED",
                "Reference codes are backend-defined; edit label, tone, icon or order instead");
    }

    private String statusOrEnumDomain(String domain) {
        String status = ReferenceTaxonomy.STATUS_TYPES.get(domain);
        if (status != null) {
            return status;
        }
        String enumeration = ReferenceTaxonomy.ENUM_CODES.get(domain);
        if (enumeration != null) {
            return enumeration;
        }
        throw ApiException.notFound();
    }

    private String catalogLabel(String labelKey) {
        for (String namespace : List.of("common", "workshop_admin", "technician",
                "platform_admin")) {
            String value = uiMessages.namespace(namespace, "en").values().get(labelKey);
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    private boolean isCatalogKey(String label) {
        if (label == null || label.isBlank() || label.indexOf(' ') >= 0) {
            return false;
        }
        return uiMessages.namespace("common", "en").values().containsKey(label)
                || uiMessages.namespace("workshop_admin", "en").values().containsKey(label)
                || uiMessages.namespace("technician", "en").values().containsKey(label)
                || uiMessages.namespace("platform_admin", "en").values().containsKey(label);
    }

    private String parentCode(String metadataJson) {
        Map<String, Object> metadata = object(metadataJson);
        Object parent = metadata.get("parentCode");
        if (parent == null) {
            parent = metadata.get("parent");
        }
        return parent == null ? null : parent.toString();
    }

    private List<String> strings(Object value) {
        if (value == null) {
            return List.of();
        }
        List<String> result = new ArrayList<>();
        if (value instanceof List<?> list) {
            for (Object item : list) {
                if (item != null) {
                    result.add(item.toString());
                }
            }
            return List.copyOf(result);
        }
        if (value instanceof String text) {
            return strings(text);
        }
        return List.of();
    }

    private List<String> strings(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        try {
            JsonNode node = objectMapper.readTree(json);
            List<String> values = new ArrayList<>();
            if (node.isArray()) {
                node.forEach(item -> values.add(item.asText()));
            }
            return List.copyOf(values);
        } catch (Exception exception) {
            throw new IllegalStateException("Invalid reference taxonomy JSON", exception);
        }
    }

    private Map<String, Object> object(String json) {
        if (json == null || json.isBlank()) {
            return new LinkedHashMap<>();
        }
        try {
            JsonNode node = objectMapper.readTree(json);
            if (!node.isObject()) {
                return new LinkedHashMap<>();
            }
            Map<String, Object> values = new LinkedHashMap<>();
            node.fields().forEachRemaining(entry ->
                    values.put(entry.getKey(),
                            objectMapper.convertValue(entry.getValue(), Object.class)));
            return values;
        } catch (Exception exception) {
            throw new IllegalStateException("Invalid reference taxonomy JSON", exception);
        }
    }

    private static String text(Map<String, Object> metadata, String key, String fallback) {
        Object value = metadata.get(key);
        return value == null || value.toString().isBlank() ? fallback : value.toString();
    }

    private static boolean flag(Map<String, Object> metadata, String key, boolean fallback) {
        Object value = metadata.get(key);
        if (value instanceof Boolean bool) {
            return bool;
        }
        return value == null ? fallback : Boolean.parseBoolean(value.toString());
    }

    /** Option-set status is ACTIVE; the reference contract keeps PUBLISHED. */
    private static String referenceStatus(String status) {
        return "ACTIVE".equals(status) ? "PUBLISHED" : status;
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new IllegalStateException("Cannot serialize reference JSON", exception);
        }
    }

    private void audit(CurrentUser actor, String action, String domainKey, String code,
                       Object metadata) {
        audit.record(actor, action, "REFERENCE_DOMAIN",
                code == null ? domainKey : domainKey + ":" + code, null, metadata, null, null);
    }

    private static String family(String domainKey) {
        return domainKey.contains("status") ? "status" : "enum";
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private static String clientName(CurrentUser caller) {
        return switch (caller.role()) {
            case "PLATFORM_ADMIN" -> "platform_admin";
            case "WORKSHOP_ADMIN" -> "workshop_admin";
            case "TECHNICIAN" -> "technician";
            default -> "";
        };
    }
}
