/// Server-aligned evidence validation shared by capture and the upload queue.
///
/// These rules mirror `TechnicianInspectionService` exactly: photo mimes do not
/// include PNG, photos must be at least 640x480, videos 15-30 seconds, and photo
/// and video sources are camera or local file. Keeping them pure makes them
/// testable without a camera, a browser, or a server.
library;

enum EvidenceValidationFailure {
  empty,
  tooLarge,
  resolutionTooLow,
  unsupportedPhotoType,
  unsupportedVideoType,
  unsupportedDocumentType,
  unsupportedType,
  cameraRequired,
  durationUnavailable,
  tooShort,
  tooLong,
  invalidHash,
  duplicate,
}

class EvidenceValidationException implements Exception {
  const EvidenceValidationException(this.failure);

  final EvidenceValidationFailure failure;
}

const Set<String> photoMimes = <String>{
  'image/jpeg',
  'image/heic',
  'image/heif',
  'image/webp',
};

const Set<String> videoMimes = <String>{
  'video/mp4',
  'video/webm',
  'video/quicktime',
};

const Set<String> documentMimes = <String>{
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/heic',
  'image/heif',
  'image/webp',
};

const int maxPhotoBytes = 20 * 1024 * 1024;
const int maxVideoBytes = 50 * 1024 * 1024;
const int maxDocumentBytes = 20 * 1024 * 1024;

const int minPhotoWidth = 640;
const int minPhotoHeight = 480;

const int minVideoDurationMs = 15000;
const int maxVideoDurationMs = 30000;

bool isSha256Hex(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

/// Returns the first rule the capture violates, or null when it may be uploaded.
EvidenceValidationFailure? validateEvidenceMetadata({
  required String type,
  required String mime,
  required int bytes,
  required String sha256,
  String? captureSource,
  int? width,
  int? height,
  int? durationMs,
  Iterable<String> existingSha256 = const <String>[],
}) {
  final normalizedType = type.trim().toUpperCase();
  final normalizedMime = mime.trim().toLowerCase();
  final source = (captureSource ?? '').trim().toUpperCase();
  final hash = sha256.trim().toLowerCase();

  final Set<String> allowedMimes;
  final int maxBytes;
  switch (normalizedType) {
    case 'PHOTO':
      allowedMimes = photoMimes;
      maxBytes = maxPhotoBytes;
    case 'VIDEO':
      allowedMimes = videoMimes;
      maxBytes = maxVideoBytes;
    case 'DOCUMENT':
      allowedMimes = documentMimes;
      maxBytes = maxDocumentBytes;
    default:
      return EvidenceValidationFailure.unsupportedType;
  }

  if (!allowedMimes.contains(normalizedMime)) {
    return switch (normalizedType) {
      'PHOTO' => EvidenceValidationFailure.unsupportedPhotoType,
      'VIDEO' => EvidenceValidationFailure.unsupportedVideoType,
      _ => EvidenceValidationFailure.unsupportedDocumentType,
    };
  }
  if (bytes <= 0) {
    return EvidenceValidationFailure.empty;
  }
  if (bytes > maxBytes) {
    return EvidenceValidationFailure.tooLarge;
  }
  if ((normalizedType == 'PHOTO' || normalizedType == 'VIDEO') &&
      source != 'CAMERA' &&
      source != 'FILE') {
    return EvidenceValidationFailure.cameraRequired;
  }
  if (normalizedType == 'PHOTO' &&
      (width == null ||
          height == null ||
          width < minPhotoWidth ||
          height < minPhotoHeight)) {
    return EvidenceValidationFailure.resolutionTooLow;
  }
  if (normalizedType == 'VIDEO') {
    if (durationMs == null || durationMs <= 0) {
      return EvidenceValidationFailure.durationUnavailable;
    }
    if (durationMs < minVideoDurationMs) {
      return EvidenceValidationFailure.tooShort;
    }
    if (durationMs > maxVideoDurationMs) {
      return EvidenceValidationFailure.tooLong;
    }
  }
  if (!isSha256Hex(hash)) {
    return EvidenceValidationFailure.invalidHash;
  }
  for (final existing in existingSha256) {
    if (existing.trim().toLowerCase() == hash) {
      return EvidenceValidationFailure.duplicate;
    }
  }
  return null;
}
