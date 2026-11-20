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
        return records("STATUS", domainKey, caller, includeDraft);
    }

    @Transactional(readOnly = true)
    public List<ReferenceRecordDto> enums(String enumCode, CurrentUser caller,
                                          boolean includeDraft) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return records("ENUM", domainKey, caller, includeDraft);
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

    @Transactional
    public ReferenceRecordDto createStatus(String statusType, ReferenceWriteRequest request,
                                           CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return create("STATUS", domainKey, request, actor);
    }

    @Transactional
    public ReferenceRecordDto updateStatus(String statusType, String code,
                                           ReferenceWriteRequest request, CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return update(domainKey, code, request, actor);
    }

    @Transactional
    public ReferenceRecordDto publishStatus(String statusType, String code, CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return publish(domainKey, code, actor);
    }

    @Transactional
    public ReferenceRecordDto retireStatus(String statusType, String code, CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return retire(domainKey, code, actor);
    }

    @Transactional
    public List<ReferenceRecordDto> reorderStatuses(String statusType, List<ReorderEntry> entries,
                                                    CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.STATUS_TYPES.get(statusType);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return reorder(domainKey, entries, actor);
    }

    @Transactional
    public List<ReferenceRecordDto> reorderEnums(String enumCode, List<ReorderEntry> entries,
                                                 CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return reorder(domainKey, entries, actor);
    }

    @Transactional
    public ReferenceRecordDto createEnum(String enumCode, ReferenceWriteRequest request,
                                         CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return create("ENUM", domainKey, request, actor);
    }

    @Transactional
    public ReferenceRecordDto updateEnum(String enumCode, String code,
                                         ReferenceWriteRequest request, CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return update(domainKey, code, request, actor);
    }

    @Transactional
    public ReferenceRecordDto publishEnum(String enumCode, String code, CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return publish(domainKey, code, actor);
    }

    @Transactional
    public ReferenceRecordDto retireEnum(String enumCode, String code, CurrentUser actor) {
        String domainKey = ReferenceTaxonomy.ENUM_CODES.get(enumCode);
        if (domainKey == null) {
            throw ApiException.notFound();
        }
        return retire(domainKey, code, actor);
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
        audit(actor, "reference.transition.updated", entity, null,
                Map.of("count", safe.size()));
        return transitions(entity, actor);
    }

    private ReferenceRecordDto create(String domainType, String domainKey,
                                      ReferenceWriteRequest request, CurrentUser actor) {
        String code = validateCode(request.code());
        if (repository.find(domainKey, code).isPresent()) {
            throw ApiException.conflict("REFERENCE_EXISTS",
                    "Reference code already exists: " + code);
        }
        WriteValues values = validate(domainKey, request, code, true);
        repository.insert(domainType, domainKey, code, values.labelKey, values.tone,
                values.icon, values.order, values.selectable, jsonArray(values.visibleFor),
                jsonArray(values.allowedNext), "DRAFT");
        audit(actor, action(domainType, "created"), domainKey, code, values.asMap());
        return dto(requireRow(domainKey, code));
    }

    private ReferenceRecordDto update(String domainKey, String code,
                                      ReferenceWriteRequest request, CurrentUser actor) {
        ReferenceRow before = requireRow(domainKey, code);
        if (!blank(request.code()) && !request.code().trim().equals(code)) {
            throw ApiException.unprocessable("CODE_IMMUTABLE",
                    "Reference code is immutable after create");
        }
        if ("RETIRED".equals(before.status())) {
            throw ApiException.conflict("REFERENCE_RETIRED",
                    "Retired reference records cannot be edited");
        }
        WriteValues values = validate(domainKey, request, code, false);
        repository.update(domainKey, code, values.labelKey, values.tone, values.icon,
                values.order, values.selectable, jsonArray(values.visibleFor),
                jsonArray(values.allowedNext));
        audit(actor, "reference." + family(domainKey) + ".updated", domainKey, code,
                values.asMap());
        return dto(requireRow(domainKey, code));
    }

    private ReferenceRecordDto publish(String domainKey, String code, CurrentUser actor) {
        ReferenceRow row = requireRow(domainKey, code);
        if (!"DRAFT".equals(row.status())) {
            throw ApiException.conflict("REFERENCE_STATE_INVALID",
                    "Only DRAFT references can be published");
        }
        repository.updateStatus(domainKey, code, "PUBLISHED");
        audit(actor, "reference." + family(domainKey) + ".published", domainKey, code,
                Map.of("code", code));
        return dto(requireRow(domainKey, code));
    }

    private ReferenceRecordDto retire(String domainKey, String code, CurrentUser actor) {
        ReferenceRow row = requireRow(domainKey, code);
        if (!"PUBLISHED".equals(row.status())) {
            throw ApiException.conflict("REFERENCE_STATE_INVALID",
                    "Only PUBLISHED references can be retired");
        }
        ImpactDto impact = repository.impact(domainKey, code);
        if (impact.items() > 0 || impact.jobs() > 0 || impact.templates() > 0
                || impact.documents() > 0) {
            throw ApiException.conflict("REFERENCE_IN_USE",
                    "Reference is still in use: " + impact.items() + " items, "
                            + impact.jobs() + " jobs, " + impact.templates()
                            + " templates, " + impact.documents() + " documents");
        }
        repository.updateStatus(domainKey, code, "RETIRED");
        audit(actor, "reference." + family(domainKey) + ".retired", domainKey, code,
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
            repository.updateOrder(domainKey, entry.code(), entry.order());
        }
        audit(actor, "reference." + family(domainKey) + ".reordered", domainKey, null,
                Map.of("count", safe.size()));
        String domainType = ReferenceTaxonomy.ENUM_CODES.containsValue(domainKey)
                ? "ENUM" : "STATUS";
        return records(domainType, domainKey, actor, true);
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

    private WriteValues validate(String domainKey, ReferenceWriteRequest request,
                                 String code, boolean creating) {
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

    private List<ReferenceRecordDto> records(String domainType, String domainKey,
                                             CurrentUser caller, boolean includeDraft) {
        if (includeDraft && !caller.isPlatformAdmin()) {
            throw ApiException.forbidden();
        }
        String client = clientName(caller);
        List<ReferenceRecordDto> result = new ArrayList<>();
        for (ReferenceRow row : repository.findDomain(domainType, domainKey, includeDraft)) {
            List<String> visibleFor = strings(row.visibleForJson());
            if (!visibleFor.contains(client)) {
                continue;
            }
            result.add(dto(row));
        }
        return result;
    }

    private ReferenceRecordDto dto(ReferenceRow row) {
        return new ReferenceRecordDto(row.code(), row.labelKey(), row.tone(), row.icon(),
                row.sortOrder(), row.selectable(), strings(row.visibleForJson()),
                strings(row.allowedNextJson()), row.version(), row.status());
    }

    private ReferenceRow requireRow(String domainKey, String code) {
        return repository.find(domainKey, code).orElseThrow(ApiException::notFound);
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

    private String validateCode(String raw) {
        String code = raw == null ? "" : raw.trim();
        if (code.isEmpty() || !code.matches("^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$")) {
            throw ApiException.unprocessable("CODE_INVALID", "Invalid reference code");
        }
        return code;
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
            return Map.of();
        }
        try {
            JsonNode node = objectMapper.readTree(json);
            if (!node.isObject()) {
                return Map.of();
            }
            Map<String, Object> values = new LinkedHashMap<>();
            node.fields().forEachRemaining(entry ->
                    values.put(entry.getKey(), objectMapper.convertValue(entry.getValue(), Object.class)));
            return values;
        } catch (Exception exception) {
            throw new IllegalStateException("Invalid reference taxonomy JSON", exception);
        }
    }

    private String jsonArray(List<String> values) {
        return json(values);
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

    private static String action(String domainType, String suffix) {
        return "reference." + ("STATUS".equals(domainType) ? "status" : "enum") + "." + suffix;
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
