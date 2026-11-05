import 'package:flutter/foundation.dart';

/// Test-only fixtures must never be part of a release build or deployment.
///
/// The gallery is already a separate workspace member that no product app or
/// `infra/` deployment references. This guard is the second line of defence:
/// release builds hide every fidelity section and refuse to start unless an
/// explicit opt-in define is supplied for a local inspection build.
abstract final class FixtureGuard {
  static const bool allowInRelease = bool.fromEnvironment(
    'ALLOW_FIDELITY_FIXTURES',
  );

  static bool get enabled => !kReleaseMode || allowInRelease;
}
