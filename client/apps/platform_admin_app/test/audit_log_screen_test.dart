import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/audit/audit_log_screen.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
        ),
        child: const AuditLogScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 9: Platform Audit Events Log Tests', () {
    testWidgets('renders all Figma headers, action buttons, and audit events',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Breadcrumb and headings
      expect(find.text('TAMPER-PROOF LEDGER'), findsOneWidget);
      expect(find.text('Security Audit Log'), findsOneWidget);
      expect(
        find.text(
          'Cryptographic ledger of administrative operations and permission shifts across workshop tiers.',
        ),
        findsOneWidget,
      );

      // Action buttons
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Verify Nodes'), findsOneWidget);

      // Filters
      expect(find.text('All Events'), findsOneWidget);
      expect(find.text('Permission Changes'), findsOneWidget);
      expect(find.text('Deactivations'), findsOneWidget);
      expect(find.text('Access Grants'), findsOneWidget);

      // Initial Events
      expect(find.text('Public Share Link Deactivated'), findsOneWidget);
      expect(find.text('Security Action'), findsOneWidget);
      expect(find.text('Workshop Node Created: Apex Fleet Central'), findsOneWidget);
      expect(find.text('Node Provisioned'), findsOneWidget);
      expect(find.text('Admin Role Granted to Operations Specialist'), findsOneWidget);
      expect(find.text('RBAC Updated'), findsOneWidget);
      expect(find.text('Master Checklist Schema Modified: Brake Wear'), findsOneWidget);
      expect(find.text('Catalog Versioned'), findsOneWidget);

      // Bottom Ledger Seal
      expect(find.text('Ledger Integrity Seal: 0x489F...A39E'), findsOneWidget);
      expect(find.text('SHOWING 4 OF 241 EVENTS'), findsOneWidget);
      expect(find.text('Load Previous Block'), findsOneWidget);
    });

    testWidgets('filtering by category updates displayed events',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap Deactivations
      final deactTab = find.byKey(const Key('category-tab-Deactivations'));
      await tester.tap(deactTab);
      await tester.pumpAndSettle();

      expect(find.text('Public Share Link Deactivated'), findsOneWidget);
      expect(find.text('Workshop Node Created: Apex Fleet Central'), findsNothing);
      expect(find.text('Admin Role Granted to Operations Specialist'), findsNothing);
    });

    testWidgets('filtering by search input narrows matching events',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const Key('input-filter-audit-log'));
      await tester.enterText(searchInput, 'Apex Fleet');
      await tester.pumpAndSettle();

      expect(find.text('Workshop Node Created: Apex Fleet Central'), findsOneWidget);
      expect(find.text('Public Share Link Deactivated'), findsNothing);
    });

    testWidgets('Export CSV triggers feedback SnackBar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final exportBtn = find.byKey(const Key('btn-export-csv'));
      await tester.tap(exportBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Exporting cryptographic audit log'), findsOneWidget);
    });

    testWidgets('Verify Nodes opens ledger verification modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('btn-verify-nodes'));
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Ledger & Node Verification'), findsOneWidget);
      expect(find.text('48 / 48 Workshop Cluster Nodes Validated'), findsOneWidget);
      expect(find.text('0 Hash Anomalies or Tampering Detected'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('inspecting event opens payload dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final inspectBtn = find.byKey(const Key('btn-inspect-event-evt-1'));
      await tester.ensureVisible(inspectBtn);
      await tester.tap(inspectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Audit Event Payload'), findsOneWidget);
      expect(find.text('Public Share Link Deactivated'), findsNWidgets(2)); // Card + Dialog title
      expect(find.textContaining('"event_id": "evt-1"'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('Load Previous Block loads additional events and updates counter',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('SHOWING 4 OF 241 EVENTS'), findsOneWidget);

      final loadMoreBtn = find.byKey(const Key('btn-load-previous-block'));
      await tester.ensureVisible(loadMoreBtn);
      await tester.tap(loadMoreBtn);
      await tester.pumpAndSettle();

      expect(find.text('SHOWING 6 OF 241 EVENTS'), findsOneWidget);
      expect(find.text('API Token Revoked: Legacy Scan Tool Sync'), findsOneWidget);
    });

    testWidgets('responsive layout on 400px mobile without RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(
        _buildTestApp(screenSize: const Size(400, 900)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Security Audit Log'), findsOneWidget);
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
