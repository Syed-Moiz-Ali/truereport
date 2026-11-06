import 'package:flutter/rendering.dart';

/// Automated widget tests default `debugDisableShadows` to `true`, replacing
/// blurred shadows with solid blocks. Fidelity capture must run with real
/// shadows, then restore the previous value before the test body ends (the
/// binding verifies painting debug variables at that point).
bool enableFidelityShadows() {
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  if (debugDisableShadows) {
    throw StateError('Fidelity capture must run with shadows enabled.');
  }
  return previous;
}

void restoreFidelityShadows(bool previous) {
  debugDisableShadows = previous;
}

void assertFidelityShadows() {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
}
