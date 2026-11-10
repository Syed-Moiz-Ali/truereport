import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/equipment/equipment_library_screen.dart';

class _TestLocaleNotifier extends LocaleNotifier {
  _TestLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Widget _buildTestApp({
  Locale locale = const Locale('en'),
  Size screenSize = const Size(1280, 1024),
}) {
  return ProviderScope(
    overrides: [
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
        ),
        child: const EquipmentLibraryScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 8: Global Equipment Library Tests', () {
    testWidgets('renders all Figma headers, filter tabs, and equipment cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Breadcrumb and headings
      expect(find.text('NETWORK HARDWARE FLEET'), findsOneWidget);
      expect(find.text('Platform Equipment Catalogue'), findsOneWidget);
      expect(
        find.text(
          'Hardware devices, calibration gauges, and diagnostic readers authorized across network.',
        ),
        findsOneWidget,
      );

      // Filter tabs and Register CTA
      expect(find.text('All Tools'), findsOneWidget);
      expect(find.text('Calibrated'), findsOneWidget);
      expect(find.text('Telemetry'), findsOneWidget);
      expect(find.text('Register Equipment'), findsOneWidget);

      // Tool Cards
      expect(find.text('OBD2 Scanner'), findsOneWidget);
      expect(find.text('Signal Locked'), findsOneWidget);
      expect(find.text('Digital Tread Measurement Tool'), findsOneWidget);
      expect(find.text('ISO Certified'), findsOneWidget);
      expect(find.text('Precision Fastener Torque Tool'), findsOneWidget);
      expect(find.text('Auto Zeroing'), findsOneWidget);
      expect(find.text('Surface Coating Thickness Probe'), findsOneWidget);
      expect(find.text('Magnetic Eddy'), findsOneWidget);
      expect(find.text('EV High-Voltage Analyzer'), findsOneWidget);
      expect(find.text('CAT IV 1000V'), findsOneWidget);

      // Integrate card
      expect(find.text('Integrate New Spec'), findsOneWidget);
      expect(find.text('Browse Protocols'), findsOneWidget);

      // Bottom telemetry policy banner
      expect(find.text('Automatic Telemetry Sync'), findsOneWidget);
      expect(find.text('5/5 Authorized Active'), findsOneWidget);
      expect(find.text('Diagnostic Logs'), findsOneWidget);
    });

    testWidgets('filtering by tab updates visible cards list',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap "Calibrated" filter
      final calibratedTab = find.byKey(const Key('filter-tab-Calibrated'));
      await tester.tap(calibratedTab);
      await tester.pumpAndSettle();

      expect(find.text('OBD2 Scanner'), findsOneWidget);
      expect(find.text('Digital Tread Measurement Tool'), findsOneWidget);
      expect(find.text('Precision Fastener Torque Tool'), findsOneWidget);
      expect(find.text('Surface Coating Thickness Probe'), findsOneWidget);
      // EV Analyzer is not calibrated in mock
      expect(find.text('EV High-Voltage Analyzer'), findsNothing);
    });

    testWidgets('toggling equipment switch updates state and displays feedback',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final toggleObd =
          find.byKey(const Key('toggle-equipment-eq-obd2'));
      await tester.ensureVisible(toggleObd);
      await tester.tap(toggleObd);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('OBD2 Scanner is now Disabled across network'),
        findsOneWidget,
      );
      expect(find.text('4/5 Authorized Active'), findsOneWidget);
    });

    testWidgets('Register Equipment dialog opens and provisions new equipment',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final registerBtn = find.byKey(const Key('btn-register-equipment'));
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Register Network Equipment'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('input-register-eq-name')),
        'Optical Wheel Aligner',
      );
      await tester.enterText(
        find.byKey(const Key('input-register-eq-spec')),
        '3D Camera Rig • ISO 17025',
      );

      final submitBtn =
          find.byKey(const Key('btn-submit-register-equipment'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Optical Wheel Aligner'), findsOneWidget);
      expect(
        find.textContaining('Optical Wheel Aligner registered into Global Equipment Library'),
        findsOneWidget,
      );
    });

    testWidgets('Browse Protocols and Diagnostic Logs open respective modals',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Open Protocols
      final browseBtn = find.byKey(const Key('btn-browse-protocols'));
      await tester.ensureVisible(browseBtn);
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();

      expect(find.text('Supported Diagnostic Protocols'), findsOneWidget);
      expect(find.text('ISO 14229 (UDS)'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Open Diagnostic Logs
      final logsBtn = find.byKey(const Key('btn-diagnostic-logs'));
      await tester.ensureVisible(logsBtn);
      await tester.tap(logsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Telemetry Calibration Drift Logs'), findsOneWidget);
      expect(find.text('OBD2-8849'), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
    });

    testWidgets('responsive layout on 400px mobile without RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(
        _buildTestApp(screenSize: const Size(400, 900)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Platform Equipment Catalogue'), findsOneWidget);
    });

    testWidgets('renders cleanly in Arabic RTL without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(
        _buildTestApp(locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
