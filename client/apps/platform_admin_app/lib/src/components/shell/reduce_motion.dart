import 'package:flutter/material.dart';

/// Honors `MediaQuery.disableAnimations` (prefers-reduced-motion).
abstract final class PtReduceMotion {
  static Duration duration(BuildContext context, Duration normal) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return Duration.zero;
    }
    return normal;
  }
}
