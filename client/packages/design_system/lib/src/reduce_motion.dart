import 'package:flutter/widgets.dart';

abstract final class ReduceMotion {
  static Duration duration(BuildContext context, Duration normal) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : normal;
  }

  static bool enabled(BuildContext context) =>
      !MediaQuery.of(context).disableAnimations;
}
