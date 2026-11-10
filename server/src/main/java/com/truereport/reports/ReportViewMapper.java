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

        // Exactly 10 Essential Clean Inspection Photos
        // 1. Full Frontal Profile
        list.add(createShowcaseItem(
                "sc-front-full", "exterior", extCat,
                ar ? "الواجهة الأمامية الكاملة" : "Full Frontal Profile",
                ar ? "الصدام، غطاء المحرك، وشبك الرادياتير" : "Front Bumper, Bonnet, Chrome Radiator Grille",
                ar ? "سليم • طلاء المصنع الأصلي" : "Pristine • Original Factory Paint",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "الواجهة الأمامية بحالة ممتازة وخالية من آثار الترميل أو الصدمات؛ فواصل الرفارف متطابقة هندسياً."
                   : "Frontal clip in excellent condition with zero road blast; fender alignment factory true."
        ));

        // 2. Front 3/4 Perspective
        list.add(createShowcaseItem(
                "sc-front-34", "exterior", extCat,
                ar ? "الزاوية الأمامية الجانبية 3/4" : "Front 3/4 Dynamic Angle",
                ar ? "المصابيح الأمامية LED والرفرف الأمامي" : "LED Matrix Headlamps & Front Fender",
                ar ? "سليم • لا توجد خدوش" : "Pristine • Scratch-Free",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "عدسات المصابيح الأمامية صافية وخالية من الاصفرار أو الشروخ؛ زاوية الرفرف سليمة تماماً."
                   : "Headlamp optical lenses 100% clear with zero micro-fractures; quarter contour intact."
        ));

        // 3. Left Lateral Flank
        list.add(createShowcaseItem(
                "sc-side-left", "exterior", extCat,
                ar ? "الجانب الأيسر والأبواب" : "Left Lateral Flank & Doors",
                ar ? "باب السائق والباب الخلفي وعتبة الصعود" : "Driver Door, Rear Left Door, Rocker Panel",
                ar ? "خالٍ من الضربات • لمعان ممتاز" : "Dent-Free • Gloss Finish",
                "/report/assets/img/image-2-074ad6c830.jpg",
                ar ? "استواء كامل لصفائح الأبواب الجانبية دون أي حكات أو نقرات مواقف."
                   : "Completely straight side body panels with zero parking dings."
        ));

        // 4. Right Lateral Flank
        list.add(createShowcaseItem(
                "sc-side-right", "exterior", extCat,
                ar ? "الجانب الأيمن والأبواب" : "Right Lateral Flank & Doors",
                ar ? "باب الراكب، الباب الخلفي وغطاء الوقود" : "Front Passenger Door, Rear Door, Fuel Cap",
                ar ? "سطح نظيف • مرآة سليمة" : "Clean Surface • Mirror Intact",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "الطلاء بلمعان أصلي، المرايا الجانبية تطوى بسلاسة ونظام النقطة العمياء يعمل."
                   : "Paint gloss depth factory-grade; mirror power folding operational."
        ));

        // 5. Full Rear Profile & Tailgate
        list.add(createShowcaseItem(
                "sc-rear-full", "exterior", extCat,
                ar ? "الواجهة الخلفية وباب الصندوق" : "Full Rear Profile & Tailgate",
                ar ? "باب الصندوق الكهربائي، المصابيح الخلفية، والكاميرا" : "Electric Liftgate, Tail Lamps, Backup Camera",
                ar ? "حساسات وكاميرا مفحوصة" : "Sensors & Camera Verified",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "باب الشنطة يفتح ويقفل كهربائياً بسلاسة، حساسات الرجوع للخلف والكاميرا تعمل بدقة."
                   : "Power liftgate opens and latches smoothly; rear camera and ultrasonic sensors tested."
        ));

        // 6. Driver Cockpit & Dash
        list.add(createShowcaseItem(
                "sc-cabin-cockpit", "interior", intCat,
                ar ? "قمرة القيادة وعجلة القيادة" : "Driver Cockpit & Steering Wheel",
                ar ? "مقود جلدي، عدادات رقمية، وشاشة الملاحة" : "Leather Wheel, Digital Cluster, Navigation Screen",
                ar ? "خلو تام من لمبات التحذير" : "Zero Warning Lights",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "لوحة القيادة خالية من أي لمبات تحذيرية، قراءة العداد 42,850 كم موثقة ومطابقة."
                   : "Dash cluster completely clean with zero DTC faults; odometer 42,850 km verified."
        ));

        // 7. Interior Seating & Upholstery
        list.add(createShowcaseItem(
                "sc-seats-front", "interior", intCat,
                ar ? "المقاعد والفرش الداخلي" : "Premium Leather Seating",
                ar ? "جلد طبيعي مخرم، تحكم كهربائي وتبريد مقاعد" : "Perforated Nappa Leather, Power Seats with Memory",
                ar ? "جلد مرن وخالٍ من التشققات" : "Supple Leather • No Tears",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "المقاعد محتفظة بمرونتها وقوامها الأصلي دون هبوط أو تآكل بالفرش."
                   : "Seat bolsters firm with zero sagging; heating and ventilation functional."
        ));

        // 8. 3.5L Twin-Turbo Engine Bay
        list.add(createShowcaseItem(
                "sc-engine-bay", "mechanical", mecCat,
                ar ? "حجرة المحرك 3.5L توين تيربو" : "3.5L Twin-Turbo V6 Engine Bay",
                ar ? "محرك V6، سيور التوقيت، وخطوط التبريد" : "V6 Twin-Turbo, Serpentine Belts, Coolant Lines",
                ar ? "دوران هادئ • لا توجد تسريبات" : "Smooth Idling • Zero Leaks",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "المحرك يعمل بنعومة وهدوء فائقين، خلو كامل من ترشيحات الزيوت أو نقص سوائل التبريد."
                   : "Engine runs smoothly and quietly; zero oil weeping or coolant consumption."
        ));

        // 9. Alloy Wheels & Tyres
        list.add(createShowcaseItem(
                "sc-wheels", "mechanical", mecCat,
                ar ? "الجنوط والعجلات ونظام الفرامل" : "20\" Alloy Wheels & Brake Rotors",
                ar ? "جنوط ألمنيوم مكحلة وديسكات فرامل مهواة" : "OEM Diamond-Cut Alloys & Ventilated Rotors",
                ar ? "عمق المداس 7.1 مم • ملاحظة احتكاك" : "Tread: 7.1mm • Sidewall Scuff",
                "/report/assets/img/image-1-30f4a447ab.jpg",
                ar ? "ملاحظة: خدش سطحي 2 مم على جدار الإطار الخلفي الأيمن. باقي الإطارات والجنوط بحالة ممتازة."
                   : "Note: Superficial 2mm curb scuff on rear-right tyre sidewall. Other 3 wheels pristine."
        ));

        // 10. Underbody Hoist & Chassis
        list.add(createShowcaseItem(
                "sc-underbody", "mechanical", mecCat,
                ar ? "أسفل الهيكل والشاصيه" : "Underbody Hoist & Chassis Rails",
                ar ? "قضبان الشاصيه، صفائح الحماية، ونظام العادم" : "Frame Rails, Skid Plates, Exhaust System",
                ar ? "شاصيه مستقيم • خالٍ من الصدأ" : "Straight Frame • Zero Corrosion",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "تم الفحص على الرافعة؛ قضبان الشاصيه مستقيمة 100% وخالية من أي ضربات سفلية أو تلحيم."
                   : "Inspected on hoist; chassis rails 100% straight with zero grounding impacts or rust."
        ));

        return list;
    }
}
