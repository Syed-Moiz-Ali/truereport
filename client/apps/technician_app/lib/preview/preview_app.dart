import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'direction_a.dart';
import 'direction_b.dart';
import 'direction_c.dart';
import 'preview_data.dart';

/// Throwaway design preview for the technician jobs module.
///
/// Run with `flutter run -t lib/preview/preview_app.dart` and switch directions
/// with the URL: `?dir=a|b|c` and `?screen=queue|job`.
void main() => runApp(const JobsDesignPreview());

class JobsDesignPreview extends StatelessWidget {
  const JobsDesignPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const _PreviewSwitcher(),
    );
  }
}

class _PreviewSwitcher extends StatelessWidget {
  const _PreviewSwitcher();

  @override
  Widget build(BuildContext context) {
    final query = Uri.base.queryParameters;
    final screen = query['screen'] == 'job'
        ? PreviewScreen.job
        : PreviewScreen.queue;
    return switch ((query['dir'] ?? 'a').toLowerCase()) {
      'b' => DirectionB(screen: screen),
      'c' => DirectionC(screen: screen),
      _ => DirectionA(screen: screen),
    };
  }
}
