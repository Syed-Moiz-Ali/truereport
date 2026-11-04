package com.truereport.reports;

import com.truereport.shared.storage.ObjectStorage;
import org.springframework.stereotype.Service;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ReportPdfService {

    private final SpringTemplateEngine templateEngine;
    private final ReportViewMapper viewMapper;
    private final ReportFonts fonts;
    private final PdfRenderer renderer;
    private final ObjectStorage storage;

    public ReportPdfService(SpringTemplateEngine templateEngine, ReportViewMapper viewMapper,
                            ReportFonts fonts, PdfRenderer renderer, ObjectStorage storage) {
        this.templateEngine = templateEngine;
        this.viewMapper = viewMapper;
        this.fonts = fonts;
        this.renderer = renderer;
        this.storage = storage;
    }

    public byte[] render(ReportVersion version, List<EvidenceDerivative> derivatives) throws Exception {
        Map<String, Object> root = viewMapper.printPage(version, derivatives);
        Map<UUID, EvidenceDerivative> byId = new LinkedHashMap<>();
        for (EvidenceDerivative derivative : derivatives) {
            if (derivative.getPurpose().equals("PUBLIC_FULL")) {
                byId.put(derivative.getId(), derivative);
            }
        }
        addDataUris((List<Map<String, Object>>) root.get("keyFindings"), byId);
        for (Object rawCategory : (List<?>) root.get("categories")) {
            Map<String, Object> category = (Map<String, Object>) rawCategory;
            addDataUris((List<Map<String, Object>>) category.get("items"), byId);
        }
        root.put("fontCss", fonts.fontCss());
        Context context = new Context();
        context.setVariable("r", root);
        String html = templateEngine.process("report/print-report", context);
        return renderer.render(html);
    }

    private void addDataUris(List<Map<String, Object>> items, Map<UUID, EvidenceDerivative> byId) {
        if (items == null) {
            return;
        }
        for (Map<String, Object> item : items) {
            List<Map<String, Object>> photos = (List<Map<String, Object>>) item.get("photos");
            if (photos == null) {
                continue;
            }
            for (Map<String, Object> photo : photos) {
                UUID id = (UUID) photo.get("id");
                EvidenceDerivative derivative = byId.get(id);
                if (derivative == null) {
                    continue;
                }
                byte[] bytes = storage.get(derivative.getStorageKey());
                photo.put("dataUri", "data:" + derivative.getMime() + ";base64,"
                        + Base64.getEncoder().encodeToString(bytes));
            }
        }
    }
}
