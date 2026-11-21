import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/models.dart';

import 'support/fake_admin_api.dart';
import 'support/ui_strings_harness.dart';

ReportDelivery _delivery(String channel) => ReportDelivery(
  id: 'delivery-1',
  channel: channel,
  recipientMasked: 'c***@example.com',
  language: 'en',
  status: 'QUEUED',
  attempts: 0,
  maxAttempts: 3,
  pdfAttached: true,
  linkState: 'ACTIVE',
  lastErrorCode: null,
  lastErrorMessage: null,
  nextAttemptAt: '',
  createdAt: '2026-11-22T09:00:00',
  updatedAt: '2026-11-22T09:00:00',
  attemptHistory: const <ReportDeliveryAttempt>[],
);

class _RecordingApi extends FakeAdminApi {
  _RecordingApi({required super.deliveryChannelOptions});

  String? sentChannel;

  @override
  Future<ReportDelivery> sendDelivery(
    String jobId, {
    required String channel,
    required String language,
    required String idempotencyKey,
  }) async {
    sentChannel = channel;
    return _delivery(channel);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeAdminApi api,
  bool channelsFail = false,
}) async {
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminApiProvider.overrideWithValue(api),
        if (channelsFail)
          deliveryChannelsProvider.overrideWith(
            (ref) => Future<List<DeliveryChannelOption>>.error(
              StateError('channels offline'),
            ),
          ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        theme: AppTheme.light,
        home: const ReportPage(jobId: 'job-3'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('email-only capability sends EMAIL', (tester) async {
    final api = _RecordingApi(
      deliveryChannelOptions: const <DeliveryChannelOption>[
        DeliveryChannelOption(channel: 'EMAIL', available: true),
        DeliveryChannelOption(channel: 'SMS', available: false),
        DeliveryChannelOption(channel: 'WHATSAPP', available: false),
      ],
    );
    await _pump(tester, api: api);
    final t = UiStrings.of(tester.element(find.byType(ReportPage)));

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('report-delivery-channel-email')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-delivery-channel-sms')), findsNothing);
    expect(
      find.byKey(const Key('report-delivery-channel-whatsapp')),
      findsNothing,
    );
    expect(
      tester
          .widget<AppSelectableText>(
            find.byKey(const Key('report-delivery-channel-email')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('SMS'), findsNothing);

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(api.sentChannel, 'EMAIL');
  });

  testWidgets('available SMS is offered but EMAIL stays the default', (
    tester,
  ) async {
    final api = _RecordingApi(
      deliveryChannelOptions: const <DeliveryChannelOption>[
        DeliveryChannelOption(channel: 'EMAIL', available: true),
        DeliveryChannelOption(channel: 'SMS', available: true),
        DeliveryChannelOption(channel: 'WHATSAPP', available: false),
      ],
    );
    await _pump(tester, api: api);
    final t = UiStrings.of(tester.element(find.byType(ReportPage)));

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('report-delivery-channel-email')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('report-delivery-channel-sms')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('report-delivery-channel-whatsapp')),
      findsNothing,
    );
    expect(
      tester
          .widget<AppSelectableText>(
            find.byKey(const Key('report-delivery-channel-email')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<AppSelectableText>(
            find.byKey(const Key('report-delivery-channel-sms')),
          )
          .selected,
      isFalse,
    );
  });

  testWidgets('channel capability failure falls back to Email only', (
    tester,
  ) async {
    await _pump(tester, api: FakeAdminApi(), channelsFail: true);
    final t = UiStrings.of(tester.element(find.byType(ReportPage)));

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('report-delivery-channel-email')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-delivery-channel-sms')), findsNothing);
    expect(
      find.byKey(const Key('report-delivery-channel-whatsapp')),
      findsNothing,
    );
  });
}
