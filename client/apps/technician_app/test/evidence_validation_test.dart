import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';

String get _validSha => 'a'.padRight(64, 'a');

void main() {
  group('evidence metadata follows the server rules', () {
    test('accepts a camera photo at the minimum resolution', () {
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'CAMERA',
          width: 640,
          height: 480,
        ),
        isNull,
      );
    });

    test('rejects a photo below 640x480', () {
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'CAMERA',
          width: 639,
          height: 480,
        ),
        EvidenceValidationFailure.resolutionTooLow,
      );
    });

    test('rejects PNG photos while allowing PNG documents', () {
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/png',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'CAMERA',
          width: 1000,
          height: 800,
        ),
        EvidenceValidationFailure.unsupportedPhotoType,
      );
      expect(
        validateEvidenceMetadata(
          type: 'DOCUMENT',
          mime: 'image/png',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'FILE',
        ),
        isNull,
      );
    });

    test('accepts FILE but rejects unknown photo/video sources', () {
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'FILE',
          width: 1000,
          height: 800,
        ),
        isNull,
      );
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'SCANNER',
          width: 1000,
          height: 800,
        ),
        EvidenceValidationFailure.cameraRequired,
      );
      expect(
        validateEvidenceMetadata(
          type: 'VIDEO',
          mime: 'video/mp4',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'FILE',
          durationMs: 20000,
        ),
        isNull,
      );
      expect(
        validateEvidenceMetadata(
          type: 'VIDEO',
          mime: 'video/mp4',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'SCANNER',
          durationMs: 20000,
        ),
        EvidenceValidationFailure.cameraRequired,
      );
    });

    test('enforces the 15-30 second video window', () {
      EvidenceValidationFailure? video(int? durationMs) =>
          validateEvidenceMetadata(
            type: 'VIDEO',
            mime: 'video/mp4',
            bytes: 1024,
            sha256: _validSha,
            captureSource: 'CAMERA',
            durationMs: durationMs,
          );

      expect(video(15000), isNull);
      expect(video(30000), isNull);
      expect(video(14999), EvidenceValidationFailure.tooShort);
      expect(video(30001), EvidenceValidationFailure.tooLong);
      expect(video(null), EvidenceValidationFailure.durationUnavailable);
    });

    test('rejects oversized and empty payloads before any request', () {
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: maxPhotoBytes + 1,
          sha256: _validSha,
          captureSource: 'CAMERA',
          width: 1000,
          height: 800,
        ),
        EvidenceValidationFailure.tooLarge,
      );
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 0,
          sha256: _validSha,
          captureSource: 'CAMERA',
          width: 1000,
          height: 800,
        ),
        EvidenceValidationFailure.empty,
      );
    });

    test('de-duplicates by sha256 and rejects a malformed hash', () {
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 1024,
          sha256: _validSha,
          captureSource: 'CAMERA',
          width: 1000,
          height: 800,
          existingSha256: [_validSha],
        ),
        EvidenceValidationFailure.duplicate,
      );
      expect(
        validateEvidenceMetadata(
          type: 'PHOTO',
          mime: 'image/jpeg',
          bytes: 1024,
          sha256: 'not-a-hash',
          captureSource: 'CAMERA',
          width: 1000,
          height: 800,
        ),
        EvidenceValidationFailure.invalidHash,
      );
    });

    test('sha256 helper accepts only 64 lowercase hex characters', () {
      expect(isSha256Hex(_validSha), isTrue);
      expect(isSha256Hex('A'.padRight(64, 'A')), isFalse);
      expect(isSha256Hex('a'.padRight(63, 'a')), isFalse);
    });
  });

  test('byte limit is type-specific', () {
    expect(
      validateEvidenceMetadata(
        type: 'DOCUMENT',
        mime: 'application/pdf',
        bytes: maxDocumentBytes + 1,
        sha256: _validSha,
        captureSource: 'FILE',
      ),
      EvidenceValidationFailure.tooLarge,
    );
  });

  test('empty data never reaches a field validator', () {
    expect(
      validateEvidenceMetadata(
        type: 'PHOTO',
        mime: 'image/jpeg',
        bytes: 0,
        sha256: _validSha,
        captureSource: 'CAMERA',
        width: 640,
        height: 480,
      ),
      EvidenceValidationFailure.empty,
    );
    expect(Uint8List(0), isEmpty);
  });
}
