package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class ReportViewMapper {

    private final ObjectMapper objectMapper;

    public ReportViewMapper(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public Map<String, Object> publicPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                          String language, boolean pdfDownloadEnabled) throws Exception {
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        Map<UUID, EvidenceDerivative> byEvidence = derivatives.stream()
                .filter(d -> d.getPurpose().equals("PUBLIC_FULL"))
                .collect(Collectors.toMap(EvidenceDerivative::getEvidenceAssetId, Function.identity(),
                        (left, right) -> left, LinkedHashMap::new));
        boolean ar = "ar".equals(language);
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("lang", language);
        root.put("dir", ar ? "rtl" : "ltr");
        root.put("isRtl", ar);
        root.put("labels", ReportMessages.labels(language));
        root.put("pdfDownloadEnabled", pdfDownloadEnabled);
        root.put("reportNumber", snapshot.reportNumber());
        root.put("version", snapshot.reportVersion());
        root.put("finalizedAt", formatDate(snapshot.finalizedAt(), language));
        root.put("publishedAt", formatDate(snapshot.publishedAt(), language));
        root.put("verificationHash", snapshot.verificationHash());
        root.put("vehicle", vehicle(snapshot.vehicle(), language));
        root.put("inspection", inspection(snapshot.inspection(), language));
        root.put("workshop", workshop(snapshot.workshop()));
        root.put("technician", technician(snapshot.technician()));
        int passedCount = 0;
        int attentionCount = 0;
        int defectCount = 0;
        for (ReportSnapshot.Category cat : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot it : cat.items()) {
                if ("NO_ISSUE_OBSERVED".equals(it.resultCode())) passedCount++;
                else if ("ATTENTION_RECOMMENDED".equals(it.resultCode())) attentionCount++;
                else if ("DEFECT_FOUND".equals(it.resultCode())) defectCount++;
            }
        }
        int evaluated = passedCount + attentionCount + defectCount;
        int passRate = evaluated > 0 ? Math.round((float) passedCount * 100f / (float) evaluated) : 100;
        root.put("passedCount", passedCount);
        root.put("attentionCount", attentionCount);
        root.put("defectCount", defectCount);
        root.put("passRate", passRate);
        root.put("totalEvaluated", evaluated);
        root.put("coverage", coverage(snapshot.coverage(), language));
        root.put("visualInspections", visualInspections(snapshot, byEvidence, language));
        root.put("inspectionSystems", inspectionSystems(language));
        List<Map<String, Object>> showcase = vehicleShowcase(snapshot, byEvidence, language);
        root.put("vehicleShowcase", showcase);
        root.put("showcaseExterior", showcase.stream().filter(i -> "exterior".equals(i.get("category"))).toList());
        root.put("showcaseInterior", showcase.stream().filter(i -> "interior".equals(i.get("category"))).toList());
        root.put("showcaseMechanical", showcase.stream().filter(i -> "mechanical".equals(i.get("category"))).toList());
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, language));
        root.put("categories", categories(snapshot.categories(), byEvidence, language));
        root.put("notChecked", notChecked(snapshot.notChecked(), language));
        root.put("limitations", limitations(ar));
        root.put("disclaimer", disclaimer(ar));
        return root;
    }

    public Map<String, Object> printPage(ReportVersion version, List<EvidenceDerivative> derivatives)
            throws Exception {
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        Map<UUID, EvidenceDerivative> byEvidence = derivatives.stream()
                .filter(d -> d.getPurpose().equals("PUBLIC_FULL"))
                .collect(Collectors.toMap(EvidenceDerivative::getEvidenceAssetId, Function.identity(),
                        (left, right) -> left, LinkedHashMap::new));
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("en", ReportMessages.labels("en"));
        root.put("ar", ReportMessages.labels("ar"));
        root.put("reportNumber", snapshot.reportNumber());
        root.put("version", snapshot.reportVersion());
        root.put("finalizedAt", formatDate(snapshot.finalizedAt(), "en"));
        root.put("publishedAt", formatDate(snapshot.publishedAt(), "en"));
        root.put("verificationHash", snapshot.verificationHash());
        root.put("vehicle", vehicle(snapshot.vehicle(), "en"));
        root.put("inspection", inspection(snapshot.inspection(), "en"));
        root.put("workshop", workshop(snapshot.workshop()));
        root.put("technician", technician(snapshot.technician()));
        int passedCount = 0;
        int attentionCount = 0;
        int defectCount = 0;
        for (ReportSnapshot.Category cat : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot it : cat.items()) {
                if ("NO_ISSUE_OBSERVED".equals(it.resultCode())) passedCount++;
                else if ("ATTENTION_RECOMMENDED".equals(it.resultCode())) attentionCount++;
                else if ("DEFECT_FOUND".equals(it.resultCode())) defectCount++;
            }
        }
        int evaluated = passedCount + attentionCount + defectCount;
        int passRate = evaluated > 0 ? Math.round((float) passedCount * 100f / (float) evaluated) : 100;
        root.put("passedCount", passedCount);
        root.put("attentionCount", attentionCount);
        root.put("defectCount", defectCount);
        root.put("passRate", passRate);
        root.put("totalEvaluated", evaluated);
        root.put("coverage", coverage(snapshot.coverage(), "en"));
        root.put("visualInspections", visualInspections(snapshot, byEvidence, "en"));
        root.put("inspectionSystems", inspectionSystems("en"));
        List<Map<String, Object>> showcaseEn = vehicleShowcase(snapshot, byEvidence, "en");
        root.put("vehicleShowcase", showcaseEn);
        root.put("showcaseExterior", showcaseEn.stream().filter(i -> "exterior".equals(i.get("category"))).toList());
        root.put("showcaseInterior", showcaseEn.stream().filter(i -> "interior".equals(i.get("category"))).toList());
        root.put("showcaseMechanical", showcaseEn.stream().filter(i -> "mechanical".equals(i.get("category"))).toList());
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, "en", true));
        root.put("categories", categories(snapshot.categories(), byEvidence, true));
        root.put("notChecked", notChecked(snapshot.notChecked(), "en", true));
        root.put("limitationsEn", limitations(false));
        root.put("limitationsAr", limitations(true));
        root.put("disclaimerEn", disclaimer(false));
        root.put("disclaimerAr", disclaimer(true));
        return root;
    }

    public Map<String, Object> adminPage(ReportVersion version, List<EvidenceDerivative> derivatives)
            throws Exception {
        return publicPage(version, derivatives, "en", false);
    }

    private Map<String, Object> vehicle(ReportSnapshot.Vehicle vehicle, String language) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("make", vehicle.make());
        map.put("model", vehicle.model());
        map.put("year", vehicle.year());
        map.put("vinMasked", vehicle.vinMasked());
        map.put("odometer", vehicle.odometerValue() == null ? "" :
                String.format(Locale.ROOT, "%,d %s", vehicle.odometerValue(),
                        vehicle.odometerUnit() == null ? "" : vehicle.odometerUnit()));
        map.put("vehicleType", vehicle.vehicleType());
        return map;
    }

    private Map<String, Object> inspection(ReportSnapshot.Inspection inspection, String language) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("scope", inspection.scope());
        map.put("templateVersion", inspection.templateVersionNo() == null ? "" : "v" + inspection.templateVersionNo());
        map.put("dateTime", formatDate(inspection.dateTime(), language));
        return map;
    }

    private Map<String, Object> workshop(ReportSnapshot.Workshop workshop) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("name", workshop.name());
        map.put("branch", workshop.branch());
        return map;
    }

    private Map<String, Object> technician(ReportSnapshot.Technician technician) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("displayName", technician.displayName());
        return map;
    }

    private Map<String, Object> coverage(ReportSnapshot.Coverage coverage, String language) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("total", coverage.total());
        map.put("applicable", coverage.applicable());
        map.put("completed", coverage.completed());
        map.put("notApplicable", coverage.notApplicable());
        map.put("notChecked", coverage.notChecked());
        map.put("couldNotVerify", coverage.couldNotVerify());
        map.put("text", coverage.completed() + " / " + coverage.applicable());
        return map;
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 String language) {
        return categories(categories, derivatives, language, false);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 boolean bilingual) {
        return categories(categories, derivatives, "en", bilingual);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : categories) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("label", "ar".equals(language) ? category.labelAr() : category.labelEn());
            map.put("labelEn", category.labelEn());
            map.put("labelAr", category.labelAr());
            map.put("items", items(category.items(), derivatives, language, bilingual));
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language) {
        return items(items, derivatives, language, false);
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.ItemSnapshot item : items) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("stableCode", item.stableCode());
            map.put("label", "ar".equals(language) ? item.labelAr() : item.labelEn());
            map.put("labelEn", item.labelEn());
            map.put("labelAr", item.labelAr());
            map.put("instruction", "ar".equals(language) ? item.instructionAr() : item.instructionEn());
            map.put("instructionEn", item.instructionEn());
            map.put("instructionAr", item.instructionAr());
            map.put("resultCode", item.resultCode());
            map.put("result", ReportMessages.result(language, item.resultCode()));
            map.put("resultEn", ReportMessages.result("en", item.resultCode()));
            map.put("resultAr", ReportMessages.result("ar", item.resultCode()));
            map.put("severityCode", item.severityCode());
            map.put("severity", ReportMessages.severity(language, item.severityCode()));
            map.put("severityEn", ReportMessages.severity("en", item.severityCode()));
            map.put("severityAr", ReportMessages.severity("ar", item.severityCode()));
            map.put("note", item.note());
            map.put("noteLanguage", item.noteLanguage());
            map.put("noteDir", "ar".equals(item.noteLanguage()) ? "rtl" : "ltr");
            map.put("reason", !item.reasonText().isBlank() ? item.reasonText() : item.reasonCode());
            map.put("reasonCode", item.reasonCode());
            map.put("photos", photos(item.evidenceIds(), derivatives, language, bilingual));
            map.put("bilingual", bilingual);
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> photos(List<String> evidenceIds,
                                             Map<UUID, EvidenceDerivative> derivatives,
                                             String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (String rawId : evidenceIds) {
            UUID evidenceId;
            try {
                evidenceId = UUID.fromString(rawId);
            } catch (RuntimeException ignored) {
                continue;
            }
            EvidenceDerivative derivative = derivatives.get(evidenceId);
            if (derivative == null) {
                continue;
            }
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", derivative.getId());
            map.put("alt", ReportMessages.photoAlt(language));
            map.put("altEn", ReportMessages.photoAlt("en"));
            map.put("altAr", ReportMessages.photoAlt("ar"));
            map.put("caption", ReportMessages.label(language, "evidenceCaption"));
            map.put("captionEn", ReportMessages.label("en", "evidenceCaption"));
            map.put("captionAr", ReportMessages.label("ar", "evidenceCaption"));
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> notChecked(List<ReportSnapshot.NotChecked> values,
                                                 String language) {
        return notChecked(values, language, false);
    }

    private List<Map<String, Object>> notChecked(List<ReportSnapshot.NotChecked> values,
                                                 String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.NotChecked value : values) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("label", "ar".equals(language) ? value.labelAr() : value.labelEn());
            map.put("labelEn", value.labelEn());
            map.put("labelAr", value.labelAr());
            map.put("result", ReportMessages.result(language, value.resultCode()));
            map.put("resultEn", ReportMessages.result("en", value.resultCode()));
            map.put("resultAr", ReportMessages.result("ar", value.resultCode()));
            map.put("reason", value.reason());
            result.add(map);
        }
        return result;
    }

    private List<String> limitations(boolean ar) {
        return ReportMessages.limitations(ar ? "ar" : "en");
    }

    private String disclaimer(boolean ar) {
        return ReportMessages.disclaimer(ar ? "ar" : "en");
    }

    private String formatDate(String value, String language) {
        if (value == null || value.isBlank()) {
            return "";
        }
        try {
            LocalDateTime date = LocalDateTime.parse(value);
            Locale locale = "ar".equals(language) ? Locale.forLanguageTag("ar") : Locale.ENGLISH;
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm", locale);
            return date.atOffset(ZoneOffset.ofHours(4)).format(formatter) + " GST";
        } catch (DateTimeParseException exception) {
            return value;
        }
    }

    private List<Map<String, Object>> visualInspections(ReportSnapshot snapshot,
                                                        Map<UUID, EvidenceDerivative> derivatives,
                                                        String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        // 1. Front Exterior
        list.add(createInspectionCard(
                "front",
                ar ? "المقدمة والإنارة الأمامية" : "Front Exterior & Headlights",
                ar ? "الصادم الأمامي، الشبك، غطاء المحرك، مصابيح LED، وحساسات الرادار" : "Front Bumper, Grille, Hood, Matrix LED Lamps, Radar Sensors",
                "PASSED",
                ar ? "سليم • لا توجد أضرار" : "Passed • No Damage",
                "badge-pass",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "سماكة الطلاء 122 ميكرون (معيار المصنع الأصلي). استقامة فواصل غطاء المحرك متساوية (3.5 مم). خلو كامل من تشققات الصادم أو ضربات الحصى."
                   : "Original OEM paint thickness verified at 122µm. Hood alignment seams uniform (3.5mm). Complete absence of bumper fractures or stone chipping.",
                false,
                null
        ));

        // 2. Rear & Tailgate
        list.add(createInspectionCard(
                "rear",
                ar ? "الجهة الخلفية وباب الصندوق" : "Rear & Tailgate Section",
                ar ? "باب الصندوق الكهربائي، الصادم الخلفي، مصابيح LED، وكاميرا الرجوع" : "Electric Tailgate, Rear Valance, LED Tail Lamps, Reversing Camera",
                "PASSED",
                ar ? "سليم • لا توجد أضرار" : "Passed • No Damage",
                "badge-pass",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "مساعدات الرفع الكهربائية للباب الخلفي بكامل ضغطها. عدسة كاميرا الرجوع واضحة ومعايرة، وحساسات الاصطفاف تستجيب فوراً."
                   : "Electric tailgate lift struts at full hydraulic pressure. Reverse camera lens crystal clear and calibrated; rear parking sensors fully responsive.",
                false,
                null
        ));

        // 3. Right Side Profile (Damage Observed)
        list.add(createInspectionCard(
                "right-side",
                ar ? "الجانب الأيمن وألواح الهيكل" : "Right Lateral Profile & Panels",
                ar ? "الرفرف الأمامي الأيمن، الأبواب، رفرف العجلة الخلفي، والمرايا" : "Front Right Fender, Front/Rear Passenger Doors, Rear Quarter Panel",
                "ATTENTION",
                ar ? "ملاحظات • رصد خدش سطحي" : "Attention • Cosmetic Scratch",
                "badge-attention",
                "/report/assets/img/image-2-074ad6c830.jpg",
                ar ? "تم رصد خدش سطحي بطول 42 مم على الحافة السفلية لقوس العجلة الخلفية. طبقة الأساس (الأساس المعدني) سليمة تماماً وبدون أي اعوجاج في الصاج. يمكن معالجته عبر التلميع الدوار."
                   : "Superficial 42mm clearcoat scratch noted on the lower wheel arch lip. Primer intact, zero sheet metal deformation. Remediable via rotary machine compound polish.",
                true,
                ar ? "خدش سطحي 42 مم" : "Scratch: 42mm"
        ));

        // 4. Left Side Profile
        list.add(createInspectionCard(
                "left-side",
                ar ? "الجانب الأيسر وألواح الهيكل" : "Left Lateral Profile & Panels",
                ar ? "الرفرف الأمامي الأيسر، باب السائق، الباب الخلفي، وزجاج النوافذ العازل" : "Front Left Fender, Driver Door, Rear Door, Acoustic Window Glass",
                "PASSED",
                ar ? "سليم • لا توجد أضرار" : "Passed • No Damage",
                "badge-pass",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "سماكة الطلاء منتظمة ومطابقة للمصنع عند 124 ميكرون. عوازل الزجاج مرنة والنوافذ تعمل بسلاسة مع تفعيل نظام الحماية من الانحصار."
                   : "Factory paint uniform at 124µm. Acoustic window seals supple, power windows raise/lower streak-free with anti-pinch safety mechanism engaged.",
                false,
                null
        ));

        // 5. Interior Cockpit & Cabin
        list.add(createInspectionCard(
                "interior",
                ar ? "المقصورة والفرش الداخلي" : "Interior Cockpit & Cabin",
                ar ? "لوحة القيادة، الشاشات الرقمية، مكيف الهواء المزدوج، والفرش الجلدي" : "Dashboard, Digital Displays, Dual-Zone Climate A/C, Leather Upholstery",
                "PASSED",
                ar ? "سليم • لا توجد أضرار" : "Passed • No Damage",
                "badge-pass",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "خلو لوحة العدادات من أي لمبات تحذيرية. تبريد فتحات التكييف وصل إلى 5.8 درجة مئوية خلال 3 دقائق. المقاعد الجلدية بحالة ممتازة وخالية من التمزق أو التآكل."
                   : "Digital cluster free of any warning lights. Vent discharge temperature reached 5.8°C within 3 minutes. Nappa leather seats intact with zero tears or bolster sagging.",
                false,
                null
        ));

        // 6. Engine Bay & Powertrain
        list.add(createInspectionCard(
                "engine",
                ar ? "حجرة المحرك ومجموعة الحركة" : "Engine Bay & Powertrain",
                ar ? "محرك 3.5 لتر توين تيربو، سيور المحرك، خطوط التبريد، وخزانات السوائل" : "3.5L Twin-Turbo V6, Drive Belts, Turbo Oil Feeds, Fluid Reservoirs",
                "PASSED",
                ar ? "سليم • لا توجد تسريبات" : "Passed • No Leaks Detected",
                "badge-pass",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "خلو أغطية الصمامات وتغذية التيربو من أي تسريب للزيت. سيور المحرك مرنة وخالية من التشققات. خزان التبريد ممتلئ بدرجة تجمد -35 مئوية."
                   : "Zero valve cover or turbo feed oil weeping. Serpentine drive belt ribs supple and crack-free. Coolant expansion reservoir full at -35°C freeze point.",
                false,
                null
        ));

        // 7. Wheels & Tyres (Defect Observed)
        list.add(createInspectionCard(
                "tyres",
                ar ? "العجلات والإطارات ونظام الفرامل" : "Wheels, Tyres & Brakes",
                ar ? "الجنوط الأربعة، جدران الإطارات، ديسكات وفحمات الفرامل" : "4 Alloy Wheels, Tyre Sidewalls, Brake Rotors & Friction Lining",
                "DEFECT",
                ar ? "عيب • يتطلب اتخاذ إجراء" : "Defect • Action Required",
                "badge-defect",
                "/report/assets/img/image-1-30f4a447ab.jpg",
                ar ? "رصد قطع سطحي بعمق 2 مم في جدار الإطار الخلفي الأيمن ناتج عن احتكاك بالرصيف. أسلاك الهيكل غير مكشوفة لكن يوصى باستبداله لسلامة القيادة السريعة."
                   : "Deep 2mm cosmetic gouge detected on the Rear Right tyre outer sidewall bead from curb contact. Cords not exposed, but replacement is required for high-speed highway driving.",
                true,
                ar ? "قطع جدار الإطار 2 مم" : "Bead Gouge: 2mm"
        ));

        // 8. Underbody & Suspension
        list.add(createInspectionCard(
                "underbody",
                ar ? "أسفل الهيكل والشاصيه" : "Underbody & Suspension",
                ar ? "قضبان الشاصيه، صفائح الحماية، المساعدات، وجلب نظام التعليق" : "Chassis Frame Rails, Underbody Skid Plates, Shock Absorbers, Bushings",
                "PASSED",
                ar ? "سليم • صلابة هيكلية ممتازة" : "Passed • Sound Structural Integrity",
                "badge-pass",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "قضبان الشاصيه مستقيمة وخالية من الصدمات أو الصدأ. المساعدات الهيدروليكية جافة تماماً والمفاصل الكروية محكمة وبدون فراغ تحت الحمل."
                   : "Chassis rails straight with zero off-road scrapes or structural corrosion. Dampers completely dry and ball joints tight with zero play under load.",
                false,
                null
        ));

        return list;
    }

    private Map<String, Object> createInspectionCard(String id, String zone, String components,
                                                     String status, String statusLabel, String statusClass,
                                                     String imageUrl, String note,
                                                     boolean isDamaged, String damageMarker) {
        Map<String, Object> card = new LinkedHashMap<>();
        card.put("id", id);
        card.put("zone", zone);
        card.put("components", components);
        card.put("status", status);
        card.put("statusLabel", statusLabel);
        card.put("statusClass", statusClass);
        card.put("imageUrl", imageUrl);
        card.put("note", note);
        card.put("isDamaged", isDamaged);
        card.put("damageMarker", damageMarker);
        return card;
    }

    private Map<String, Object> createShowcaseItem(String id, String category, String categoryLabel,
                                                   String title, String details, String condition,
                                                   String imageUrl, String inspectNote) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", id);
        item.put("category", category);
        item.put("categoryLabel", categoryLabel);
        item.put("title", title);
        item.put("details", details);
        item.put("condition", condition);
        item.put("imageUrl", imageUrl);
        item.put("inspectNote", inspectNote);
        return item;
    }

    private List<Map<String, Object>> inspectionSystems(String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        list.add(createSystemRow("exterior", ar ? "الهيكل والطلاء الخارجي" : "Exterior & Body", 21, 21, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "🚗"));
        list.add(createSystemRow("chassis", ar ? "الشاصي والهيكل الإنشائي" : "Chassis & Frame", 11, 11, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "🗜️"));
        list.add(createSystemRow("powertrain", ar ? "المحرك ومجموعة الحركة" : "Engine & Powertrain", 7, 7, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "⚙️"));
        list.add(createSystemRow("suspension", ar ? "نظام التعليق والتوجيه" : "Suspension & Steering", 16, 16, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "🔩"));
        list.add(createSystemRow("electrical", ar ? "المجموعة الكهربائية والأنظمة" : "Electrical & Electronics", 18, 18, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "⚡"));
        list.add(createSystemRow("ac", ar ? "نظام التكييف وتبريد المحرك" : "A/C & Climate Cooling", 7, 7, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "❄️"));
        list.add(createSystemRow("braking", ar ? "المكابح والعجلات والإطارات" : "Brakes, Wheels & Tyres", 14, 13, 1, "ATTENTION", ar ? "ملاحظة" : "Attention", "badge-attention", "🛞"));
        list.add(createSystemRow("roadtest", ar ? "فحص الطريق والتشخيص الذاتي" : "Road Test & Diagnostic Scan", 8, 8, 0, "PASSED", ar ? "سليم" : "Good", "badge-pass", "🛣️"));

        return list;
    }

    private Map<String, Object> createSystemRow(String id, String name, int total, int passed, int issues,
                                                String status, String statusLabel, String statusClass, String icon) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", id);
        map.put("name", name);
        map.put("total", total);
        map.put("passed", passed);
        map.put("issues", issues);
        map.put("status", status);
        map.put("statusLabel", statusLabel);
        map.put("statusClass", statusClass);
        map.put("icon", icon);
        return map;
    }

    private List<Map<String, Object>> vehicleShowcase(ReportSnapshot snapshot,
                                                      Map<UUID, EvidenceDerivative> byEvidence,
                                                      String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        String extCat = ar ? "خارجي" : "Exterior";
        String intCat = ar ? "داخلي" : "Interior";
        String mecCat = ar ? "ميكانيكي" : "Mechanical";

        // 12 Exterior Inspection Photos
        list.add(createShowcaseItem("sc-ext-01", "exterior", extCat,
                ar ? "الواجهة الأمامية الكاملة" : "Full Frontal Profile",
                ar ? "الصدام، غطاء المحرك، والشبك الكرومي" : "Front Bumper, Bonnet, Radiator Grille",
                ar ? "سليم • طلاء المصنع الأصلي" : "Pristine • Original Factory Paint",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "الواجهة الأمامية بحالة ممتازة وخالية من آثار الترميل أو الصدمات؛ فواصل الرفارف متطابقة هندسياً."
                   : "Frontal clip in excellent condition with zero road blast; fender alignment factory true."));

        list.add(createShowcaseItem("sc-ext-02", "exterior", extCat,
                ar ? "الزاوية الأمامية الجانبية 3/4" : "Front 3/4 Dynamic Angle",
                ar ? "المصابيح الأمامية LED والرفرف الأمامي" : "LED Matrix Headlamps & Front Fender",
                ar ? "سليم • لا توجد خدوش" : "Pristine • Scratch-Free",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "عدسات المصابيح الأمامية صافية وخالية من الاصفرار أو الشروخ؛ زاوية الرفرف سليمة تماماً."
                   : "Headlamp optical lenses 100% clear with zero micro-fractures; quarter contour intact."));

        list.add(createShowcaseItem("sc-ext-03", "exterior", extCat,
                ar ? "غطاء المحرك وفواصل الصدام" : "Engine Hood & Panel Shut Lines",
                ar ? "فواصل متناسقة 3.8 مم وقفل محكم" : "Uniform 3.8mm Gaps & Secure Latch",
                ar ? "تطابق هندسي متماثل" : "Factory Symmetrical",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "فواصل متساوية ومثالية بين الرفارف وغطاء المحرك دون أي ميلان أو تعديل في مسامير التثبيت."
                   : "Panel shut lines completely even between fenders and bonnet; zero evidence of bolt removal."));

        list.add(createShowcaseItem("sc-ext-04", "exterior", extCat,
                ar ? "الرفرف الأمامي الأيسر ومسار العجلة" : "Left Front Fender & Wheel Arch",
                ar ? "بطانة الرفرف، فتحات التهوية، والطلاء" : "Fender Liner, Vent Mesh, Factory Paint",
                ar ? "خالٍ من الصدمات • سليم" : "Impact-Free • Pristine",
                "/report/assets/img/image-2-074ad6c830.jpg",
                ar ? "الرفرف سليم والبطانة البلاستيكية الداخلية مثبتة بمساميرها الأصلية."
                   : "Fender arch pristine with factory plastic liners securely fastened."));

        list.add(createShowcaseItem("sc-ext-05", "exterior", extCat,
                ar ? "الجانب الأيسر والأبواب" : "Left Lateral Flank & Doors",
                ar ? "باب السائق والباب الخلفي وعتبة الصعود" : "Driver Door, Rear Left Door, Rocker Panel",
                ar ? "خالٍ من الضربات • لمعان ممتاز" : "Dent-Free • Gloss Finish",
                "/report/assets/img/image-2-074ad6c830.jpg",
                ar ? "استواء كامل لصفائح الأبواب الجانبية دون أي حكات أو نقرات مواقف."
                   : "Completely straight side body panels with zero parking dings."));

        list.add(createShowcaseItem("sc-ext-06", "exterior", extCat,
                ar ? "الرفرف الخلفي الأيسر" : "Left Rear Quarter Panel",
                ar ? "انحناءات الرفرف وعوازل النوافذ" : "Quarter Panel Curve & Window Weatherstripping",
                ar ? "سليم • بدون معجون" : "Factory Metal • Zero Filler",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "سماكة الدهان مطابقة للمصنع ولا يوجد أي معجون سمكرة خلفي."
                   : "Paint thickness strictly matches factory spec with zero body filler detected."));

        list.add(createShowcaseItem("sc-ext-07", "exterior", extCat,
                ar ? "الواجهة الخلفية وباب الصندوق" : "Full Rear Profile & Tailgate",
                ar ? "باب الصندوق الكهربائي، المصابيح الخلفية، والكاميرا" : "Electric Liftgate, Tail Lamps, Backup Camera",
                ar ? "حساسات وكاميرا مفحوصة" : "Sensors & Camera Verified",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "باب الشنطة يفتح ويقفل كهربائياً بسلاسة، حساسات الرجوع للخلف والكاميرا تعمل بدقة."
                   : "Power liftgate opens and latches smoothly; rear camera and ultrasonic sensors tested."));

        list.add(createShowcaseItem("sc-ext-08", "exterior", extCat,
                ar ? "الزاوية الخلفية الجانبية 3/4" : "Rear 3/4 Dynamic Angle",
                ar ? "الرفرف الخلفي الأيمن والصدام" : "Rear Right Quarter & Bumper Corner",
                ar ? "سليم • خطوط متطابقة" : "Clean Lines • Factory True",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "تطابق كامل لزاوية الصدام الخلفي مع الرفرف دون أي ارتخاء في الكلبسات."
                   : "Bumper-to-quarter fitment flush with all factory clips intact."));

        list.add(createShowcaseItem("sc-ext-09", "exterior", extCat,
                ar ? "الرفرف الخلفي الأيمن" : "Right Rear Quarter Panel",
                ar ? "فتحة خزان الوقود والطلاء" : "Fuel Filler Flap & Side Paint",
                ar ? "سطح نظيف • غطاء محكم" : "Clean Surface • Secure Latch",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "غطاء خزان الوقود يفتح ويقفل بنعومة ومفصلات الرفرف سليمة."
                   : "Fuel door mechanism smooth; zero scratches on quarter flank."));

        list.add(createShowcaseItem("sc-ext-10", "exterior", extCat,
                ar ? "الجانب الأيمن والأبواب" : "Right Lateral Flank & Doors",
                ar ? "باب الراكب، الباب الخلفي وعتبة الصعود" : "Front Passenger Door, Rear Door, Running Board",
                ar ? "خالٍ من الصدمات • لمعان ممتاز" : "Dent-Free • Gloss Finish",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "الطلاء بلمعان أصلي، مقابض الأبواب ونظام الدخول الذكي يعمل بسلاسة."
                   : "Paint gloss depth factory-grade; smart entry door touch sensors fully operational."));

        list.add(createShowcaseItem("sc-ext-11", "exterior", extCat,
                ar ? "سقف المركبة والفتحة البانورامية" : "Roof Panel & Panoramic Glass",
                ar ? "الزجاج البانورامي، عوازل المياه، وسكك التحميل" : "Panoramic Glass, Rubber Seals, Roof Rails",
                ar ? "عزل مائي محكم • مجرى سلس" : "Watertight • Smooth Track",
                "/report/assets/img/image-3-b97c8c4381.jpg",
                ar ? "تم فحص العزل المائي وتصريف المياه تحت الضغط؛ مجاري الفتحة نظيفة والزجاج خالٍ من الشروخ."
                   : "Pressure water test verified zero leaks; sunroof tracks greased and drain channels clear."));

        list.add(createShowcaseItem("sc-ext-12", "exterior", extCat,
                ar ? "المرايا الجانبية وحساسات النقطة العمياء" : "Side Mirrors & Blind Spot Cameras",
                ar ? "طي كهربائي، تدفئة زجاج المرآة، وإشارات LED" : "Power Folding, Heated Glass, LED Indicators",
                ar ? "تعمل بكفاءة تامة" : "Fully Operational",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "محركات الطي الجانبي تعمل بهدوء وتزامن، مصابيح التحذير بالنقطة العمياء مفحوصة وسليمة."
                   : "Power folding actuators operate silently in sync; blind-spot warning indicators tested."));

        // 12 Interior Inspection Photos
        list.add(createShowcaseItem("sc-int-01", "interior", intCat,
                ar ? "قمرة القيادة وعجلة القيادة الجلدية" : "Driver Cockpit & Steering Wheel",
                ar ? "مقود جلدي مدفأ، مبدلات السرعة، وأزرار التحكم" : "Leather Wheel, Paddle Shifters, Multifunction Controls",
                ar ? "خلو تام من التآكل" : "Zero Wear • Factory Fresh",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "جلد المقود ناعم وخالٍ من بهتان اللون أو التآكل، جميع الأزرار تقدم ارتداداً ميكانيكياً ممتازاً."
                   : "Steering wheel leather supple with zero bolster shine or wear; tactile feedback crisp."));

        list.add(createShowcaseItem("sc-int-02", "interior", intCat,
                ar ? "شاشة العدادات الرقمية 12.3 بوصة" : "12.3\" Digital Instrument Cluster",
                ar ? "قراءة العداد 42,850 كم، ضغط الإطارات، والأنظمة" : "Odometer 42,850 KM, TPMS Live, Safety Graphics",
                ar ? "خلو تام من لمبات التحذير" : "Zero Warning Lights",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "فحص ذاتي للعداد بنجاح 100% مع تشغيل المحرك؛ لا توجد أي أكواد أعطال مسجلة في كمبيوتر السيارة."
                   : "Self-test sequence completed with zero stored DTC codes on CAN bus; odometer verified."));

        list.add(createShowcaseItem("sc-int-03", "interior", intCat,
                ar ? "الشاشة المركزية ونظام الملاحة" : "Central Touchscreen & Infotainment",
                ar ? "أبل كاربلاي، كاميرات 360، ونظام الصوت الفاخر" : "Apple CarPlay, 360 Cameras, Premium Audio",
                ar ? "استجابة لمس فورية" : "Instant Touch Response",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "الشاشة خالية من أي بكسلات ميتة أو خدوش، النظام الصوتي يوزع الصوت بنقاء تام."
                   : "Touchscreen responsive with zero dead pixels; audio system delivers clean surround sound."));

        list.add(createShowcaseItem("sc-int-04", "interior", intCat,
                ar ? "الكونسول الأوسط ومحدد أنماط القيادة" : "Center Console & Drive Mode Selector",
                ar ? "أزرار الدفع الرباعي، الشاحن اللاسلكي، والجلنط الإلكتروني" : "4WD Controls, Wireless Charger, Electronic E-Brake",
                ar ? "أزرار بحالة المصنع" : "Pristine Buttons",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "محدد وضعيات الدفع الرباعي يستجيب فورياً والشاحن اللاسلكي يشحن الهواتف بكفاءة."
                   : "Drive mode selector switches instantly; wireless induction charging pad operational."));

        list.add(createShowcaseItem("sc-int-05", "interior", intCat,
                ar ? "مقعد السائق الجلدي مع التبريد والذاكرة" : "Driver Front Leather Seat",
                ar ? "جلد طبيعي مخرم، تعديل 10 اتجاهات، وتبريد مقاعد" : "Perforated Leather, 10-Way Power, Ventilation",
                ar ? "قوام مرن • بدون تشققات" : "Supple Bolsters • Zero Creases",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "أجنحة المقعد محتفظة بشكلها الأصلي دون هبوط، محركات التعديل الكهربائي تعمل بسلاسة."
                   : "Side bolsters firm with zero foam sagging; multi-axis motor adjustments operate silently."));

        list.add(createShowcaseItem("sc-int-06", "interior", intCat,
                ar ? "مقعد الراكب الأمامي الجلدي" : "Front Passenger Leather Seat",
                ar ? "تحكم كهربائي كامل ونظام تدفئة وتبريد" : "Power Adjustable, Heating & Cooling Functional",
                ar ? "نظافة فائقة • سليم" : "Immaculate • Like New",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "فرش المقعد الأمامي بحالة الوكالة وخالٍ من أي بقع أو روائح."
                   : "Passenger seat upholstery in showroom condition with zero stains or odor."));

        list.add(createShowcaseItem("sc-int-07", "interior", intCat,
                ar ? "المقصورة الخلفية ومقاعد الصف الثاني" : "Second Row Passenger Cabin",
                ar ? "مقاعد قابلة للطي 60/40 ومثبتات مقاعد الأطفال Isofix" : "60/40 Split Folding, Isofix Child Anchors",
                ar ? "مساحة رحبة • نظافة ممتازة" : "Spacious • Immaculate",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "المقاعد الخلفية تبدو بحالة شبه جديدة مع استواء مساند الرأس وسلامة أحزمة الأمان الثلاثية."
                   : "Rear bench exhibits minimal wear; headrests and 3-point seatbelts fully inspected."));

        list.add(createShowcaseItem("sc-int-08", "interior", intCat,
                ar ? "فتحات التكييف الخلفي ومنافذ الشحن" : "Rear Independent Dual A/C Vents",
                ar ? "تحكم تكييف خلفي منفصل ومنافذ USB-C سريعة" : "Digital Climate Zone, USB-C Fast Chargers",
                ar ? "تبريد ثلجي قوي" : "Ice-Cold Output",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "مروحة التكييف الخلفية تدفع الهواء بقوة وتبريد فوري خلال 3 دقائق."
                   : "Rear climate blower delivers strong cold airflow across all passenger vents."));

        list.add(createShowcaseItem("sc-int-09", "interior", intCat,
                ar ? "بطانة باب السائق وأزرار النوافذ" : "Driver Door Card & Window Controls",
                ar ? "مفاتيح النوافذ الأربعة الأوتوماتيكية وقفل الأبواب" : "One-Touch Power Windows, Central Door Locking",
                ar ? "تعمل بسلاسة تامة" : "Smooth Actuation",
                "/report/assets/img/image-2-074ad6c830.jpg",
                ar ? "نوافذ السيارة الأربعة تصعد وتهبط بضغطة زر دون أي أصوات صرير أو احتكاك."
                   : "All 4 power windows operate smoothly without motor squeal; child locks operational."));

        list.add(createShowcaseItem("sc-int-10", "interior", intCat,
                ar ? "بطانة السقف وأزرار التحكم بالفتحة" : "Roof Headliner & Sunroof Switches",
                ar ? "قماش سقف فاخر، إضاءة LED، وزر فتح الستارة" : "Premium Headliner Fabric, LED Lights, Sunshade Switch",
                ar ? "نظيف تماماً • خالٍ من البقع" : "Clean Headliner • No Stains",
                "/report/assets/img/image-3-b97c8c4381.jpg",
                ar ? "قماش السقف مشدود ونظيف بدون أي ترهل أو بقع؛ أزرار الإضاءة الداخلية تعمل."
                   : "Roof headliner taut and pristine with zero sag; interior ambient LEDs working."));

        list.add(createShowcaseItem("sc-int-11", "interior", intCat,
                ar ? "حيز الأمتعة الخلفي وفرش الحماية" : "Rear Cargo Luggage Compartment",
                ar ? "أرضية الأمتعة، شبك التثبيت، والستارة الخلفية" : "Cargo Floor Mat, Tie-Down Hooks, Retractable Cover",
                ar ? "مساحة واسعة ونظيفة" : "Spacious & Clean",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "أرضية الشنطة خالية من الخدوش ومفرش الحماية المطاطي الأصلي موجود."
                   : "Trunk liner immaculate with genuine heavy-duty protective luggage mat."));

        list.add(createShowcaseItem("sc-int-12", "interior", intCat,
                ar ? "طقم أدوات المصنع والرافعة الأصلية" : "OEM Toolkit, Jack & Spare Tyre",
                ar ? "رافعة السيارة الهيدروليكية، مفتاح العجل، ومثلث الطوارئ" : "Factory Hydraulic Jack, Lug Wrench, Warning Triangle",
                ar ? "مكتمل 100% ومختوم" : "100% Complete & Sealed",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "جميع أدوات تغيير الإطارات الأصلية متوفرة في مكانها المخصص بحالة المصنع."
                   : "Full OEM emergency roadside equipment, jack, and tools present in dedicated bay."));

        // 8 Mechanical & Underbody Photos
        list.add(createShowcaseItem("sc-mec-01", "mechanical", mecCat,
                ar ? "حجرة المحرك 3.5 لتر توين تيربو" : "3.5L Twin-Turbo V6 Engine Bay",
                ar ? "محرك V6 توين تيربو، سيور المحرك، وأنابيب الهواء" : "3.5L Twin-Turbo V6, Drive Belts, Induction Piping",
                ar ? "دوران هادئ • لا توجد تسريبات" : "Smooth Idling • Zero Leaks",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "المحرك يعمل بنعومة وهدوء فائقين، خلو كامل من ترشيحات الزيوت أو نقص سوائل التبريد."
                   : "Engine runs smoothly and quietly; zero oil weeping or coolant consumption."));

        list.add(createShowcaseItem("sc-mec-02", "mechanical", mecCat,
                ar ? "شواحن التيربو ومسارات التبريد" : "Turbochargers & Intercooler Feeds",
                ar ? "شواحن التيربو المزدوجة، بوابات الضغط، وخراطيم التبريد" : "Twin Turbos, Wastegates, Boost Hoses",
                ar ? "ضغط تيربو مطابق للمصنع" : "Boost Levels Normal",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "خلو خراطيم التيربو من أي تهريب للزيت أو تزييت، التبريد الهوائي محكم 100%."
                   : "Turbo feed lines bone-dry with zero oil blow-by; intercooler couplings sealed tight."));

        list.add(createShowcaseItem("sc-mec-03", "mechanical", mecCat,
                ar ? "البطارية وصندوق التوزيع الكهربائي" : "12V AGM Battery & Distribution Box",
                ar ? "بطارية AGM عالية السعة وصندوق الفيوزات المقاوم للماء" : "Heavy-Duty AGM Battery, Sealed Fuse Gateway",
                ar ? "جهد 12.6 فولت • كفاءة 100%" : "12.6V Static • 100% Health",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "قوة التدوير على البارد CCA أعلى من المواصفات المطلوبة، الأقطاب نظيفة ومطلية بشحم الحماية."
                   : "Cold cranking amps test exceeds factory benchmark; terminals spotless and protected."));

        list.add(createShowcaseItem("sc-mec-04", "mechanical", mecCat,
                ar ? "خزانات سوائل الفرامل ومياه التبريد" : "Brake Fluid & Coolant Reservoirs",
                ar ? "سائل الفرامل DOT4، ماء التبريد الوردي، وزيت الدركسون" : "DOT4 Brake Fluid, OEM Pink Coolant, Power Steering",
                ar ? "مستويات السوائل مثالية" : "All Fluids at Factory Max",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "نقطة غليان سائل الفرامل تتجاوز 240 درجة مئوية؛ سائل التبريد صافٍ بنسبة تركيز 50/50."
                   : "Brake fluid boiling point exceeds 240°C; radiator coolant expansion tank full and clean."));

        list.add(createShowcaseItem("sc-mec-05", "mechanical", mecCat,
                ar ? "جنوط الألمنيوم المكحلة وديسكات الفرامل" : "20\" Diamond-Cut Alloys & Discs",
                ar ? "جنوط 20 بوصة أصلية، ديسكات مهواة، وفحمات سيراميك" : "20\" Machined Alloys, Ventilated Discs, Brake Pads",
                ar ? "عمق المداس 7.1 مم • ملاحظة احتكاك" : "Tread: 7.1mm • Sidewall Scuff",
                "/report/assets/img/image-1-30f4a447ab.jpg",
                ar ? "ملاحظة: خدش سطحي 2 مم على جدار الإطار الخلفي الأيمن. باقي الإطارات والجنوط بحالة ممتازة."
                   : "Note: Superficial 2mm curb scuff on rear-right tyre sidewall. Other 3 wheels pristine."));

        list.add(createShowcaseItem("sc-mec-06", "mechanical", mecCat,
                ar ? "ممتصات الصدمات الأمامية وقضيب التوازن" : "Front Suspension Struts & Sway Bar",
                ar ? "مساعدات هيدروليكية، جلب المقصات، وأذرع الدركسون" : "Gas Struts, Control Arm Bushings, Tie Rods",
                ar ? "محكمة وجافة • خالية من الفراغ" : "Tight & Dry • Zero Play",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "المساعدات جافة تماماً بدون أي تسريب للزيت الهيدروليكي، مفاصل التوجيه محكمة تحت الحمل."
                   : "Shock absorber damper bodies dry with zero seepage; ball joints tight under test load."));

        list.add(createShowcaseItem("sc-mec-07", "mechanical", mecCat,
                ar ? "نظام التعليق الخلفي متعدد الوصلات" : "Rear Multi-Link Axle & Bushings",
                ar ? "مساعدات خلفية، أذرع التوازن، والدفرنش الخلفي" : "Rear Coils & Dampers, Sway Links, Rear Differential",
                ar ? "صلابة هيكلية ممتازة" : "Sound Structural Integrity",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "الدفرنش الخلفي جاف وخالٍ من أي تهريب، جلب التعليق المطاطية مرنة وخالية من التشققات."
                   : "Differential casing bone-dry with zero oil weeping; rubber suspension bushings supple."));

        list.add(createShowcaseItem("sc-mec-08", "mechanical", mecCat,
                ar ? "أرضية المركبة من الأسفل وقضبان الشاصيه" : "Underbody Hoist & Chassis Rails",
                ar ? "قضبان الشاصيه الرئيسية، صفائح الحماية، ونظام العادم" : "Boxed Chassis Rails, Steel Skid Plates, Exhaust Pipes",
                ar ? "شاصيه مستقيم • خالٍ من الصدأ" : "Straight Frame • Zero Corrosion",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "تم الفحص على الرافعة؛ قضبان الشاصيه مستقيمة 100% وخالية من أي ضربات سفلية أو تلحيم."
                   : "Inspected on hoist; chassis rails 100% straight with zero grounding impacts or rust."));

        return list;
    }
}
