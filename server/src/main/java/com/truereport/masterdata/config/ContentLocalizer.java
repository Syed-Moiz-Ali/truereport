package com.truereport.masterdata.config;

import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.DropdownDto;
import com.truereport.masterdata.api.DropdownValueDto;
import com.truereport.masterdata.api.EquipmentDto;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.api.ItemSummaryDto;
import com.truereport.masterdata.api.ItemVersionDto;
import com.truereport.masterdata.api.PublishedItemDto;
import com.truereport.masterdata.api.ReasonDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueDto;
import com.truereport.shared.i18n.ContentTranslationService;
import com.truereport.shared.i18n.LanguageCatalog;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Applies authored content translations to master-data DTOs. Every method
 * returns the input untouched for the default language, so default-language
 * payloads stay byte-identical.
 */
@Component
public class ContentLocalizer {

    private final ContentTranslationService translations;
    private final LanguageCatalog languages;
    private final JdbcTemplate jdbc;
    private final com.truereport.shared.i18n.TranslationStatusService statusService;

    public ContentLocalizer(ContentTranslationService translations, LanguageCatalog languages,
                            JdbcTemplate jdbc,
                            com.truereport.shared.i18n.TranslationStatusService statusService) {
        this.translations = translations;
        this.languages = languages;
        this.jdbc = jdbc;
        this.statusService = statusService;
    }

    public boolean isDefault(String lang) {
        return languages.normalize(lang).equals(languages.defaultLanguage());
    }

    // ------------------------------------------------------------ categories

