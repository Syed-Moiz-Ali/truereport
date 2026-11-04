package com.truereport.reports;

public interface PdfRenderer {
    byte[] render(String html);
}
