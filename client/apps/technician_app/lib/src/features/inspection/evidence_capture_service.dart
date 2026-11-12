import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:video_player/video_player.dart';

enum EvidenceCaptureFailure { tooShort, tooLong, tooLarge, unavailable }

class EvidenceCaptureException implements Exception {
  const EvidenceCaptureException(this.failure);

  final EvidenceCaptureFailure failure;
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
  EvidenceCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const int maxVideoBytes = 50 * 1024 * 1024;
  static const Duration minVideoDuration = Duration(seconds: 15);
  static const Duration maxVideoDuration = Duration(seconds: 30);

  final ImagePicker _picker;

  Future<CapturedEvidence?> capturePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (file == null) {
      return null;
    }
    return _photoEvidence(file);
  }

  Future<CapturedEvidence?> recordVideo({bool capturePoster = false}) async {
    final file = await _picker.pickVideo(source: ImageSource.camera);
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxVideoBytes) {
      throw const EvidenceCaptureException(EvidenceCaptureFailure.tooLarge);
    }
    Duration? duration;
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      duration = controller.value.duration;
    } on Object {
      duration = null;
    } finally {
      await controller?.dispose();
    }
    if (duration != null) {
      if (duration < minVideoDuration) {
        throw const EvidenceCaptureException(EvidenceCaptureFailure.tooShort);
      }
      if (duration > maxVideoDuration) {
        throw const EvidenceCaptureException(EvidenceCaptureFailure.tooLong);
      }
    }
    String? poster;
    if (capturePoster) {
      final posterFile = await _picker.pickImage(source: ImageSource.camera);
      if (posterFile != null) {
        poster = base64Encode(await posterFile.readAsBytes());
      }
    }
    return CapturedEvidence(
      type: 'VIDEO',
      bytes: bytes,
      mime: mimeForPath(file.path, fallback: 'video/mp4'),
      capturedAt: DateTime.now().toUtc().toIso8601String(),
      captureSource: 'CAMERA',
      durationMs: duration?.inMilliseconds,
      posterBase64: poster,
    );
  }

  Future<CapturedEvidence?> pickDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (files.isEmpty) {
      return null;
    }
    final file = files.single;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const EvidenceCaptureException(EvidenceCaptureFailure.unavailable);
    }
    if (bytes.length > maxVideoBytes) {
      throw const EvidenceCaptureException(EvidenceCaptureFailure.tooLarge);
    }
    final mime = mimeForPath(file.name);
    final size = mime.startsWith('image/')
        ? await decodeImageSize(bytes)
        : null;
    return CapturedEvidence(
      type: 'DOCUMENT',
      bytes: bytes,
      mime: mime,
      capturedAt: DateTime.now().toUtc().toIso8601String(),
      captureSource: 'FILE',
      width: size?.width,
      height: size?.height,
    );
  }

  Future<CapturedEvidence> _photoEvidence(XFile file) async {
    final bytes = await file.readAsBytes();
    final size = await decodeImageSize(bytes);
    return CapturedEvidence(
      type: 'PHOTO',
      bytes: bytes,
      mime: mimeForPath(file.path, fallback: 'image/jpeg'),
      capturedAt: DateTime.now().toUtc().toIso8601String(),
      captureSource: 'CAMERA',
      width: size?.width,
      height: size?.height,
    );
  }
}