    public List<CategoryDto> categories(List<CategoryDto> dtos, String lang) {
        if (dtos.isEmpty()) {
            return dtos;
        }
        Map<String, String> statuses = statusService.rollup("CATEGORY", dtos.stream()
                .map(dto -> dto.id().toString()).toList(), lang);
        if (isDefault(lang) && statuses.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> localized = Map.of();
        if (!isDefault(lang)) {
            Map<String, Map<String, String>> english = new LinkedHashMap<>();
            for (CategoryDto dto : dtos) {
                english.put(dto.id().toString(), Map.of("name", safe(dto.name()),
                        "description", ""));
            }
            localized = translations.resolveMany("CATEGORY", english, lang);
        }
        List<CategoryDto> result = new ArrayList<>(dtos.size());
        for (CategoryDto dto : dtos) {
            Map<String, String> values = localized.getOrDefault(dto.id().toString(), Map.of());
            result.add(new CategoryDto(dto.id(), dto.slug(), dto.status(), dto.sortOrder(),
                    values.getOrDefault("name", safe(dto.name())), dto.itemCount(), dto.code(),
                    dto.active(), dto.translations(), dto.nameEn(), dto.nameAr(),
                    blankToNull(values.get("description")),
                    statuses.get(dto.id().toString())));
        }
        return result;
    }

    // ----------------------------------------------------------------- items

    public List<ItemSummaryDto> items(List<ItemSummaryDto> dtos, String lang) {
        if (dtos.isEmpty()) {
            return dtos;
        }
        Map<String, String> versionByItem = currentVersions(dtos.stream()
                .map(dto -> dto.id().toString()).toList());
        Map<String, String> statuses = statusService.rollup("ITEM",
                versionByItem.values().stream().toList(), lang);
        if (isDefault(lang) && statuses.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> localized = Map.of();
        if (!isDefault(lang)) {
            Map<String, Map<String, String>> english = new LinkedHashMap<>();
            for (ItemSummaryDto dto : dtos) {
                String versionId = versionByItem.get(dto.id().toString());
                if (versionId != null) {
                    english.put(versionId, Map.of("label", safe(dto.label()),
                            "instruction", safe(dto.instruction()),
                            "standardSpec", safe(dto.standardSpec())));
                }
            }
            localized = translations.resolveMany("ITEM", english, lang);
        }
        List<ItemSummaryDto> result = new ArrayList<>(dtos.size());
        for (ItemSummaryDto dto : dtos) {
            String versionId = versionByItem.get(dto.id().toString());
            Map<String, String> values = versionId == null
                    ? Map.of() : localized.getOrDefault(versionId, Map.of());
            result.add(new ItemSummaryDto(dto.id(), dto.stableCode(), dto.categoryId(),
                    dto.categoryLabelEn(), dto.categoryLabelAr(), dto.status(),
                    dto.currentVersion(), values.getOrDefault("label", safe(dto.label())),
                    values.getOrDefault("instruction", safe(dto.instruction())),
                    dto.sampleData(), dto.updatedAt(), dto.measurementUnit(), dto.sensorTool(),
                    values.getOrDefault("standardSpec", safe(dto.standardSpec())),
                    dto.safetyCritical(), dto.multiPoint(), dto.maxTyreAgeYears(),
                    dto.allowFreeTextNote(), dto.sortOrder(), dto.guideImageId(),
                    dto.translations(), dto.labelEn(), dto.labelAr(), dto.standardSpecEn(),
                    dto.standardSpecAr(), versionId == null ? null : statuses.get(versionId)));
        }
        return result;
    }

    public ItemDetailDto itemDetail(ItemDetailDto detail, String lang) {
        if (detail == null) {
            return null;
        }
        ItemSummaryDto item = items(List.of(detail.item()), lang).get(0);
        List<ItemVersionDto> versions = versions(detail.versions(), lang);
        String versionId = currentVersions(List.of(item.id().toString()))
                .get(item.id().toString());
        Map<String, String> fields = versionId == null
                ? Map.of() : statusService.fieldStatuses("ITEM", versionId, lang);
        return new ItemDetailDto(item, versions,
                isDefault(lang) && fields.isEmpty() ? null : fields);
    }

    public List<ItemVersionDto> versions(List<ItemVersionDto> dtos, String lang) {
        if (dtos.isEmpty()) {
            return dtos;
        }
        Map<String, String> statuses = statusService.rollup("ITEM", dtos.stream()
                .map(dto -> dto.id().toString()).toList(), lang);
        if (isDefault(lang) && statuses.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> localized = Map.of();
        if (!isDefault(lang)) {
            Map<String, Map<String, String>> english = new LinkedHashMap<>();
            for (ItemVersionDto dto : dtos) {
                english.put(dto.id().toString(), Map.of("label", safe(dto.label()),
                        "instruction", safe(dto.instruction()),
                        "standardSpec", safe(dto.standardSpec())));
            }
            localized = translations.resolveMany("ITEM", english, lang);
        }
        List<ItemVersionDto> result = new ArrayList<>(dtos.size());
        for (ItemVersionDto dto : dtos) {
            Map<String, String> values =
                    localized.getOrDefault(dto.id().toString(), Map.of());
            result.add(new ItemVersionDto(dto.id(), dto.versionNo(), dto.status(),
                    dto.resultOptions(), dto.severityPolicy(), dto.applicability(),
                    dto.reasonCodes(), dto.noteRequirement(), dto.evidenceRequirement(),
                    dto.minPhotos(), dto.equipmentIds(), dto.guideImageId(), dto.publishedAt(),
                    values.getOrDefault("label", safe(dto.label())),
                    values.getOrDefault("instruction", safe(dto.instruction())),
                    values.getOrDefault("standardSpec", safe(dto.standardSpec())),
                    dto.translations(), dto.labelEn(), dto.labelAr(), dto.instructionEn(),
                    dto.instructionAr(), statuses.get(dto.id().toString())));
        }
        return result;
    }

    public List<PublishedItemDto> publishedItems(List<PublishedItemDto> dtos, String lang) {
        if (isDefault(lang) || dtos.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> english = new LinkedHashMap<>();
        for (PublishedItemDto dto : dtos) {
            english.put(dto.versionId().toString(), Map.of("label", safe(dto.label()),
                    "instruction", safe(dto.instruction())));
        }
        Map<String, Map<String, String>> localized =
                translations.resolveMany("ITEM", english, lang);
        List<PublishedItemDto> result = new ArrayList<>(dtos.size());
        for (PublishedItemDto dto : dtos) {
            Map<String, String> values =
                    localized.getOrDefault(dto.versionId().toString(), Map.of());
            result.add(new PublishedItemDto(dto.itemId(), dto.versionId(), dto.stableCode(),
                    dto.categoryId(), dto.categoryLabelEn(), dto.categoryLabelAr(),
                    values.getOrDefault("label", safe(dto.label())),
                    values.getOrDefault("instruction", safe(dto.instruction())),
                    dto.labelEn(), dto.labelAr(), dto.sampleData(),
                    dto.version() == null ? null
                            : versions(List.of(dto.version()), lang).get(0)));
        }
        return result;
    }

    // ----------------------------------------------------------- option sets

    public List<OptionSetDto> optionSets(List<OptionSetDto> dtos, String lang) {
        if (isDefault(lang) || dtos.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> setEnglish = new LinkedHashMap<>();
        Map<String, Map<String, String>> valueEnglish = new LinkedHashMap<>();
        for (OptionSetDto dto : dtos) {
            setEnglish.put(dto.id(), Map.of("name", safe(dto.name())));
            for (OptionValueDto value : dto.values()) {
                valueEnglish.put(value.id(), Map.of("label", safe(value.label())));
            }
        }
        Map<String, Map<String, String>> sets =
                translations.resolveMany("OPTION_SET", setEnglish, lang);
        Map<String, Map<String, String>> values =
                translations.resolveMany("OPTION_VALUE", valueEnglish, lang);
        List<OptionSetDto> result = new ArrayList<>(dtos.size());
        for (OptionSetDto dto : dtos) {
            result.add(new OptionSetDto(dto.id(), dto.code(),
                    sets.getOrDefault(dto.id(), Map.of()).getOrDefault("name", safe(dto.name())),
                    dto.status(), dto.sortOrder(), dto.setKind(), dto.domainKey(),
                    dto.codeLocked(), dto.valuesCount(),
                    optionValues(dto.values(), lang, values),
                    dto.translations(), dto.nameEn(), dto.nameAr()));
        }
        return result;
    }

    public OptionSetDto optionSet(OptionSetDto dto, String lang) {
        if (dto == null) {
            return null;
        }
        return optionSets(List.of(dto), lang).get(0);
    }

    public List<OptionValueDto> optionValues(List<OptionValueDto> dtos, String lang) {
        if (isDefault(lang) || dtos.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> english = new LinkedHashMap<>();
        for (OptionValueDto dto : dtos) {
            english.put(dto.id(), Map.of("label", safe(dto.label())));
        }
        return optionValues(dtos, lang, translations.resolveMany("OPTION_VALUE", english, lang));
    }

    private List<OptionValueDto> optionValues(List<OptionValueDto> dtos, String lang,
                                              Map<String, Map<String, String>> localized) {
        List<OptionValueDto> result = new ArrayList<>(dtos.size());
        for (OptionValueDto dto : dtos) {
            Map<String, String> values = localized.getOrDefault(dto.id(), Map.of());
            result.add(new OptionValueDto(dto.id(), dto.code(),
                    values.getOrDefault("label", safe(dto.label())), dto.status(),
                    dto.sortOrder(), dto.metadataJson(), dto.translations(), dto.labelEn(),
                    dto.labelAr(), dto.labelKey()));
        }
        return result;
    }

    // ---------------------------------------------------- catalog collections

    public List<ReasonDto> reasons(List<ReasonDto> dtos, String lang) {
        if (isDefault(lang) || dtos.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> english = new LinkedHashMap<>();
        for (ReasonDto dto : dtos) {
            english.put(dto.id().toString(), Map.of("label", safe(dto.labelEn())));
        }
        Map<String, Map<String, String>> localized =
                translations.resolveMany("REASON", english, lang);
        return dtos.stream().map(dto -> {
            Map<String, String> values = localized.getOrDefault(dto.id().toString(), Map.of());
            return new ReasonDto(dto.id(), dto.code(), dto.status(), dto.sortOrder(),
                    dto.labelEn(), dto.labelAr(), blankToNull(values.get("label")));
        }).toList();
    }

    public List<EquipmentDto> equipment(List<EquipmentDto> dtos, String lang) {
        if (isDefault(lang) || dtos.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> english = new LinkedHashMap<>();
        for (EquipmentDto dto : dtos) {
            english.put(dto.id().toString(), Map.of("label", safe(dto.labelEn())));
        }
        Map<String, Map<String, String>> localized =
                translations.resolveMany("EQUIPMENT", english, lang);
        return dtos.stream().map(dto -> {
            Map<String, String> values = localized.getOrDefault(dto.id().toString(), Map.of());
            return new EquipmentDto(dto.id(), dto.code(), dto.status(), dto.sortOrder(),
                    dto.labelEn(), dto.labelAr(), blankToNull(values.get("label")));
        }).toList();
    }

    public List<DropdownDto> dropdowns(List<DropdownDto> dtos, String lang) {
        if (isDefault(lang) || dtos.isEmpty()) {
            return dtos;
        }
        Map<String, Map<String, String>> dropdownEnglish = new LinkedHashMap<>();
        Map<String, Map<String, String>> valueEnglish = new LinkedHashMap<>();
        for (DropdownDto dto : dtos) {
            dropdownEnglish.put(dto.id().toString(), Map.of("label", safe(dto.labelEn())));
            for (DropdownValueDto value : dto.values()) {
                valueEnglish.put(value.id().toString(), Map.of("label", safe(value.labelEn())));
            }
        }
        Map<String, Map<String, String>> dropdowns =
                translations.resolveMany("DROPDOWN", dropdownEnglish, lang);
        Map<String, Map<String, String>> values =
                translations.resolveMany("DROPDOWN_VALUE", valueEnglish, lang);
        return dtos.stream().map(dto -> {
            Map<String, String> setValues =
                    dropdowns.getOrDefault(dto.id().toString(), Map.of());
            List<DropdownValueDto> localizedValues = dto.values().stream().map(value -> {
                Map<String, String> valueValues =
                        values.getOrDefault(value.id().toString(), Map.of());
                return new DropdownValueDto(value.id(), value.code(), value.status(),
                        value.sortOrder(), value.labelEn(), value.labelAr(),
                        blankToNull(valueValues.get("label")));
            }).toList();
            return new DropdownDto(dto.id(), dto.code(), dto.status(), dto.sortOrder(),
                    dto.labelEn(), dto.labelAr(), localizedValues,
                    blankToNull(setValues.get("label")));
        }).toList();
    }

    private Map<String, String> currentVersions(List<String> itemIds) {
        if (itemIds.isEmpty()) {
            return Map.of();
        }
        List<Object> args = new ArrayList<>(itemIds);
        String placeholders = String.join(",",
                java.util.Collections.nCopies(itemIds.size(), "?"));
        Map<String, String> result = new LinkedHashMap<>();
        jdbc.query("""
                SELECT id, current_published_version_id FROM platform_items
                WHERE id IN (%s)
                """.formatted(placeholders), rs -> {
            result.put(rs.getString("id"), rs.getString("current_published_version_id"));
        }, args.toArray());
        return result;
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
