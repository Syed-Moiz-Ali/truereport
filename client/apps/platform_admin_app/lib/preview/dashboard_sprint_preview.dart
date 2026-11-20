import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'sprint_orbit.dart';
import 'sprint_trellis.dart';
import 'sprint_wall.dart';

/// Throwaway direction preview for the dashboard sprint.
/// Run: flutter run -d web-server -t lib/preview/dashboard_sprint_preview.dart
/// Query: ?d=a|b|c  ?rtl=1
void main() => runApp(const SprintPreviewApp());

class SprintPreviewApp extends StatelessWidget {
  const SprintPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SprintPreviewHost(),
    );
  }
}

class SprintPreviewHost extends StatelessWidget {
  const SprintPreviewHost({super.key});

  @override
  Widget build(BuildContext context) {
    final query = Uri.base.queryParameters;
    final rtl = query['rtl'] == '1';
    final direction = query['d'] ?? 'a';
    final page = switch (direction) {
      'b' => SprintWall(rtl: rtl),
      'c' => SprintTrellis(rtl: rtl),
      _ => SprintOrbit(rtl: rtl),
    };
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: page,
    );
  }
}
