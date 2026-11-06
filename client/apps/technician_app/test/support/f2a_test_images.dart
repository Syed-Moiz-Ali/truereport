import 'dart:io';
import 'dart:ui' as ui;

/// Decodes a Figma-exported raster image for test-only fidelity fixtures.
/// The file lives under docs/ui/figma-export and is never listed in a pubspec
/// asset section, so it cannot ship in a release bundle.
Future<ui.Image> loadFigmaTestImage(String absolutePath) async {
  final bytes = File(absolutePath).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
