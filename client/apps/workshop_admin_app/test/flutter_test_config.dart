import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';

/// Global test configuration for the Workshop Admin app.
///
/// Runs before every test file in this package, so real bundled fonts are
/// available to all widget tests — not just the screenshot suite. Font metrics
/// that come from Ahem make overflow assertions meaningless.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await RealFonts.load();
  await testMain();
}
