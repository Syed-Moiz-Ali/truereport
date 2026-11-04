package com.truereport.reports;

import java.util.LinkedHashMap;
import java.util.Map;

public final class ReportMessages {

    private ReportMessages() {
    }

    public static Map<String, Object> labels(String language) {
        boolean ar = "ar".equals(language);
        Map<String, Object> labels = new LinkedHashMap<>();
        labels.put("title", ar ? "تقرير فحص مركبة" : "Vehicle inspection report");
        labels.put("neutralDescription", ar
                ? "يتوفر تقرير فحص مركبة على هذا الرابط."
                : "A vehicle inspection report is available at this link.");
        labels.put("summary", ar ? "ملخص الفحص" : "Inspection summary");
        labels.put("coverage", ar ? "التغطية" : "Coverage");
        labels.put("completed", ar ? "مكتمل" : "completed");
        labels.put("applicable", ar ? "قابل للتطبيق" : "applicable");
        labels.put("checksCompleted", ar ? "فحوصات مكتملة" : "checks completed");
        labels.put("coverageNotScore", ar
                ? "التغطية ليست تقييماً لحالة المركبة."
                : "Coverage is not a condition score.");
        labels.put("keyFindings", ar ? "أهم الملاحظات" : "Key findings");
        labels.put("noKeyFindings", ar
                ? "لم تُسجل ملاحظات أمان أو عيوب في هذا الفحص."
                : "No safety-critical or defect findings were recorded in this inspection.");
        labels.put("vehicle", ar ? "المركبة" : "Vehicle");
        labels.put("inspection", ar ? "الفحص" : "Inspection");
        labels.put("workshop", ar ? "الورشة" : "Workshop");
        labels.put("technician", ar ? "الفني" : "Technician");
        labels.put("reportId", ar ? "معرّف التقرير" : "Report ID");
        labels.put("version", ar ? "الإصدار" : "Version");
        labels.put("finalized", ar ? "تاريخ الاعتماد" : "Finalized");
        labels.put("published", ar ? "تاريخ النشر" : "Published");
        labels.put("scope", ar ? "نطاق الفحص" : "Inspection scope");
        labels.put("template", ar ? "إصدار القالب" : "Template version");
        labels.put("odometer", ar ? "عداد المسافة" : "Odometer");
        labels.put("findings", ar ? "الملاحظات حسب الفئة" : "Findings by category");
        labels.put("category", ar ? "الفئة" : "Category");
        labels.put("result", ar ? "النتيجة" : "Result");
        labels.put("severity", ar ? "الخطورة" : "Severity");
        labels.put("note", ar ? "ملاحظة الفني" : "Technician note");
        labels.put("reason", ar ? "السبب" : "Reason");
        labels.put("notChecked", ar ? "فحوصات لم تكتمل" : "Checks not completed");
        labels.put("couldNotVerify", ar ? "تعذر التحقق" : "Could not verify");
        labels.put("limitations", ar ? "الحدود وإخلاء المسؤولية" : "Limitations and disclaimer");
        labels.put("photos", ar ? "صور الأدلة" : "Evidence photos");
        labels.put("noPhotos", ar ? "لا توجد صور أدلة منشورة." : "No public evidence photos.");
        labels.put("reportHash", ar ? "بصمة التقرير" : "Report integrity hash");
        labels.put("downloadPdf", ar ? "تنزيل PDF" : "Download PDF");
        labels.put("language", ar ? "اللغة" : "Language");
        labels.put("english", ar ? "الإنجليزية" : "English");
        labels.put("arabic", ar ? "العربية" : "Arabic");
        labels.put("notCertified", ar
                ? "هذا التقرير ليس شهادة رسمية أو ضماناً أو موافقة جهة خارجية."
                : "This report is not an official certificate, warranty or independent approval.");
        labels.put("evidenceCaption", ar ? "دليل" : "Evidence");
        labels.put("originalNote", ar ? "النص الأصلي" : "Original text");
        labels.put("noTranslation", ar
                ? "لم تُقدَّم ترجمة منفصلة لهذه الملاحظة."
                : "No separate translation was supplied for this note.");
        labels.put("reportDetails", ar ? "تفاصيل التقرير" : "Report details");
        labels.put("page", ar ? "صفحة" : "Page");
        labels.put("unavailableTitle", ar ? "الرابط غير متاح" : "This link is unavailable");
        labels.put("unavailableBody", ar
                ? "لا يمكن عرض التقرير من هذا الرابط."
                : "This report cannot be displayed from this link.");
        labels.put("temporaryTitle", ar ? "الخدمة غير متاحة مؤقتاً" : "Temporarily unavailable");
        labels.put("temporaryBody", ar
                ? "يرجى المحاولة مرة أخرى لاحقاً."
                : "Please try again later.");
        labels.put("revocationNotice", ar
                ? "إلغاء الرابط يمنع الوصول المستقبلي، لكنه لا يستطيع استرجاع نسخ أو صور أو ملفات PDF تم تنزيلها."
                : "Revocation stops future server access, but cannot recall copies, screenshots or PDFs already downloaded.");
        return labels;
    }

    public static String result(String language, String code) {
        boolean ar = "ar".equals(language);
        return switch (code) {
            case "NO_ISSUE_OBSERVED" -> ar ? "لا توجد ملاحظة" : "No issue observed";
            case "ATTENTION_RECOMMENDED" -> ar ? "يُنصح بالانتباه" : "Attention recommended";
            case "DEFECT_FOUND" -> ar ? "تم اكتشاف عيب" : "Defect found";
            case "NOT_CHECKED" -> ar ? "لم يتم الفحص" : "Not checked";
            case "NOT_APPLICABLE" -> ar ? "لا ينطبق" : "Not applicable";
            case "COULD_NOT_VERIFY" -> ar ? "تعذر التحقق" : "Could not verify";
            default -> code;
        };
    }

    public static String severity(String language, String code) {
        boolean ar = "ar".equals(language);
        return switch (code) {
            case "MINOR" -> ar ? "طفيف" : "Minor";
            case "MODERATE" -> ar ? "متوسط" : "Moderate";
            case "MAJOR" -> ar ? "جسيم" : "Major";
            case "SAFETY_CRITICAL" -> ar ? "حرج للسلامة" : "Safety-critical";
            default -> "";
        };
    }
}
