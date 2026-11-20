import 'package:video_player/video_player.dart';

/// Reads the recorded clip length from the browser blob URL.
///
/// Desktop browsers have no camera capture UI, so this is used only where the
/// picker returns a playable blob. A null result is surfaced as an explicit
/// "could not read the video length" error, never as a silent upload.
Future<Duration?> probeVideoDuration(String path) async {
  VideoPlayerController? controller;
  try {
    controller = VideoPlayerController.networkUrl(Uri.parse(path));
    await controller.initialize();
    return controller.value.duration;
  } on Object {
    return null;
  } finally {
    await controller?.dispose();
  }
}
