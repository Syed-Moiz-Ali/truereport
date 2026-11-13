import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/audit/audit_log_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'support/ui_message_fixtures.dart';

const _event = PlatformAuditEvent(
  id: 'evt-1',
  action: 'MASTER_ITEM_PUBLISHED',
  entityType: 'MASTER_ITEM',
  entityId: 'item-1',
  actorRole: 'PLATFORM_ADMIN',
  occurredAt: '2026-11-11T10:00:00Z',
  reasonCode: 'PUBLISH',
  metadataJson: '{"version":2}',
);

Widget _app({Locale locale = const Locale('en'), double width = 1280}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), 
      auditEventsProvider.overrideWith((ref) async => const [_event]),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const AuditLogScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders audit events from the API provider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('MASTER_ITEM_PUBLISHED'), findsWidgets);
    expect(find.textContaining('MASTER_ITEM'), findsWidgets);
  });

  testWidgets('renders on compact width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(_app(width: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Arabic layout without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
