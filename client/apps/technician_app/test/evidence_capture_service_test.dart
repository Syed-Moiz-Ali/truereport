import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';

class _FakePicker extends ImagePicker {
  XFile? image;
  XFile? video;
  ImageSource? lastImageSource;
  ImageSource? lastVideoSource;
  Duration? lastMaxDuration;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastImageSource = source;
    return image;
  }

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    lastVideoSource = source;
    lastMaxDuration = maxDuration;
    return video;
  }
}

XFile _photo({String mime = 'image/jpeg', String path = '/tmp/photo.jpg'}) =>
    XFile.fromData(
      Uint8List.fromList(<int>[1, 2, 3, 4]),
      mimeType: mime,
      path: path,
      name: path.split('/').last,
    );

XFile _video({String mime = 'video/mp4', String path = '/tmp/video.mp4'}) =>
    XFile.fromData(
      Uint8List.fromList(<int>[1, 2, 3, 4]),
      mimeType: mime,
      path: path,
      name: path.split('/').last,
    );

EvidenceCaptureService _service(
  _FakePicker picker, {
  Duration? duration = const Duration(seconds: 20),
  int width = 640,
  int height = 480,
}) => EvidenceCaptureService(
  picker: picker,
  durationProbe: (_) async => duration,
  imageSizeDecoder: (_) async => (width: width, height: height),
);

void main() {
  group('source selection', () {
    test('camera photo is tagged CAMERA', () async {
      final picker = _FakePicker()..image = _photo();
      final captured = await _service(picker)
          .capturePhoto(source: EvidenceSource.camera);

      expect(picker.lastImageSource, ImageSource.camera);
      expect(captured!.captureSource, 'CAMERA');
      expect(captured.type, 'PHOTO');
    });

    test('file photo is tagged FILE', () async {
      final picker = _FakePicker()..image = _photo();
      final captured = await _service(picker)
          .capturePhoto(source: EvidenceSource.file);

      expect(picker.lastImageSource, ImageSource.gallery);
      expect(captured!.captureSource, 'FILE');
    });

    test('camera video is tagged CAMERA and capped at 30 seconds', () async {
      final picker = _FakePicker()..video = _video();
      final captured = await _service(picker)
          .recordVideo(source: EvidenceSource.camera);

      expect(picker.lastVideoSource, ImageSource.camera);
      expect(picker.lastMaxDuration, const Duration(seconds: 30));
      expect(captured!.captureSource, 'CAMERA');
      expect(captured.type, 'VIDEO');
    });

    test(
      'file video is tagged FILE and runs the same duration rules',
      () async {
        final picker = _FakePicker()..video = _video();
        final captured = await _service(picker)
            .recordVideo(source: EvidenceSource.file);

        expect(picker.lastVideoSource, ImageSource.gallery);
        expect(captured!.captureSource, 'FILE');
        expect(captured.durationMs, 20000);
      },
    );
  });

  group('file-source validation', () {
    test('a PNG photo is rejected for files and camera alike', () async {
      final picker = _FakePicker()
        ..image = _photo(mime: 'image/png', path: '/tmp/photo.png');
      final service = _service(picker);

      for (final source in EvidenceSource.values) {
        await expectLater(
          service.capturePhoto(source: source),
          throwsA(
            isA<EvidenceCaptureException>().having(
              (error) => error.failure,
              'failure',
              EvidenceValidationFailure.unsupportedPhotoType,
            ),
          ),
        );
      }
    });

    test('a small file photo is rejected as too low resolution', () async {
      final picker = _FakePicker()..image = _photo();
      await expectLater(
        _service(
          picker,
          width: 320,
          height: 240,
        ).capturePhoto(source: EvidenceSource.file),
        throwsA(
          isA<EvidenceCaptureException>().having(
            (error) => error.failure,
            'failure',
            EvidenceValidationFailure.resolutionTooLow,
          ),
        ),
      );
    });

    test('a 10 second file video is rejected as too short', () async {
      final picker = _FakePicker()..video = _video();
      await expectLater(
        _service(
          picker,
          duration: const Duration(seconds: 10),
        ).recordVideo(source: EvidenceSource.file),
        throwsA(
          isA<EvidenceCaptureException>().having(
            (error) => error.failure,
            'failure',
            EvidenceValidationFailure.tooShort,
          ),
        ),
      );
    });

    test('a 31 second file video is rejected as too long', () async {
      final picker = _FakePicker()..video = _video();
      await expectLater(
        _service(
          picker,
          duration: const Duration(seconds: 31),
        ).recordVideo(source: EvidenceSource.file),
        throwsA(
          isA<EvidenceCaptureException>().having(
            (error) => error.failure,
            'failure',
            EvidenceValidationFailure.tooLong,
          ),
        ),
      );
    });
  });
}
