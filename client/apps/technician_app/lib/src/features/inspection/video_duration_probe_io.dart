import 'dart:io';

import 'package:video_player/video_player.dart';

/// Reads the recorded clip length from the local file.
Future<Duration?> probeVideoDuration(String path) async {
  VideoPlayerController? controller;
  try {
    controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    return controller.value.duration;
  } on Object {
    return null;
  } finally {
    await controller?.dispose();
  }
}
