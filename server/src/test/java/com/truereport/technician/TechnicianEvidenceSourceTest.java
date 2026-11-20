package com.truereport.technician;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class TechnicianEvidenceSourceTest {

    @Test
    void cameraIsAlwaysAcceptedForPhotoAndVideo() {
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "CAMERA", true))
                .isNull();
        assertThat(TechnicianInspectionService.captureSourceError("VIDEO", "CAMERA", false))
                .isNull();
    }

    @Test
    void fileAndImportAreAcceptedWhenThePolicyAllowsFileSources() {
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "FILE", true))
                .isNull();
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "IMPORT", true))
                .isNull();
        assertThat(TechnicianInspectionService.captureSourceError("VIDEO", "FILE", true))
                .isNull();
        assertThat(TechnicianInspectionService.captureSourceError("VIDEO", "IMPORT", true))
                .isNull();
    }

    @Test
    void fileAndImportRequireCameraWhenThePolicyIsOff() {
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "FILE", false))
                .isEqualTo("CAMERA_REQUIRED");
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "IMPORT", false))
                .isEqualTo("CAMERA_REQUIRED");
        assertThat(TechnicianInspectionService.captureSourceError("VIDEO", "FILE", false))
                .isEqualTo("CAMERA_REQUIRED");
        assertThat(TechnicianInspectionService.captureSourceError("VIDEO", "IMPORT", false))
                .isEqualTo("CAMERA_REQUIRED");
    }

    @Test
    void anythingElseIsInvalid() {
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "SCANNER", true))
                .isEqualTo("SOURCE_INVALID");
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "BLUETOOTH", true))
                .isEqualTo("SOURCE_INVALID");
        assertThat(TechnicianInspectionService.captureSourceError("PHOTO", "", true))
                .isEqualTo("SOURCE_INVALID");
        assertThat(TechnicianInspectionService.captureSourceError("VIDEO", "SCANNER", false))
                .isEqualTo("SOURCE_INVALID");
    }

    @Test
    void documentsKeepTheirExistingScannerSource() {
        assertThat(TechnicianInspectionService.captureSourceError("DOCUMENT", "SCANNER", false))
                .isNull();
        assertThat(TechnicianInspectionService.captureSourceError("DOCUMENT", "FILE", false))
                .isNull();
        assertThat(TechnicianInspectionService.captureSourceError("DOCUMENT", "BLUETOOTH", false))
                .isEqualTo("SOURCE_INVALID");
    }
}
