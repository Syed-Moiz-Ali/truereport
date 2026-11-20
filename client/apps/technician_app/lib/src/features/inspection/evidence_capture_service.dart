import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/features/inspection/video_duration_probe.dart';

/// Where a photo/video came from. The server stores this as CAMERA or FILE.
enum EvidenceSource { camera, file }

extension EvidenceSourceWire on EvidenceSource {
  String get wire => this == EvidenceSource.camera ? 'CAMERA' : 'FILE';
}

typedef VideoDurationProbe = Future<Duration?> Function(String path);
typedef ImageSizeDecoder = Future<({int width, int height})?> Function(
  List<int> bytes,
);

class EvidenceCaptureException implements Exception {
  const EvidenceCaptureException(this.failure);

  final EvidenceValidationFailure failure;
}

class CapturedEvidence {
  const CapturedEvidence({
    required this.type,
    required this.bytes,
    required this.mime,
    required this.capturedAt,
    required this.captureSource,
    this.width,
    this.height,
    this.durationMs,
    this.posterBase64,
  });

  final String type;
  final Uint8List bytes;
  final String mime;
  final String capturedAt;
  final String captureSource;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? posterBase64;
}

class EvidenceCaptureService {
  EvidenceCaptureService({
    ImagePicker? picker,
    VideoDurationProbe? durationProbe,
    ImageSizeDecoder? imageSizeDecoder,
  }) : _picker = picker ?? ImagePicker(),
       _durationProbe = durationProbe ?? probeVideoDuration,
       _imageSizeDecoder = imageSizeDecoder ?? decodeImageSize;

  final ImagePicker _picker;
  final VideoDurationProbe _durationProbe;
  final ImageSizeDecoder _imageSizeDecoder;

  ImageSource _imageSource(EvidenceSource source) =>
      source == EvidenceSource.camera
      ? ImageSource.camera
      : ImageSource.gallery;

  String _mimeFor(XFile file, String fallback) {
    final byPath = mimeForPath(file.path, fallback: '');
    if (byPath.isNotEmpty) {
      return byPath;
    }
    final declared = file.mimeType?.trim().toLowerCase() ?? '';
    if (declared.isNotEmpty && !declared.contains('*')) {
      return declared;
    }
    return fallback;
  }

  Future<CapturedEvidence?> capturePhoto({
    EvidenceSource source = EvidenceSource.camera,
  }) async {
    final file = await _picker.pickImage(
      source: _imageSource(source),
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (file == null) {
      return null;
    }
    return _photoEvidence(file, source);
  }

  Future<CapturedEvidence?> recordVideo({
    EvidenceSource source = EvidenceSource.camera,
    bool capturePoster = false,
    Iterable<String> existingSha256 = const <String>[],
  }) async {
    final file = await _picker.pickVideo(
      source: _imageSource(source),
      maxDuration: const Duration(milliseconds: maxVideoDurationMs),
    );
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    final duration = await _durationProbe(file.path);
    String? poster;
    if (capturePoster) {
      final posterFile = await _picker.pickImage(source: ImageSource.camera);
      if (posterFile != null) {
        poster = base64Encode(await posterFile.readAsBytes());
      }
    }
    final captured = CapturedEvidence(
      type: 'VIDEO',
      bytes: bytes,
      mime: _mimeFor(file, 'video/mp4'),
      capturedAt: DateTime.now().toUtc().toIso8601String(),
      captureSource: source.wire,
      durationMs: duration?.inMilliseconds,
      posterBase64: poster,
    );
    _ensureValid(captured, existingSha256);
    return captured;
  }

  Future<CapturedEvidence?> pickDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'heic',
        'heif',
        'webp',
      ],
    );
    if (files.isEmpty) {
      return null;
    }
    final file = files.single;
    final bytes = await file.readAsBytes();
    final mime = mimeForPath(file.name);
    final size = mime.startsWith('image/')
        ? await _imageSizeDecoder(bytes)
        : null;
    final captured = CapturedEvidence(
      type: 'DOCUMENT',
      bytes: bytes,
      mime: mime,
      capturedAt: DateTime.now().toUtc().toIso8601String(),
      captureSource: 'FILE',
      width: size?.width,
      height: size?.height,
    );
    _ensureValid(captured);
    return captured;
  }

  Future<CapturedEvidence> _photoEvidence(
    XFile file,
    EvidenceSource source,
  ) async {
    final bytes = await file.readAsBytes();
    final size = await _imageSizeDecoder(bytes);
    final captured = CapturedEvidence(
      type: 'PHOTO',
      bytes: bytes,
      mime: _mimeFor(file, 'image/jpeg'),
      capturedAt: DateTime.now().toUtc().toIso8601String(),
      captureSource: source.wire,
      width: size?.width,
      height: size?.height,
    );
    _ensureValid(captured);
    return captured;
  }

  void _ensureValid(
    CapturedEvidence captured, [
    Iterable<String> existingSha256 = const <String>[],
  ]) {
    final failure = validateEvidenceMetadata(
      type: captured.type,
      mime: captured.mime,
      bytes: captured.bytes.length,
      sha256: sha256Hex(captured.bytes),
      captureSource: captured.captureSource,
      width: captured.width,
      height: captured.height,
      durationMs: captured.durationMs,
      existingSha256: existingSha256,
    );
    if (failure != null) {
      throw EvidenceCaptureException(failure);
    }
  }
}
