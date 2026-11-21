package com.truereport.media.api;

public final class VehiclePhotoDtos {

    private VehiclePhotoDtos() {
    }

    /** Init carries declared size/hash so the upload can be verified. */
    public record VehiclePhotoInitRequest(
            String mime,
            Long bytes,
            String sha256,
            String capturedAt,
            String captureSource,
            String deviceId
    ) {
    }

    public record VehiclePhotoInitResponse(String id, String status, String mime, long bytes) {
    }

    public record VehiclePhotoUploadResponse(
            String id, String status, String mime, long bytes, String sha256) {
    }

    public record VehiclePhotoCompleteResponse(
            String id, String status, String mime, long bytes, String sha256, String capturedAt) {
    }

    public record VehiclePhotoDto(
            String id, String status, String mime, Long bytes, String sha256, String capturedAt) {
    }
}
