import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class CapturedPhoto {
  const CapturedPhoto({
    required this.bytes,
    required this.mimeType,
    required this.sha256,
  });

  final Uint8List bytes;
  final String mimeType;
  final String sha256;
}

class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<CapturedPhoto?> capture(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2400,
      maxHeight: 2400,
      requestFullMetadata: false,
    );
    if (picked == null) {
      return null;
    }
    final original = await picked.readAsBytes();
    var bytes = original;
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        quality: 85,
        minWidth: 1600,
        minHeight: 1200,
        format: CompressFormat.jpeg,
      );
      if (compressed.isNotEmpty) {
        bytes = compressed;
      }
    } on Object {
      bytes = original;
    }
    return CapturedPhoto(
      bytes: bytes,
      mimeType: 'image/jpeg',
      sha256: sha256.convert(bytes).toString(),
    );
  }
}
