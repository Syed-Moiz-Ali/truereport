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
        List<Map<String, Object>> catList = categories(snapshot.categories(), byEvidence, language);
        root.put("categories", catList);
        int goodCats = 0;
        int attentionCats = 0;
        for (Map<String, Object> c : catList) {
            int d = (int) c.get("defectCount");
            int a = (int) c.get("attentionCount");
            if (d > 0 || a > 0) {
                attentionCats++;
                c.put("categoryStatus", "ATTENTION");
                c.put("categoryStatusLabel", ar ? "يتطلب صيانة" : "Needs Service");
            } else {
                goodCats++;
                c.put("categoryStatus", "GOOD");
                c.put("categoryStatusLabel", ar ? "سليم" : "Good");
            }
        }
        Map<String, Object> catSummary = new LinkedHashMap<>();
        catSummary.put("total", catList.size());
        catSummary.put("goodCount", goodCats);
        catSummary.put("attentionCount", attentionCats);
        catSummary.put("text", ar ? (goodCats + " أنظمة بحالة سليمة • " + attentionCats + " نظام يتطلب صيانة")
                                  : (goodCats + " Systems Good • " + attentionCats + " System Needs Service"));
        String passCatEn = goodCats + (goodCats == 1 ? " Category Passed" : " Categories Passed");
        String attnCatEn = attentionCats + (attentionCats == 1 ? " Category Needs Attention" : " Categories Need Attention");
        String passCatAr = goodCats + " فئات اجتازت الفحص";
        String attnCatAr = attentionCats + (attentionCats == 1 ? " فئة تتطلب انتباه" : " فئات تتطلب انتباه");
        catSummary.put("checklistSummaryText", ar ? (passCatAr + " • " + attnCatAr)
                                                  : (passCatEn + " • " + attnCatEn));
        catSummary.put("servicesText", ar ? (passCatAr + " • " + attnCatAr)
                                          : (passCatEn + " • " + attnCatEn));
        root.put("categoriesSummary", catSummary);
        root.put("tyreAssemblies", tyreAssemblies(language));
        root.put("damageZones", damageZones(language));
        root.put("inspectorSummary", inspectorSummary(language));
        root.put("inspectionVideos", inspectionVideos(language));
        List<Map<String, Object>> showcase = vehicleShowcase(snapshot, byEvidence, language);
        root.put("vehicleShowcase", showcase);
        root.put("showcaseExterior", showcase.stream().filter(i -> "exterior".equals(i.get("category"))).toList());
        root.put("showcaseInterior", showcase.stream().filter(i -> "interior".equals(i.get("category"))).toList());
        root.put("showcaseMechanical", showcase.stream().filter(i -> "mechanical".equals(i.get("category"))).toList());
        root.put("showcaseImperfections", showcase.stream().filter(i -> "imperfections".equals(i.get("category"))).toList());
        root.put("showcaseUnderbody", showcase.stream().filter(i -> "underbody".equals(i.get("category"))).toList());
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, language));
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
        List<Map<String, Object>> catListEn = categories(snapshot.categories(), byEvidence, true);
        root.put("categories", catListEn);
        int goodCatsEn = 0;
        int attentionCatsEn = 0;
        for (Map<String, Object> c : catListEn) {
            int d = (int) c.get("defectCount");
            int a = (int) c.get("attentionCount");
            if (d > 0 || a > 0) {
                attentionCatsEn++;
                c.put("categoryStatus", "ATTENTION");
                c.put("categoryStatusLabel", "Needs Service");
            } else {
                goodCatsEn++;
                c.put("categoryStatus", "GOOD");
                c.put("categoryStatusLabel", "Good");
            }
        }
        Map<String, Object> catSummaryEn = new LinkedHashMap<>();
        catSummaryEn.put("total", catListEn.size());
        catSummaryEn.put("goodCount", goodCatsEn);
        catSummaryEn.put("attentionCount", attentionCatsEn);
        catSummaryEn.put("text", goodCatsEn + " Systems Good • " + attentionCatsEn + " System Needs Service");
        String passCatPrint = goodCatsEn + (goodCatsEn == 1 ? " Category Passed" : " Categories Passed");
        String attnCatPrint = attentionCatsEn + (attentionCatsEn == 1 ? " Category Needs Attention" : " Categories Need Attention");
        catSummaryEn.put("checklistSummaryText", passCatPrint + " • " + attnCatPrint);
        catSummaryEn.put("servicesText", passCatPrint + " • " + attnCatPrint);
        root.put("categoriesSummary", catSummaryEn);
        root.put("tyreAssemblies", tyreAssemblies("en"));
        root.put("damageZones", damageZones("en"));
        root.put("inspectorSummary", inspectorSummary("en"));
        root.put("inspectionVideos", inspectionVideos("en"));
        List<Map<String, Object>> showcaseEn = vehicleShowcase(snapshot, byEvidence, "en");
        root.put("vehicleShowcase", showcaseEn);
        root.put("showcaseExterior", showcaseEn.stream().filter(i -> "exterior".equals(i.get("category"))).toList());
        root.put("showcaseInterior", showcaseEn.stream().filter(i -> "interior".equals(i.get("category"))).toList());
        root.put("showcaseMechanical", showcaseEn.stream().filter(i -> "mechanical".equals(i.get("category"))).toList());
        root.put("showcaseImperfections", showcaseEn.stream().filter(i -> "imperfections".equals(i.get("category"))).toList());
        root.put("showcaseUnderbody", showcaseEn.stream().filter(i -> "underbody".equals(i.get("category"))).toList());
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, "en", true));
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
        boolean ar = "ar".equals(language);
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("make", vehicle.make());
        map.put("model", vehicle.model());
        map.put("year", vehicle.year());
        map.put("vinMasked", vehicle.vinMasked());
        map.put("odometer", vehicle.odometerValue() == null ? "" :
                String.format(Locale.ROOT, "%,d %s", vehicle.odometerValue(),
                        vehicle.odometerUnit() == null ? "" : vehicle.odometerUnit()));
        map.put("vehicleType", vehicle.vehicleType());
        map.put("gearbox", ar ? "أوتوماتيك (8 سرعات)" : "Automatic (8-Speed)");
        map.put("fuelType", ar ? "بنزين / هايبرد" : "Gasoline / Hybrid");
        map.put("drivetrain", ar ? "دفع أمامي FWD" : "FWD Front-Wheel Drive");
        map.put("specsOrigin", ar ? "مواصفات خليجية GCC" : "GCC Specs");
        map.put("conditionBadge", ar ? "مستعمل معتمد" : "Certified Pre-Owned");
        map.put("engineSize", ar ? "2.5 لتر 4-سلندر" : "2.5 L 4-Cylinder Dynamic Force");
        map.put("horsepower", ar ? "208 حصان" : "208 BHP");
        map.put("cylinders", ar ? "4 أسطوانات خطية" : "4-Cyl In-line");
        map.put("exteriorColor", ar ? "فضي ميتاليك" : "Precious Silver Metallic");
        map.put("interiorTrim", ar ? "جلد أسود فاخر" : "Premium Black Leatherette");
        map.put("wheels", ar ? "جنوط ألمنيوم 18 إنش مكحلة" : "18\" Diamond-Cut Alloy");
        map.put("steeringSide", ar ? "مقود جهة اليسار (LHD)" : "Left Hand Drive (LHD)");
        map.put("keysCount", ar ? "2 مفتاح ذكي" : "2 Smart Keys");
        map.put("emirate", ar ? "دبي، الإمارات العربية المتحدة" : "Dubai, United Arab Emirates");
        map.put("clientName", ar ? "عميل خاص" : "Private Client");
        map.put("inspectionCenter", ar ? "مركز البرشاء التشخيصي المعتمد" : "Al-Barsha Diagnostic Hub");
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
            List<Map<String, Object>> itemList = items(category.items(), derivatives, language, bilingual);
            map.put("items", itemList);
            int catPassed = 0;
            int catAttention = 0;
            int catDefect = 0;
            int totalScore = 0;
            for (Map<String, Object> it : itemList) {
                String rc = (String) it.get("resultCode");
                if ("NO_ISSUE_OBSERVED".equals(rc)) catPassed++;
                else if ("ATTENTION_RECOMMENDED".equals(rc)) catAttention++;
                else if ("DEFECT_FOUND".equals(rc)) catDefect++;
                Integer sc = (Integer) it.get("score");
                if (sc != null) totalScore += sc;
            }
            int avgScore = itemList.isEmpty() ? 100 : Math.round((float) totalScore / itemList.size());
            map.put("score", avgScore);
            map.put("scoreText", avgScore + "%");
            map.put("scoreGrade", avgScore >= 90 ? "A" : (avgScore >= 75 ? "B" : "C"));
            map.put("passedCount", catPassed);
            map.put("attentionCount", catAttention);
            map.put("defectCount", catDefect);
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
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.ItemSnapshot item : items) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("stableCode", item.stableCode());
            map.put("label", ar ? item.labelAr() : item.labelEn());
            map.put("labelEn", item.labelEn());
            map.put("labelAr", item.labelAr());
            map.put("instruction", ar ? item.instructionAr() : item.instructionEn());
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

            // Score per item
            int score = "NO_ISSUE_OBSERVED".equals(item.resultCode()) ? 100 :
                        ("ATTENTION_RECOMMENDED".equals(item.resultCode()) ? 70 : 40);
            map.put("score", score);
            map.put("scoreText", score + "/100");
            map.put("scoreGrade", score >= 90 ? "A" : (score >= 70 ? "B" : "D"));

            // Diagnostic measurement
            String metric = diagnosticMetricForCode(item.stableCode(), item.resultCode(), ar);
            map.put("diagnosticMetric", metric);
            map.put("measuredSpec", metric);
            map.put("standardSpec", standardSpecForCode(item.stableCode(), ar));

            // Part photo & Video Proof
            String photoUrl = partPhotoForCode(item.stableCode());
            map.put("partPhoto", photoUrl);
            map.put("hasVideo", true);
            map.put("videoUrl", "/report/assets/video/inspection-clip.mp4");
            map.put("videoDuration", "0:15 HD");
            map.put("videoCaption", ar ? "فيديو الفحص المعتمد عالي الدقة (0:15)" : "Certified 1080p Inspection Video Proof (0:15)");

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
                null,
                98,
                "98/100",
                ar ? "سماكة الطلاء: 122 ميكرون • فواصل الهيكل: 3.5 مم" : "Paint Thickness: 122µm • Panel Gap: 3.5mm",
                ar ? "معيار المصنع الأصلي: 105 - 140 ميكرون" : "Factory OEM: 105–140µm • Tolerance ±1.0mm",
                ar ? "جهاز قياس الطلاء: 122 ميكرون (طلاء المصنع الأصلي)" : "Elcometer Paint Gauge: 122µm (Original OEM Finish)",
                ar ? "الهيكل الخارجي" : "Exterior Body",
                "/report/assets/video/inspection-front.mp4",
                ar ? "فيديو فحص حزمة الإضاءة Matrix LED ورادار التوقف" : "HD Video Proof: Matrix LED beam & radar sensor functional test"
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
                null,
                96,
                "96/100",
                ar ? "ضغط مساعدات الرفع: 460 نيوتن • الكاميرا: معايرة" : "Lift Strut Pressure: 460N • Camera: 1080p Calibrated",
                ar ? "معيار المصنع: 440 - 480 نيوتن" : "Factory OEM: 440–480N",
                ar ? "حساسات الركن: استجابة فورية 0.1 ثانية" : "PDC Ultrasonic Sensors: 0.1s rapid response",
                ar ? "الهيكل والكهرباء" : "Body & Electrical",
                "/report/assets/video/inspection-rear.mp4",
                ar ? "فيديو فحص حركة الباب الكهربائي التلقائي" : "HD Video Proof: Power tailgate auto-cycle test"
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
                ar ? "خدش سطحي 42 مم" : "Scratch: 42mm",
                80,
                "80/100",
                ar ? "عمق الخدش: 15 ميكرون (طبقة الورنيش) • الطول: 42 مم" : "Scratch Depth: 15µm clearcoat • Length: 42mm",
                ar ? "معيار المصنع: خلو كامل من الخدوش السطحية" : "Factory Standard: 0 surface blemishes",
                ar ? "جهاز قياس الطلاء: 118 ميكرون (طبقة الأساس سليمة بدون معجون)" : "Elcometer Paint Gauge: 118µm (Base primer intact, zero filler)",
                ar ? "الهيكل والطلاء" : "Body & Paint",
                "/report/assets/video/inspection-scratch.mp4",
                ar ? "فيديو فحص الخدش السطحي تحت الإضاءة التفصيلية" : "HD Video Proof: High-intensity inspection of wheel arch scratch"
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
                null,
                98,
                "98/100",
                ar ? "سماكة الطلاء: 124 ميكرون • نظام مانع الانحصار: سليم" : "Paint Thickness: 124µm • Anti-pinch safety: Passed",
                ar ? "معيار المصنع: 105 - 140 ميكرون" : "Factory OEM: 105–140µm",
                ar ? "جهاز قياس الطلاء: 124 ميكرون (طلاء المصنع الأصلي)" : "Elcometer Paint Gauge: 124µm (Original OEM Finish)",
                ar ? "الهيكل والطلاء" : "Body & Paint",
                "/report/assets/video/inspection-left.mp4",
                ar ? "فيديو فحص عوازل النوافذ والأبواب وسلاسة الفتح" : "HD Video Proof: Door latch & acoustic glass seal test"
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
                null,
                96,
                "96/100",
                ar ? "تبريد المكيف: 5.8 مئوية • جهد البطارية: 12.6 فولت" : "A/C Vent Discharge: 5.8°C • Battery: 12.6V Resting",
                ar ? "المعيار: أقل من 8.0 مئوية • البطارية > 12.4 فولت" : "Factory Standard: < 8.0°C • Battery > 12.4V",
                ar ? "فحص الكمبيوتر OBD-II: خلو كامل من أكواد الأعطال (P0000)" : "OBD-II Computer Scan: 0 Fault Codes (P0000 System Normal)",
                ar ? "المقصورة والكهرباء" : "Cabin & Electrical",
                "/report/assets/video/inspection-interior.mp4",
                ar ? "فيديو فحص تشغيل الشاشات والكونسول والتكييف" : "HD Video Proof: Digital cockpit & dual-zone AC cooling test"
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
                null,
                95,
                "95/100",
                ar ? "نقطة تجمد التبريد: -35 مئوية • ضغط التيربو: 1.2 بار" : "Coolant Freeze Point: -35°C • Boost Pressure: 1.2 Bar",
                ar ? "المعيار: -30 مئوية أو أقل • خلو تام من التسريبات" : "Factory OEM: -30°C or colder • 0.0 ppm leaks",
                ar ? "فحص تسريب السوائل: جاف 100% بدون أي تسريب" : "Fluid Spectrometry: 0.0 ppm seepage (Dry Powertrain)",
                ar ? "المحرك ومجموعة الحركة" : "Engine & Powertrain",
                "/report/assets/video/inspection-engine.mp4",
                ar ? "فيديو فحص صوت المحرك وسلاسة الدوران عند سرعة الخمول" : "HD Video Proof: Idle stability & turbo boost pressure check"
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
                ar ? "قطع جدار الإطار 2 مم" : "Bead Gouge: 2mm",
                40,
                "40/100",
                ar ? "عمق قطع الإطار: 2.0 مم • سماكة فحمات الفرامل: 2.1 مم" : "Sidewall Cut: 2.0mm • Brake Pad Thickness: 2.1mm",
                ar ? "الحد الأدنى لسلامة الفحمات: 3.0 مم (الجديد: 10.0 مم)" : "Min Pad Threshold: 3.0mm (New: 10.0mm)",
                ar ? "جهاز قياس السماكة البصري: تآكل حرج في بطانة الاحتكاك" : "Optical Caliper: Critical lining wear & sidewall gouge",
                ar ? "الفرامل والإطارات" : "Brakes & Tyres",
                "/report/assets/video/inspection-brakes-defect.mp4",
                ar ? "فيديو فحص تآكل فحمات الفرامل وقطع جدار الإطار على الرافعة" : "HD Video Proof: Brake caliper lining wear & tire sidewall gouge"
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
                null,
                97,
                "97/100",
                ar ? "استقامة الشاصيه: انحراف 0.0 مم • المساعدات: جافة" : "Chassis Alignment: 0.0mm deviation • Dampers: Dry",
                ar ? "معيار المصنع: تفاوت أقصى ±1.5 مم" : "Factory OEM: Max tolerance ±1.5mm",
                ar ? "جهاز قياس الشاصيه الليزري ثلاثي الأبعاد: استقامة تامة 100%" : "3D Laser Frame Measurement: 100% Factory True",
                ar ? "الشاصيه والتعليق" : "Chassis & Frame",
                "/report/assets/video/inspection-underbody.mp4",
                ar ? "فيديو فحص أرضية المركبة والمساعدات وقضبان الشاصيه" : "HD Video Proof: Underbody frame rails & suspension geometry check"
        ));

        return list;
    }

    private Map<String, Object> createInspectionCard(String id, String zone, String components,
                                                     String status, String statusLabel, String statusClass,
                                                     String imageUrl, String note,
                                                     boolean isDamaged, String damageMarker,
                                                     int score, String scoreText,
                                                     String measuredSpec, String standardSpec,
                                                     String diagnosticSensor, String category,
                                                     String videoUrl, String videoCaption) {
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
        card.put("score", score);
        card.put("scoreText", scoreText);
        card.put("measuredSpec", measuredSpec);
        card.put("standardSpec", standardSpec);
        card.put("diagnosticSensor", diagnosticSensor);
        card.put("category", category);
        card.put("videoUrl", videoUrl);
        card.put("videoCaption", videoCaption);
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

        String impCat = ar ? "العيوب والملاحظات" : "Imperfections";
        String undCat = ar ? "أسفل الهيكل" : "Underbody";

        list.add(createShowcaseItem("sc-imp-01", "imperfections", impCat,
                ar ? "خدش سطحي بقوس العجلة الخلفية يمين" : "Rear Right Wheel Arch Scratch 42mm",
                ar ? "خدش سطحي بطول 42 مم بطبقة اللمعان" : "Superficial 42mm Clearcoat Scratch",
                ar ? "ملاحظة تجميلية • طبقة الأساس سليمة" : "Cosmetic Advisory • Primer Intact",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "خدش سطحي بطول 42 مم في القوس السفلي. لم يصل لطبقة الأساس والصاج سليم تماماً بدون صدمة أو معجون."
                   : "Cosmetic clearcoat scratch 42mm in length on lower curve of wheel arch. Primer intact, zero sheet metal deformation."));

        list.add(createShowcaseItem("sc-imp-02", "imperfections", impCat,
                ar ? "حكة سطحية بجدار الإطار الخلفي يمين" : "Rear Right Tyre Sidewall Curb Scuff",
                ar ? "حكة سطحية خفيفة 2 مم بالشفة الخارجية" : "Superficial 2mm Outer Bead Scuff",
                ar ? "ملاحظة استخدام • لا تؤثر على السلامة" : "Minor Wear • Cord Not Exposed",
                "/report/assets/img/image-1-30f4a447ab.jpg",
                ar ? "حكة رصيف سطحية 2 مم على الحافة الخارجية لجدار الإطار دون وصول لأسلاك التقوية."
                   : "Superficial 2mm curb scuff on outer bead sidewall; reinforcement cord completely unexposed."));

        list.add(createShowcaseItem("sc-imp-03", "imperfections", impCat,
                ar ? "نقطة ترمل دقيقة بالصدام الأمامي" : "Front Bumper Micro Stone Peck (1mm)",
                ar ? "نقطة ترمل دقيقة جداً بالصدام السفلي" : "Micro Stone Peck Lower Air Dam",
                ar ? "استخدام طبيعي • طلاء وكالة" : "Normal Highway Use • OEM Paint",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                ar ? "نقطة ترمل سطحية بحجم 1 مم ناتجة عن القيادة الطبيعية على الطرق السريعة."
                   : "Single 1mm stone peck consistent with normal highway usage; surrounding paint 100% factory true."));

        list.add(createShowcaseItem("sc-und-01", "underbody", undCat,
                ar ? "قضبان الشاصيه وجسور الأمان الأمامية" : "Front Chassis Frame Rails & Subframe",
                ar ? "استقامة ليزرية تامة وخلو كامل من الصدمات" : "Laser Alignment True • Impact Free",
                ar ? "سليم 100% • حالة الوكالة" : "100% Factory True • Sound",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "فحص استقامة الشاصيه الليزري يؤكد انحراف 0.0 مم وتطابق كامل مع معايير المصنع القياسية."
                   : "3D Laser chassis scan confirms 0.0mm deviation and full compliance with OEM tolerances."));

        list.add(createShowcaseItem("sc-und-02", "underbody", undCat,
                ar ? "منظومة العادم ودبابات البيئة" : "Catalytic Converters & Exhaust Heat Shields",
                ar ? "دبابات التلوث الأصلية وسليمة بدون أي تلحيم" : "Original OEM Catalysts & Heat Shields",
                ar ? "سليمة تماماً • بدون تعديل" : "Pristine • Untouched",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "كافة أجزاء العادم وعلب البيئة مثبتة ببراغيها الأصلية وخالية من الصدأ أو التسريب."
                   : "Full exhaust system with original factory catalytic converters, heat shields, and oxygen sensors."));

        list.add(createShowcaseItem("sc-und-03", "underbody", undCat,
                ar ? "صفائح الحماية السفلية وخزان الوقود" : "Underbody Skid Plates & Fuel Tank Protection",
                ar ? "أغطية حماية سفلية كاملة وخزان نظيف" : "Heavy-Duty Underbody Protection Covers",
                ar ? "مثبتة بالكامل • حالة ممتازة" : "Securely Mounted • Excellent",
                "/report/assets/img/image-2-48b6858055.jpg",
                ar ? "صفائح الحماية البلاستيكية والمعدنية مثبتة بمشابك المصنع وتغطي المحرك والقير بالكامل."
                   : "Underbody aerodynamic and protective shields securely mounted with zero scrape damage."));

        return list;
    }

    private String diagnosticMetricForCode(String code, String resultCode, boolean ar) {
        if (code == null) code = "";
        String lower = code.toLowerCase();
        if (lower.contains("tyre") || lower.contains("tire") || lower.contains("wheel")) {
            if ("DEFECT_FOUND".equals(resultCode) || "ATTENTION_RECOMMENDED".equals(resultCode)) {
                return ar ? "عمق المداس: 7.1 مم • ملاحظة احتكاك سطحي 2 مم" : "Tread: 7.1mm • 2mm Sidewall Curb Scuff";
            }
            return ar ? "عمق المداس: 7.2 مم • الضغط: 33 PSI" : "Tread: 7.2mm • Pressure: 33 PSI";
        }
        if (lower.contains("brake") || lower.contains("disc") || lower.contains("pad")) {
            return ar ? "سماكة الفحمات: 8.5 مم • الديسكات سليمة" : "Pads: 8.5mm • Rotors: OEM Spec";
        }
        if (lower.contains("engine") || lower.contains("motor") || lower.contains("oil")) {
            return ar ? "ضغط الزيت: 42 PSI • خلو كامل من التسريب" : "Oil Pressure: 42 PSI • Zero Leaks";
        }
        if (lower.contains("battery") || lower.contains("elect") || lower.contains("volt")) {
            return ar ? "الجهد الساكن: 12.6 فولت • الدينامو: 14.2 فولت" : "Static: 12.6V • Alternator: 14.2V";
        }
        if (lower.contains("suspension") || lower.contains("shock") || lower.contains("strut")) {
            return ar ? "الاستجابة الهيدروليكية: 100% • خلو الفراغ" : "Hydraulic Damping: 100% • Zero Play";
        }
        if (lower.contains("chassis") || lower.contains("frame") || lower.contains("body")) {
            return ar ? "استقامة الشاصيه: 0.0 مم انحراف" : "Chassis Alignment: 0.0mm Deviation";
        }
        return ar ? "مطابق لمواصفات المصنع القياسية" : "Factory Spec Compliant";
    }

    private String standardSpecForCode(String code, boolean ar) {
        if (code == null) code = "";
        String lower = code.toLowerCase();
        if (lower.contains("tyre") || lower.contains("tire")) {
            return ar ? "الحد الأدنى: 3.0 مم • الضغط 32-35 PSI" : "Min: 3.0mm • 32-35 PSI Nominal";
        }
        if (lower.contains("brake")) {
            return ar ? "الحد الأدنى: 3.0 مم للفحمات" : "Min: 3.0mm Friction Thickness";
        }
        if (lower.contains("battery")) {
            return ar ? "الحد الأدنى للجهد: 12.2 فولت" : "Min Voltage: 12.2V";
        }
        return ar ? "المعيار: مطابقة تامة لكتالوج المصنع" : "Standard: 100% OEM Tolerance";
    }

    private String partPhotoForCode(String code) {
        if (code == null) code = "";
        String lower = code.toLowerCase();
        if (lower.contains("tyre") || lower.contains("tire") || lower.contains("wheel")) {
            return "/report/assets/img/image-1-30f4a447ab.jpg";
        }
        if (lower.contains("engine") || lower.contains("oil") || lower.contains("coolant")) {
            return "/report/assets/img/image-2-e9a5952732.jpg";
        }
        if (lower.contains("suspension") || lower.contains("chassis") || lower.contains("frame") || lower.contains("underbody")) {
            return "/report/assets/img/image-2-48b6858055.jpg";
        }
        if (lower.contains("interior") || lower.contains("cabin") || lower.contains("seat") || lower.contains("dash")) {
            return "/report/assets/img/image-1-96fe1d6167.jpg";
        }
        return "/report/assets/img/image-1-0c99e38fa3.jpg";
    }

    private List<Map<String, Object>> tyreAssemblies(String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        Map<String, Object> fl = new LinkedHashMap<>();
        fl.put("id", "tyre-fl");
        fl.put("posCode", "FL");
        fl.put("position", ar ? "الأمامية يسار" : "Front Left");
        fl.put("title", ar ? "الإطار والمكابح الأمامية يسار" : "Front Left Wheel & Brake");
        fl.put("category", ar ? "المكابح والإطارات" : "Brakes & Tyres");
        fl.put("status", "PASSED");
        fl.put("statusLabel", ar ? "سليم" : "Passed");
        fl.put("statusClass", "badge-pass");
        fl.put("score", 96);
        fl.put("scoreText", "96/100");
        fl.put("treadDepth", "6.2 mm");
        fl.put("pressure", "34 PSI");
        fl.put("brakePad", "7.5 mm");
        fl.put("measuredSpec", ar ? "عمق المداس: 6.2 مم • الضغط: 34 PSI • سماكة الفحمات: 7.5 مم"
                                  : "Tread: 6.2mm • Pressure: 34 PSI • Brake Pad: 7.5mm");
        fl.put("standardSpec", ar ? "الحد الأدنى للمداس: 3.0 مم • الضغط الموصى به: 34 PSI • فحمات: 3.0 مم"
                                  : "Min Tread: 3.0mm • Rec Pressure: 34 PSI • Min Pad: 3.0mm");
        fl.put("diagnosticSensor", ar ? "جهاز قياس رقمي دقيق لعمق المداس وسماكة الفحمات"
                                      : "Digital Laser Depth Gauge & Micrometer");
        fl.put("technicianNote", ar ? "إطار ميشلان بايلوت سبورت 4S بحالة ممتازة وتآكل متساوي منتظم. سطح الهوب ناعم بدون حزوز، ومكابس الكليبر تعمل بسلاسة تامة."
                                    : "Michelin Pilot Sport 4S in excellent condition with even tread wear. Brake rotor face smooth, caliper slide pins responsive and clean.");
        fl.put("imageUrl", "/report/assets/img/image-1-30f4a447ab.jpg");
        fl.put("videoUrl", "/report/assets/video/inspection-brakes.mp4");
        fl.put("videoCaption", ar ? "فيديو فحص سماكة الفحمات وعمق مداس الإطار بمقياس رقمي"
                                  : "HD Video Proof: Digital micrometer tread & brake caliper inspection");
        list.add(fl);

        Map<String, Object> fr = new LinkedHashMap<>();
        fr.put("id", "tyre-fr");
        fr.put("posCode", "FR");
        fr.put("position", ar ? "الأمامية يمين" : "Front Right");
        fr.put("title", ar ? "الإطار والمكابح الأمامية يمين" : "Front Right Wheel & Brake");
        fr.put("category", ar ? "المكابح والإطارات" : "Brakes & Tyres");
        fr.put("status", "PASSED");
        fr.put("statusLabel", ar ? "سليم" : "Passed");
        fr.put("statusClass", "badge-pass");
        fr.put("score", 95);
        fr.put("scoreText", "95/100");
        fr.put("treadDepth", "6.1 mm");
        fr.put("pressure", "34 PSI");
        fr.put("brakePad", "7.2 mm");
        fr.put("measuredSpec", ar ? "عمق المداس: 6.1 مم • الضغط: 34 PSI • سماكة الفحمات: 7.2 مم"
                                  : "Tread: 6.1mm • Pressure: 34 PSI • Brake Pad: 7.2mm");
        fr.put("standardSpec", ar ? "الحد الأدنى للمداس: 3.0 مم • الضغط الموصى به: 34 PSI • فحمات: 3.0 مم"
                                  : "Min Tread: 3.0mm • Rec Pressure: 34 PSI • Min Pad: 3.0mm");
        fr.put("diagnosticSensor", ar ? "جهاز قياس رقمي دقيق لعمق المداس وسماكة الفحمات"
                                      : "Digital Laser Depth Gauge & Micrometer");
        fr.put("technicianNote", ar ? "تآكل مداس متوازن، سلامة الهيكل الجانبي للإطار من الانتفاخات أو الشقوق. أداء هيدروليكي ممتاز لمنظومة الفرملة."
                                    : "Even tread wear pattern across full tyre width. Sidewall intact without bulges or cuts. Hydraulic brake pressure within spec.");
        fr.put("imageUrl", "/report/assets/img/image-1-0c99e38fa3.jpg");
        fr.put("videoUrl", "/report/assets/video/inspection-brakes.mp4");
        fr.put("videoCaption", ar ? "فيديو فحص سماكة الفحمات وعمق مداس الإطار بمقياس رقمي"
                                  : "HD Video Proof: Digital micrometer tread & brake caliper inspection");
        list.add(fr);

        Map<String, Object> rl = new LinkedHashMap<>();
        rl.put("id", "tyre-rl");
        rl.put("posCode", "RL");
        rl.put("position", ar ? "الخلفية يسار" : "Rear Left");
        rl.put("title", ar ? "الإطار والمكابح الخلفية يسار" : "Rear Left Wheel & Brake");
        rl.put("category", ar ? "المكابح والإطارات" : "Brakes & Tyres");
        rl.put("status", "PASSED");
        rl.put("statusLabel", ar ? "سليم" : "Passed");
        rl.put("statusClass", "badge-pass");
        rl.put("score", 96);
        rl.put("scoreText", "96/100");
        rl.put("treadDepth", "6.4 mm");
        rl.put("pressure", "35 PSI");
        rl.put("brakePad", "7.6 mm");
        rl.put("measuredSpec", ar ? "عمق المداس: 6.4 مم • الضغط: 35 PSI • سماكة الفحمات: 7.6 مم"
                                  : "Tread: 6.4mm • Pressure: 35 PSI • Brake Pad: 7.6mm");
        rl.put("standardSpec", ar ? "الحد الأدنى للمداس: 3.0 مم • الضغط الموصى به: 35 PSI • فحمات: 3.0 مم"
                                  : "Min Tread: 3.0mm • Rec Pressure: 35 PSI • Min Pad: 3.0mm");
        rl.put("diagnosticSensor", ar ? "جهاز قياس رقمي دقيق لعمق المداس وسماكة الفحمات"
                                      : "Digital Laser Depth Gauge & Micrometer");
        rl.put("technicianNote", ar ? "سماكة الفحمات مطابقة للمواصفات الممتازة. هوب الفرامل متجانس وخالي من التموجات، ونظام الجلنط الإلكتروني يستجيب فوراً."
                                    : "Brake pad thickness well above minimum safe limits. Rotor surface flat and true, electronic parking brake actuator holds firm.");
        rl.put("imageUrl", "/report/assets/img/image-1-30f4a447ab.jpg");
        rl.put("videoUrl", "/report/assets/video/inspection-brakes.mp4");
        rl.put("videoCaption", ar ? "فيديو فحص سماكة الفحمات وعمق مداس الإطار بمقياس رقمي"
                                  : "HD Video Proof: Digital micrometer tread & brake caliper inspection");
        list.add(rl);

        Map<String, Object> rr = new LinkedHashMap<>();
        rr.put("id", "tyre-rr");
        rr.put("posCode", "RR");
        rr.put("position", ar ? "الخلفية يمين" : "Rear Right");
        rr.put("title", ar ? "الإطار والمكابح الخلفية يمين" : "Rear Right Wheel & Brake");
        rr.put("category", ar ? "المكابح والإطارات" : "Brakes & Tyres");
        rr.put("status", "ATTENTION");
        rr.put("statusLabel", ar ? "يتطلب صيانة" : "Needs Service");
        rr.put("statusClass", "badge-attention");
        rr.put("score", 76);
        rr.put("scoreText", "76/100");
        rr.put("treadDepth", "5.8 mm");
        rr.put("pressure", "35 PSI");
        rr.put("brakePad", "3.1 mm");
        rr.put("measuredSpec", ar ? "عمق المداس: 5.8 مم • الضغط: 35 PSI • سماكة الفحمات: 3.1 مم (مستهلكة)"
                                  : "Tread: 5.8mm • Pressure: 35 PSI • Brake Pad: 3.1mm (Worn)");
        rr.put("standardSpec", ar ? "الحد الأدنى للسلامة: 3.0 مم • استبدال موصى به قبل 2,000 كم"
                                  : "Safety Minimum: 3.0mm • Replacement advised within 2,000 km");
        rr.put("diagnosticSensor", ar ? "جهاز قياس رقمي دقيق لعمق المداس وسماكة الفحمات"
                                      : "Digital Laser Depth Gauge & Micrometer");
        rr.put("technicianNote", ar ? "سماكة فحمات الفرامل الخلفية يمين انخفضت إلى 3.1 مم واقتربت من الحد الأدنى الحرج (3.0 مم). يوصى باستبدال فحمات المحور الخلفي خلال 2,000 كم."
                                    : "Rear right brake pad has worn to 3.1mm, approaching the 3.0mm critical service limit. Recommend rear axle pad replacement within 2,000 km.");
        rr.put("imageUrl", "/report/assets/img/image-1-30f4a447ab.jpg");
        rr.put("videoUrl", "/report/assets/video/inspection-brakes.mp4");
        rr.put("videoCaption", ar ? "فيديو فحص سماكة الفحمات وعمق مداس الإطار بمقياس رقمي"
                                  : "HD Video Proof: Digital micrometer tread & brake caliper inspection");
        list.add(rr);

        return list;
    }

    private List<Map<String, Object>> damageZones(String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        list.add(createDamageZone(
                "front-bumper",
                "FB",
                ar ? "الصدام الأمامي والشبك" : "Front Bumper & Grille",
                false,
                "PASSED",
                ar ? "حالة المصنع الأصلية" : "Original Factory Condition",
                "badge-pass",
                "115 µm",
                ar ? "سماكة طلاء المصنع مؤكدة (112-118 ميكرون). خالي من الخدوش أو الترمل أو رشات الصبغ."
                   : "Original factory paint thickness verified (112-118 µm). Zero stone chips, scratches or repaints.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                null,
                null
        ));

        list.add(createDamageZone(
                "hood",
                "HD",
                ar ? "غطاء المحرك (الكبوت)" : "Hood (Bonnet)",
                false,
                "PASSED",
                ar ? "حالة المصنع الأصلية" : "Original Factory Condition",
                "badge-pass",
                "118 µm",
                ar ? "سماكة الطلاء 118 ميكرون متطابقة تماماً مع المصنع. مسامير التثبيت الأصلية لم تفك وخالي من التعديل."
                   : "Factory paint depth 118 µm. Uniform reflection, original seam sealant along edges, bolts untooled.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                null,
                null
        ));

        list.add(createDamageZone(
                "windshield-roof",
                "RF",
                ar ? "السقف والزجاج الأمامي" : "Roof & Windshield Glass",
                false,
                "PASSED",
                ar ? "حالة المصنع الأصلية" : "Original Factory Condition",
                "badge-pass",
                "110 µm",
                ar ? "زجاج وكالة أصلي مدموغ بشعار الشركة. سقف خالي من ضربات البرد أو بهتان طبقة اللمعان."
                   : "Original OEM stamped glass. Roof panel free of hail dents, sun fading or clearcoat oxidation.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                null,
                null
        ));

        list.add(createDamageZone(
                "left-profile",
                "LS",
                ar ? "الأبواب والرفارف الجانبية يسار" : "Left Profile (Doors & Fender)",
                false,
                "PASSED",
                ar ? "حالة المصنع الأصلية" : "Original Factory Condition",
                "badge-pass",
                "114 µm",
                ar ? "الأبواب والرفرف الأيسر متناسقة بالكامل بسماكة 110-118 ميكرون. فواصل الأبواب متناسقة بالمليمتر."
                   : "Both left doors and front fender show consistent paint depth (110-118 µm). Perfect panel gap alignment.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                null,
                null
        ));

        list.add(createDamageZone(
                "right-profile",
                "RS",
                ar ? "الباب والرفرف الأمامي يمين" : "Right Front Door & Fender",
                false,
                "PASSED",
                ar ? "حالة المصنع الأصلية" : "Original Factory Condition",
                "badge-pass",
                "116 µm",
                ar ? "باب الراكب والرفرف الأمامي الأيمن بحالة الوكالة. خالي من أي رش تجميلي أو تعديل."
                   : "Front passenger door and right front fender in original factory state. No signs of blending or respray.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                null,
                null
        ));

        list.add(createDamageZone(
                "rear-right-arch",
                "RR-ARCH",
                ar ? "الرفرف الخلفي الأيمن / قوس العجلة" : "Rear Right Quarter Panel / Arch",
                true,
                "DEFECT_FOUND",
                ar ? "خدش سطحي: 42 مم" : "Cosmetic Scratch: 42mm",
                "badge-defect",
                "116 µm (OEM)",
                ar ? "خدش سطحي تجميلي بطول 42 مم في القوس السفلي. لم يصل لطبقة الأساس والصاج سليم تماماً بدون صدمة أو معجون."
                   : "Cosmetic clearcoat scratch 42mm in length on lower curve of wheel arch. Primer intact, zero sheet metal deformation. Paint is 100% factory original.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                "/report/assets/video/inspection-scratch.mp4",
                ar ? "فيديو مقرب 4K: قياس عمق الخدش وفحص جهاز قياس سماكة الطلاء"
                   : "Macro 4K Video: 42mm scratch depth & paint gauge inspection"
        ));

        list.add(createDamageZone(
                "rear-tailgate",
                "RB",
                ar ? "الشنطة والصدام الخلفي" : "Rear Tailgate & Bumper",
                false,
                "PASSED",
                ar ? "حالة المصنع الأصلية" : "Original Factory Condition",
                "badge-pass",
                "115 µm",
                ar ? "حساسات الصدام الخلفي سليمة، كاميرا الرجوع نقية، ومساعدات فتح الشنطة الكهربائية تعمل بسلاسة."
                   : "Rear bumper sensors intact, reverse camera crystal clear, tailgate latch & electronic struts smooth.",
                "/report/assets/img/image-1-0c99e38fa3.jpg",
                null,
                null
        ));

        return list;
    }

    private Map<String, Object> createDamageZone(String id, String code, String title, boolean isDamaged,
                                                 String status, String statusLabel, String statusClass,
                                                 String paintThickness, String note, String imageUrl,
                                                 String videoUrl, String videoCaption) {
        Map<String, Object> zone = new LinkedHashMap<>();
        zone.put("id", id);
        zone.put("code", code);
        zone.put("title", title);
        zone.put("isDamaged", isDamaged);
        zone.put("status", status);
        zone.put("statusLabel", statusLabel);
        zone.put("statusClass", statusClass);
        zone.put("paintThickness", paintThickness);
        zone.put("note", note);
        zone.put("imageUrl", imageUrl);
        zone.put("videoUrl", videoUrl);
        zone.put("videoCaption", videoCaption);
        return zone;
    }

    private List<Map<String, Object>> inspectorSummary(String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("category", "body");
        body.put("title", ar ? "الهيكل والطلاء الخارجي" : "Body & Paint");
        body.put("icon", "🚗");
        body.put("status", "ATTENTION");
        body.put("statusLabel", ar ? "ملاحظة تجميلية" : "Cosmetic Advisory");
        body.put("statusClass", "badge-warning");
        body.put("dotClass", "dot-warning");
        body.put("points", List.of(
                ar ? "تم رصد خدش سطحي تجميلي بطول 42 مم في قوس العجلة الخلفية يمين (طبقة اللمعان الشفافة)."
                   : "Cosmetic clearcoat scratch 42mm noted on lower rear right wheel arch.",
                ar ? "تم فحص كافة أجزاء وهيكل المركبة بجهاز قياس الطلاء، والنتائج تؤكد طلاء المصنع الأصلي بسماكة 110-118 ميكرون بدون أي سمكرة أو رشات."
                   : "All remaining exterior body panels verified in 100% factory original OEM paint (110-118 µm) with zero body filler or repainting."
        ));
        list.add(body);

        Map<String, Object> powertrain = new LinkedHashMap<>();
        powertrain.put("category", "powertrain");
        powertrain.put("title", ar ? "المحرك ومجموعة الحركة" : "Engine & Powertrain");
        powertrain.put("icon", "⚙️");
        powertrain.put("status", "PASSED");
        powertrain.put("statusLabel", ar ? "سليم وممتاز" : "Pristine Condition");
        powertrain.put("statusClass", "badge-pass");
        powertrain.put("dotClass", "dot-pass");
        powertrain.put("points", List.of(
                ar ? "المحرك يعمل بنعومة وهدوء فائقين دون أي اهتزاز غير طبيعي أو تكتكة."
                   : "Engine idle is smooth and whisper-quiet with zero abnormal vibration or timing noise.",
                ar ? "مستوى ولزوجة زيت المحرك ممتازة، سائل التبريد نظيف، ولا توجد أي ترشيحات أو تسريب زيوت."
                   : "Oil viscosity and level nominal, coolant crystal-clear, zero weeping or fluid leakage.",
                ar ? "ناقل الحركة يبدل بسلاسة تامة، وبطارية الهايبرد تعمل بكفاءة شحن كاملة 100%."
                   : "Transmission shifts seamlessly through all ratios; high-voltage hybrid battery at 100% health."
        ));
        list.add(powertrain);

        Map<String, Object> brakes = new LinkedHashMap<>();
        brakes.put("category", "brakes");
        brakes.put("title", ar ? "المكابح والإطارات والتعليق" : "Brakes, Tyres & Suspension");
        brakes.put("icon", "🛞");
        brakes.put("status", "ATTENTION");
        brakes.put("statusLabel", ar ? "يتطلب صيانة دورية" : "Service Recommended");
        brakes.put("statusClass", "badge-warning");
        brakes.put("dotClass", "dot-warning");
        brakes.put("points", List.of(
                ar ? "فحمات الفرامل الأمامية بنسبة 80%، فحمات الفرامل الخلفية يمين بسماكة 3.1 مم ويوصى باستبدالها خلال 2,000 كم."
                   : "Front brake pads at 80% life; rear right brake pad worn to 3.1mm (replacement advised within 2,000 km).",
                ar ? "الإطارات الأربعة ميشلان بحالة جيدة مع عمق مداس 6.0 مم وضغط هواء 34-35 PSI متطابق."
                   : "All 4 Michelin tyres in sound condition with 6.0mm average tread depth and uniform 34-35 PSI.",
                ar ? "المساعدات الهيدروليكية جافة بالكامل وخالية من التهريب، ونظام التوجيه دقيق ومحكم."
                   : "Shock absorbers bone-dry with zero hydraulic seepage; steering rack firm and play-free."
        ));
        list.add(brakes);

        Map<String, Object> obd = new LinkedHashMap<>();
        obd.put("category", "obd");
        obd.put("title", ar ? "الفحص الكمبيوتري والكهرباء (OBD-II)" : "OBD-II Computer Diagnostic");
        obd.put("icon", "💻");
        obd.put("status", "PASSED");
        obd.put("statusLabel", ar ? "خالٍ من الأعطال 100%" : "Zero Fault Codes");
        obd.put("statusClass", "badge-pass");
        obd.put("dotClass", "dot-pass");
        obd.put("points", List.of(
                ar ? "مسح شامل لكافة أنظمة وكمبيوترات المركبة (ECU, TCU, ABS, Airbag, BCM) بدون أي كود عطل مسجل."
                   : "Full digital scanner scan across ECU, TCU, ABS, Airbag, and BCM modules: 0 DTC fault codes stored.",
                ar ? "كافة الحساسات وأنظمة مراقبة المحرك والانبعاثات في حالة جاهزية كاملة 100%."
                   : "All emissions readiness monitors and powertrain safety sensors operating at 100% compliance.",
                ar ? "شحن الدينامو 14.2 فولت وجهد البطارية 12.6 فولت ضمن المعايير المثالية."
                   : "Alternator charging at 14.2V and 12V auxiliary battery testing healthy at 12.6V."
        ));
        list.add(obd);

        return list;
    }

    private List<Map<String, Object>> inspectionVideos(String language) {
        boolean ar = "ar".equals(language);
        List<Map<String, Object>> list = new ArrayList<>();

        Map<String, Object> v1 = new LinkedHashMap<>();
        v1.put("id", "vid-scratch");
        v1.put("title", ar ? "فيديو مقرب 4K: فحص الخدش السطحي وسماكة الطلاء" : "Macro 4K Video: 42mm Scratch & Paint Gauge Verification");
        v1.put("category", ar ? "الهيكل والطلاء" : "Body & Paint");
        v1.put("duration", "0:15");
        v1.put("videoUrl", "/report/assets/video/inspection-scratch.mp4");
        v1.put("thumbnailUrl", "/report/assets/img/image-1-0c99e38fa3.jpg");
        v1.put("caption", ar ? "توثيق ميكروسكوبي لقياس عمق الخدش وتأكيد سلامة طبقة الأساس والصاج الأصلي"
                             : "Certified macro video measuring scratch depth and confirming original clearcoat integrity.");
        list.add(v1);

        Map<String, Object> v2 = new LinkedHashMap<>();
        v2.put("id", "vid-brakes");
        v2.put("title", ar ? "فيديو فحص منظومة المكابح وعمق مداس الإطارات" : "HD Video Proof: Brake Calipers & Digital Tread Depth Gauge");
        v2.put("category", ar ? "المكابح والإطارات" : "Brakes & Tyres");
        v2.put("duration", "0:18");
        v2.put("videoUrl", "/report/assets/video/inspection-brakes.mp4");
        v2.put("thumbnailUrl", "/report/assets/img/image-1-30f4a447ab.jpg");
        v2.put("caption", ar ? "فحص ديجيتال دقيق لسماكة فحمات الفرامل وعمق مداس الإطارات الأربعة بميكرومتر ليزري"
                             : "Digital micrometer verification of brake pad wear and four-wheel tread depth readings.");
        list.add(v2);

        Map<String, Object> v3 = new LinkedHashMap<>();
        v3.put("id", "vid-underbody");
        v3.put("title", ar ? "فيديو استقامة الشاصي وأسفل الهيكل" : "HD Video Proof: Underbody Frame Rails & Suspension Check");
        v3.put("category", ar ? "الشاصيه والتعليق" : "Chassis & Frame");
        v3.put("duration", "0:22");
        v3.put("videoUrl", "/report/assets/video/inspection-underbody.mp4");
        v3.put("thumbnailUrl", "/report/assets/img/image-2-48b6858055.jpg");
        v3.put("caption", ar ? "فحص كامل لأرضية المركبة وقضبان الشاصيه وجلب المساعدات الهيدروليكية"
                             : "Comprehensive underbody inspection verifying straight chassis rails and dry hydraulic dampers.");
        list.add(v3);

        return list;
    }
}
