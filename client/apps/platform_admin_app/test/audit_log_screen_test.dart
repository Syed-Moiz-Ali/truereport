import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

const _testManifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
    UiMessageLanguage(code: 'ar', direction: 'rtl', nativeName: 'العربية'),
  ],
);

class _TestUiMessageController extends UiMessageController {
  _TestUiMessageController(this.lang);
  final String lang;

  @override
  UiMessageState build() => UiMessageState(
    manifest: _testManifest,
    activeLanguage: lang,
    defaultLanguage: 'en',
    ready: true,
    revision: 1,
  );
}

Widget _app({Locale locale = const Locale('en'), double width = 1280}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(locale.languageCode),
      ),
      auditEventsPageProvider.overrideWith(
        (ref, query) async =>
            const AuditEventPage(items: [_event], total: 1, page: 0, size: 25),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const AuditLogScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'renders audit events from the API provider with humanized labels',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Localized action title and entity
      expect(find.text('Item published'), findsOneWidget);
      expect(find.textContaining('Master item'), findsWidgets);
      expect(find.text('Actor: Platform Admin'), findsOneWidget);
      expect(find.text('Reason: Publish'), findsOneWidget);

      // No raw uppercase snake_case or raw ISO strings
      expect(find.text('MASTER_ITEM_PUBLISHED'), findsNothing);
      expect(find.text('2026-11-11T10:00:00Z'), findsNothing);

      // Metadata JSON is hidden by default behind details toggle
      expect(find.text('{"version":2}'), findsNothing);
      expect(find.text('View details'), findsOneWidget);

      // Tapping 'View details' shows the raw metadata
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.text('{"version":2}'), findsOneWidget);
      expect(find.text('Hide details'), findsOneWidget);
    },
  );

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

  testWidgets('localizes known Arabic audit actions, entities, and details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(AuditLogScreen));
    final container = ProviderScope.containerOf(element, listen: false);
    expect(container.read(uiMessageControllerProvider).activeLanguage, 'ar');
    expect(Localizations.localeOf(element).languageCode, 'ar');
    expect(Directionality.of(element), TextDirection.rtl);
    expect(find.text('العربية (AR)'), findsOneWidget);

    expect(find.text('تم نشر العنصر'), findsOneWidget);
    expect(find.textContaining('عنصر رئيسي'), findsWidgets);
    expect(find.text('الفاعل: مدير المنصة'), findsOneWidget);
    expect(find.text('السبب: نشر'), findsOneWidget);
    expect(find.text('عرض التفاصيل'), findsOneWidget);
    expect(find.text('View details'), findsNothing);
    expect(find.text('Hide details'), findsNothing);

    await tester.tap(find.text('عرض التفاصيل'));
    await tester.pumpAndSettle();
    expect(find.text('{"version":2}'), findsOneWidget);
    expect(find.text('إخفاء التفاصيل'), findsOneWidget);
    expect(find.text('View details'), findsNothing);
  });
}
