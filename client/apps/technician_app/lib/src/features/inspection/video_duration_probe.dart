/// Conditional video duration probe.
///
/// Mobile/desktop paths are real files; the web picker returns a blob URL.
/// Keeping the platform split in one tiny file is what lets the technician app
/// build for web without importing `dart:io` anywhere in the shared service.
library;

export 'video_duration_probe_io.dart'
    if (dart.library.html) 'video_duration_probe_web.dart';
