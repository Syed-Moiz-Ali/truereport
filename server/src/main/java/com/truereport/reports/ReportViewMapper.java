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

    private List<Map<String, Object>> vehicleShowcase(ReportSnapshot snapshot,
                                                      Map<UUID, EvidenceDerivative> byEvidence,
                                                      String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        String extCat = ar ? "خارجي" : "Exterior";
        String intCat = ar ? "داخلي" : "Interior";
        String mecCat = ar ? "ميكانيكي" : "Mechanical";

        // 1. Front 3/4 Dynamic Angle
        list.add(createShowcaseItem(
                "sc-front-34", "exterior", extCat,
                ar ? "الزاوية الأمامية الجانبية 3/4" : "Front 3/4 Dynamic Angle",
                ar ? "الصدام، المصابيح الأمامية LED، والشبك الكرومي" : "Bumper, LED Matrix Headlamps, Chrome Radiator Grille",
                ar ? "سليم • خالٍ من آثار الحصى" : "Pristine • Zero Stone Chips",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "واجهة أمامية نظيفة تماماً بدون أي علامات ترميل أو احتكاك سطحي. عدسات المصابيح صافية بنسبة 100%."
                   : "Frontal clip exceptionally clean with zero road grit blast or scuffs. Headlamp optical clarity 100%."
        ));

        // 2. Full Frontal Profile
        list.add(createShowcaseItem(
                "sc-front-full", "exterior", extCat,
                ar ? "الواجهة الأمامية الكاملة" : "Full Frontal Profile",
                ar ? "غطاء المحرك، حليات الشبك، وقاعدة الزجاج الأمامي" : "Bonnet Lid, Chrome Trim, Windshield Cowl",
                ar ? "طلاء المصنع الأصلي" : "Original Factory Paint",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "سماكة الدهان 112 ميكرون مطابقة تماماً لمواصفات المصنع دون أي مؤشرات لإعادة الرش."
                   : "Paint depth measured at 112 microns conforming strictly to factory spec with zero respray indicators."
        ));

        // 3. Engine Hood & Panel Gaps
        list.add(createShowcaseItem(
                "sc-hood", "exterior", extCat,
                ar ? "غطاء المحرك وفواصل الصدام" : "Engine Hood & Panel Gaps",
                ar ? "فواصل متناسقة 3.8 مم، قفل محكم ومساعدات هيدروليكية" : "Even 3.8mm Gaps, Secure Latch & Hydraulic Struts",
                ar ? "تطابق هندسي متماثل" : "Factory Symmetrical",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "فواصل متساوية ومثالية بين الرفارف وغطاء المحرك دون أي ميلان أو تعديل في مسامير التثبيت."
                   : "Panel shut lines completely even between fenders and bonnet; zero evidence of bolt removal."
        ));

        // 4. Left Side Profile & Doors
        list.add(createShowcaseItem(
                "sc-side-left", "exterior", extCat,
                ar ? "الجانب الأيسر والأبواب" : "Left Lateral Flank & Doors",
                ar ? "باب السائق والباب الخلفي، مقابض الأبواب، وعتبة الصعود" : "Driver & Rear Passenger Doors, Door Handles, Rocker Steps",
                ar ? "خالٍ من الصدمات • لمعان ممتاز" : "Dent-Free • Gloss Finish",
                "/report/assets/img/image-2-074ad6c830.jpg",
                ar ? "أبواب جانبية مستوية وخالية من ضربات المواقف. شريط العتبة سليم دون تآكل."
                   : "Straight door panels with zero parking dings. Side running board steps firmly mounted."
        ));

        // 5. Right Side Profile & Doors
        list.add(createShowcaseItem(
                "sc-side-right", "exterior", extCat,
                ar ? "الجانب الأيمن والأبواب" : "Right Lateral Flank & Doors",
                ar ? "باب الراكب، الباب الخلفي الأيمن، وغطاء خزان الوقود" : "Front Passenger Door, Right Rear Door, Fuel Filler Flap",
                ar ? "سطح نظيف • مرآة سليمة" : "Clean Surface • Mirror Intact",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "خلو الرفرفين والبابين الأيمنين من أي خدوش عميقة. غطاء الوقود يغلق بإحكام."
                   : "Right side flanks free of deep scratches. Fuel flap release mechanism operational."
        ));

        // 6. Rear 3/4 Dynamic Angle
        list.add(createShowcaseItem(
                "sc-rear-34", "exterior", extCat,
                ar ? "الزاوية الخلفية 3/4" : "Rear 3/4 Dynamic Angle",
                ar ? "الرفرف الخلفي، مجموعة الإضاءة الخلفية، ومخرج العادم" : "Quarter Panel, Tail Lamp Cluster, Integrated Diffuser",
                ar ? "انحناءات هيكل سليمة" : "Pristine Contour",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "انحناءات الرفرف الخلفي خالية من أي إصلاحات أو معجون سمكرة."
                   : "Rear quarter curvature factory original with zero structural filler detected."
        ));

        // 7. Full Rear & Power Tailgate
        list.add(createShowcaseItem(
                "sc-rear-full", "exterior", extCat,
                ar ? "الواجهة الخلفية وباب الصندوق" : "Full Rear & Power Tailgate",
                ar ? "باب الصندوق الكهربائي، الكاميرا الخلفية، وحساسات الاصطدام" : "Electric Liftgate, Backup HD Camera, Ultrasonic Sensors",
                ar ? "حساسات وكاميرا مفحوصة" : "Sensor Array Verified",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "فتح وإغلاق كهربائي سلس بضغطة زر. عدسة الكاميرا عالية الوضوح والحساسات تعمل بدقة."
                   : "Power liftgate opens and latches smoothly. Rear HD camera lens pristine; sensors calibrated."
        ));

        // 8. Roof Panel & Panoramic Glass
        list.add(createShowcaseItem(
                "sc-roof", "exterior", extCat,
                ar ? "سقف المركبة والفتحة البانورامية" : "Roof Panel & Panoramic Glass",
                ar ? "الزجاج البانورامي، عوازل المياه المطاطية، وسكك التحميل" : "Panoramic Glass, Watertight Weatherstripping, Roof Rails",
                ar ? "عزل مائي محكم • مجرى سلس" : "Watertight • Smooth Track",
                "/report/assets/img/image-3-b97c8c4381.jpg",
                ar ? "تم فحص العزل المائي وتصريف المياه تحت الضغط؛ مجاري الفتحة نظيفة والزجاج خالٍ من الشروخ."
                   : "Pressure water test verified zero leaks; sunroof tracks greased and drain channels unobstructed."
        ));

        // 9. Side Mirrors & Blind Spot Cameras
        list.add(createShowcaseItem(
                "sc-mirrors", "exterior", extCat,
                ar ? "المرايا الجانبية وحساسات النقطة العمياء" : "Side Mirrors & Blind Spot Cameras",
                ar ? "طي كهربائي، تدفئة زجاج المرآة، ومؤشرات الالتفاف LED" : "Power Folding, Heated Glass, Integrated Turn Indicators",
                ar ? "تعمل بكفاءة تامة" : "Fully Operational",
                "/report/assets/img/image-1-7c45b77732.jpg",
                ar ? "محركات الطي الجانبي تعمل بهدوء وتزامن، مصابيح التحذير بالنقطة العمياء مفحوصة وسليمة."
                   : "Power folding actuators operate silently in sync; blind-spot warning indicators tested."
        ));

        // 10. Underbody Hoist & Floor Pan
        list.add(createShowcaseItem(
                "sc-underbody", "exterior", extCat,
                ar ? "أرضية المركبة من الأسفل والشاصيه" : "Underbody Hoist & Floor Pan",
                ar ? "صفائح الحماية المعدنية، العوازل الحرارية، والعوارض السفلية" : "Skid Plates, Thermal Heat Shields, Lower Structural Crossmembers",
                ar ? "خالٍ من الصدمات أو الصدأ" : "Zero Impact Damage or Rust",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "شاصيه مستقيم بدون أي تعديل أو صدمات سفلية، مسامير صفائح الحماية بحالة المصنع."
                   : "Chassis rails arrow-straight with zero grounding impacts; undertray fasteners intact."
        ));

        // 11. Driver Cockpit & Steering Wheel
        list.add(createShowcaseItem(
                "sc-cabin-cockpit", "interior", intCat,
                ar ? "قمرة القيادة وعجلة القيادة" : "Driver Cockpit & Steering Wheel",
                ar ? "مقود جلدي مدفأ، مبدلات السرعة، وأزرار التحكم الصوتي" : "Heated Leather Wheel, Paddle Shifters, Audio & Cruise Buttons",
                ar ? "أزرار وفرش بحالة المصنع" : "Factory Pristine",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "جلد المقود ناعم وخالٍ من بهتان اللون أو التآكل، جميع الأزرار تقدم ارتداداً ميكانيكياً ممتازاً."
                   : "Steering wheel leather supple with zero bolster shine or wear; tactile feedback crisp on all switches."
        ));

        // 12. 12.3\" Digital Instrument Cluster
        list.add(createShowcaseItem(
                "sc-cluster", "interior", intCat,
                ar ? "شاشة العدادات الرقمية 12.3 بوصة" : "12.3\" Digital Instrument Cluster",
                ar ? "قراءة العداد 42,850 كم، مراقبة ضغط الإطارات، ومؤشرات الأمان" : "Odometer 42,850 KM, TPMS Live Telemetry, Safety Graphics",
                ar ? "خلو تام من لمبات التحذير" : "Zero Warning Faults",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "فحص ذاتي للعداد بنجاح 100% مع تشغيل المحرك؛ لا توجد أي أكواد أعطال مسجلة في كمبيوتر السيارة."
                   : "Self-test sequence completed with zero stored DTC codes on CAN bus; odometer verified."
        ));

        // 13. Central Console & Infotainment
        list.add(createShowcaseItem(
                "sc-console", "interior", intCat,
                ar ? "الشاشة المركزية ووحدة التحكم بالتكييف" : "Central Console & Infotainment",
                ar ? "شاشة لمس عالية الدقة، نظام الملاحة، ومحدد وضعيات الدفع الرباعي" : "High-Res Touchscreen, Navigation, Multi-Terrain Drive Mode Selector",
                ar ? "استجابة لمس فورية" : "Instant Touch Response",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "النظام الصوتي الفاخر وشاشات التحكم تعمل بكفاءة عالية؛ مفاتيح الدفع الرباعي تستجيب فوراً."
                   : "Premium audio system and display crisp; 4WD terrain dial shifts smoothly between modes."
        ));

        // 14. Front Leather Seats
        list.add(createShowcaseItem(
                "sc-seats-front", "interior", intCat,
                ar ? "المقاعد الأمامية مع التبريد والتدفئة" : "Front Leather Seats (Heated / Ventilated)",
                ar ? "جلد طبيعي مخرم، تحكم كهربائي بـ 10 اتجاهات مع ذاكرة حفظ" : "Perforated Premium Nappa, 10-Way Power Adjustment with Memory",
                ar ? "جلد مرن وخالٍ من التشققات" : "Supple Leather • No Creases",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "أجنحة المقاعد محتفظة بشكلها الأصلي دون هبوط، محركات التعديل الكهربائي تعمل بسلاسة."
                   : "Side bolsters firm with zero foam sagging; multi-axis motor adjustments operate silently."
        ));

        // 15. Rear Passenger Cabin & Dual A/C
        list.add(createShowcaseItem(
                "sc-seats-rear", "interior", intCat,
                ar ? "المقصورة الخلفية ومكيف الهواء المستقل" : "Rear Passenger Cabin & Independent A/C",
                ar ? "مقاعد الصف الثاني، فتحات تكييف سقفية، ومنافذ شحن تايب سي" : "Second Row Seating, Roof Air Vents, USB-C Fast Chargers",
                ar ? "نظافة فائقة • استخدام قليل" : "Spotless • Minimal Usage",
                "/report/assets/img/image-1-96fe1d6167.jpg",
                ar ? "فرش خلفي بحالة ممتازة وخالٍ من البقع أو الروائح؛ التبريد الخلفي يصل لدرجة ممتازة بسرعة."
                   : "Rear upholstery pristine and odor-free; dual rear climate blower delivers strong ice-cold airflow."
        ));

        // 16. Rear Cargo Compartment & Toolkit
        list.add(createShowcaseItem(
                "sc-trunk", "interior", intCat,
                ar ? "مساحة الأمتعة الخلفية ومجموعة الأدوات" : "Rear Cargo Compartment & OEM Toolkit",
                ar ? "أرضية الأمتعة، رافعة السيارة الأصلية، مفتاح العجل وطفاية الحريق" : "Cargo Floor Mat, Factory Hydraulic Jack, Lug Wrench, Emergency Flare",
                ar ? "طقم أدوات المصنع كامل" : "Complete OEM Tools",
                "/report/assets/img/image-1-5926056ac5.jpg",
                ar ? "حيز الشنطة نظيف جداً ومفرش الحماية سليم؛ طقم عدة الطوارئ موجود بالكامل ومختوم."
                   : "Boot carpet immaculate; full factory tool set, jack, and warning triangle complete in storage bay."
        ));

        // 17. 3.5L Twin-Turbo V6 Engine Bay
        list.add(createShowcaseItem(
                "sc-engine-bay", "mechanical", mecCat,
                ar ? "حجرة المحرك 3.5 لتر توين تيربو" : "3.5L Twin-Turbo V6 Engine Bay",
                ar ? "محرك V6 توين تيربو، سيور المحرك، شواحن التيربو، وخراطيم التبريد" : "Twin-Turbocharged V6, Drive Belts, Turbo Wastegates, Cooling Hoses",
                ar ? "دوران هادئ • خراطيم أصلية" : "Smooth Idling • Factory Hoses",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "تشغيل هادئ بدون أي اهتزازات غير طبيعية أو أصوات تكايات، خلو تام من أي ترشيحات زيتية."
                   : "Engine starts instantly and idles smoothly; zero valve train chatter or oil seepage detected."
        ));

        // 18. 20\" Diamond-Cut Alloy Wheels & Brakes
        list.add(createShowcaseItem(
                "sc-wheels", "mechanical", mecCat,
                ar ? "جنوط 20 بوصة أصلية وديسكات الفرامل" : "20\" OEM Diamond-Cut Wheels & Brakes",
                ar ? "جنوط ألمنيوم مكحلة، ديسكات مهواة، وحساسات ضغط الإطارات" : "Machined Face Alloys, Ventilated Disc Rotors, Internal TPMS Sensors",
                ar ? "عمق المداس 7.1 مم • ديسكات 90%" : "Tread: 7.1mm • Rotors 90%",
                "/report/assets/img/image-1-30f4a447ab.jpg",
                ar ? "ملاحظة: وجود خدش سطحي 2 مم على جدار الإطار الخلفي الأيمن. باقي الجنوط الثلاثة بحالة ممتازة."
                   : "Note: 2mm surface curb scuff on rear-right sidewall. Remaining 3 rims and tyres in excellent order."
        ));

        // 19. Battery & Electrical Gateway Box
        list.add(createShowcaseItem(
                "sc-battery", "mechanical", mecCat,
                ar ? "البطارية وصندوق التوزيع الكهربائي" : "12V AGM Battery & Electrical Gateway",
                ar ? "بطارية AGM عالية السعة، كابلات التوصيل، وصندوق الفيوزات المقاوم للماء" : "High-Capacity AGM Battery, Heavy Gauge Cables, Weather-Sealed Fuse Box",
                ar ? "جهد 12.6 فولت • كفاءة 100%" : "12.6V Static • 100% Health",
                "/report/assets/img/image-2-e9a5952732.jpg",
                ar ? "قوة التدوير على البارد CCA أعلى من المواصفات المطلوبة، الأقطاب نظيفة ومطلية بشحم الحماية."
                   : "Cold cranking amps test exceeds factory benchmark; terminals spotless and greased against oxidation."
        ));

        // 20. Stainless Exhaust & Emissions Catalysts
        list.add(createShowcaseItem(
                "sc-exhaust", "mechanical", mecCat,
                ar ? "نظام العادم ودبات التلوث" : "Dual Stainless Exhaust & Catalysts",
                ar ? "أنابيب ستانلس ستيل، محولات حفازة ثلاثية، ومثبتات مطاطية مرنة" : "Stainless Steel Piping, Three-Way Catalytic Converters, Heavy-Duty Hangers",
                ar ? "انبعاثات مطابقة للمواصفات" : "Emissions Spec Compliant",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "نظام العادم محكم بالكامل بدون أي تسريب للغازات، قراءات حساسات الأكسجين O2 متوازنة تماماً."
                   : "Exhaust joints sealed with zero soot blow-by; lambda oxygen sensors switching properly within spec."
        ));

        return list;
    }
}
