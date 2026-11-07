import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/screens/f2a/assigned_jobs_view.dart';
import 'package:technician_app/src/screens/f2b/f2b_intl.dart';
import 'package:technician_app/src/screens/f2b/final_review_view.dart';
import 'package:technician_app/src/screens/f2b/finalize_view.dart';
import 'package:technician_app/src/screens/f2b/offline_sync_view.dart';

import 'support/f2a_fixture_data.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';

/// F3-B Step 0: technician surfaces must never show raw ISO-8601 instants or
/// unformatted ASCII numbers. Fixed instants render locale-shaped (EN digits
/// vs Arabic-Indic) through the same instant semantics everywhere: offset-less
/// ISO is parsed as UTC and displayed in the Asia/Dubai (UTC+4) wall clock.
void main() {
  setUpAll(() async {
    await loadF2AFonts();
    // Date symbols load lazily in intl; initialize the locales this suite
    // exercises (production startup should do the same).
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('ar_EG', null);
  });

  final arabicDigits = RegExp(r'[٠-٩]');
  final rawIso = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:');

  group('f2b intl helpers are locale-shaped', () {
    test('counts group per locale', () {
      expect(formatCountLocalized(34180, 'en'), '34,180');
      final ar = formatCountLocalized(34180, 'ar');
      expect(ar, isNot('34,180'));
      expect(arabicDigits.hasMatch(ar), isTrue);
      expect(ar.contains('34180'), isFalse);
    });

    test('odometer mirrors F2-A formatOdometer per locale', () {
      expect(formatOdometerLocalized(34180, 'MI', 'en'), '34,180 MI');
      final ar = formatOdometerLocalized(34180, 'MI', 'ar');
      expect(arabicDigits.hasMatch(ar), isTrue);
      expect(ar.endsWith(' MI'), isTrue);
      expect(formatOdometerLocalized(null, 'KM', 'en'), isEmpty);
    });

    test('offset-less ISO is parsed as UTC (same instant semantics)', () {
      expect(
        parseInstantAsUtc('2026-11-05T06:42:00'),
        DateTime.utc(2026, 11, 5, 6, 42),
      );
      expect(
        parseInstantAsUtc('2026-11-05T06:42:00'),
        parseInstantAsUtc('2026-11-05T06:42:00Z'),
      );
      expect(parseInstantAsUtc(''), isNull);
      expect(parseInstantAsUtc('not-a-date'), isNull);
    });

    test('fixed instant renders locale-shaped Dubai wall clock', () {
      const instant = '2026-11-05T06:42:00Z';
      final en = formatInstantDubaiLocalized(instant, 'en');
      final ar = formatInstantDubaiLocalized(instant, 'ar');
      expect(en, isNotEmpty);
      expect(rawIso.hasMatch(en), isFalse);
      // 06:42Z is 10:42 in Dubai (UTC+4); EN keeps ASCII digits.
      expect(en.contains('10:42'), isTrue);
      expect(ar, isNot(en));
      expect(arabicDigits.hasMatch(ar), isTrue);
      expect(rawIso.hasMatch(ar), isFalse);
      // Offset-less input is the same instant.
      expect(
        formatInstantDubaiLocalized('2026-11-05T06:42:00', 'en'),
        en,
      );
      expect(formatInstantDubaiLocalized('', 'en'), isEmpty);
    });

    test('time helper mirrors scheduledTimeUtc4 per locale', () {
      final en = formatTimeDubaiLocalized('2026-11-05T06:42:00Z', 'en');
      final ar = formatTimeDubaiLocalized('2026-11-05T06:42:00Z', 'ar');
      expect(en, '10:42 UTC+4');
      expect(ar.contains('UTC+4'), isTrue);
      expect(arabicDigits.hasMatch(ar), isTrue);
    });
  });

  group('existing F2-A helpers behave per locale', () {
    // The F2-A helpers follow `Intl` locale directly; `ar_EG` is the CLDR
    // Arabic locale with Arabic-Indic digits (`intl`'s bare `ar` uses
    // Western digits), so it is the representative Arabic shaping here.
    test('formatOdometer shapes digits per locale', () {
      final en = Intl.withLocale('en', () => formatOdometer(48210, 'KM'));
      final ar = Intl.withLocale('ar_EG', () => formatOdometer(48210, 'KM'));
      expect(en, '48,210 KM');
      expect(ar, isNot(en));
      expect(arabicDigits.hasMatch(ar), isTrue);
    });

    test('scheduledTimeUtc4 renders the same instant per locale', () {
      const instant = '2026-11-05T06:42:00Z';
      final en = Intl.withLocale('en', () => scheduledTimeUtc4(instant));
      final ar = Intl.withLocale('ar_EG', () => scheduledTimeUtc4(instant));
      expect(en.contains('10:42'), isTrue);
      expect(en.contains('UTC+4'), isTrue);
      expect(ar, isNot(en));
      expect(arabicDigits.hasMatch(ar), isTrue);
      expect(rawIso.hasMatch(ar), isFalse);
    });
  });

  group('rendered F2-B views carry no raw ISO and shape numbers', () {
    String allText(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .join('\n');

    Future<void> pumpView(
      WidgetTester tester,
      Widget view,
      Locale locale,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        f2bHost(
          child: view,
          locale: locale,
          theme: AppTheme.build(isArabic: locale.languageCode == 'ar'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }

    testWidgets('finalize odometer is locale-shaped, no raw ISO', (
      tester,
    ) async {
      final checklist = productChecklist();
      Widget view() => FinalizeView(
        job: productJobs.first,
        review: const ReviewResult(
          ready: true,
          completed: 17,
          total: 40,
          blocking: [],
          warnings: [],
        ),
        checklist: checklist,
        onFinalize: () async {},
        onBack: () {},
        onProfile: () {},
      );

      await pumpView(tester, view(), const Locale('en'));
      var text = allText(tester);
      expect(text.contains('48,210 KM'), isTrue);
      expect(rawIso.hasMatch(text), isFalse);
      expect(text.contains(figmaScheduled), isFalse);

      await pumpView(tester, view(), const Locale('ar'));
      text = allText(tester);
      expect(arabicDigits.hasMatch(text), isTrue);
      expect(text.contains('48,210 KM'), isFalse);
      expect(rawIso.hasMatch(text), isFalse);
      expect(text.contains(figmaScheduled), isFalse);
    });

    testWidgets('final review counts/percent are locale-shaped', (
      tester,
    ) async {
      const review = ReviewResult(
        ready: false,
        completed: 1234,
        total: 5678,
        blocking: [
          ReviewIssue(
            code: 'ITEM_UNANSWERED',
            inspectionItemId: 'item-1',
            label: null,
            detail: null,
          ),
          ReviewIssue(
            code: 'EVIDENCE_REQUIRED',
            inspectionItemId: 'item-2',
            label: null,
            detail: null,
          ),
        ],
        warnings: [],
      );
      Widget view() => FinalReviewView(
        job: productJobs.first,
        review: review,
        onOpenIssue: (_) {},
        onContinue: () {},
        onBack: () {},
        onProfile: () {},
      );

      await pumpView(tester, view(), const Locale('en'));
      var text = allText(tester);
      expect(text.contains('1,234 / 5,678'), isTrue);
      expect(text.contains('22%'), isTrue);
      expect(rawIso.hasMatch(text), isFalse);

      await pumpView(tester, view(), const Locale('ar'));
      text = allText(tester);
      expect(arabicDigits.hasMatch(text), isTrue);
      expect(text.contains('1,234 / 5,678'), isFalse);
      expect(text.contains('1,234'), isFalse);
      expect(rawIso.hasMatch(text), isFalse);
    });

    testWidgets('offline sync counts are locale-shaped', (tester) async {
      final now = DateTime.utc(2026, 11, 5, 8);
      Widget view() => OfflineSyncView(
        operations: [
          SyncOperation(
            id: 'op-1',
            jobId: 'JOB-2601',
            type: 'answer',
            payload: const {},
            state: 'PENDING',
            attempts: 0,
            lastError: null,
            createdAt: now,
          ),
        ],
        pendingCount: 1234,
        online: false,
        onRetry: () {},
        onBack: () {},
        onProfile: () {},
      );

      await pumpView(tester, view(), const Locale('en'));
      expect(allText(tester).contains('1,234'), isTrue);

      await pumpView(tester, view(), const Locale('ar'));
      final text = allText(tester);
      expect(arabicDigits.hasMatch(text), isTrue);
      expect(text.contains('1,234'), isFalse);
    });

    testWidgets('no F2-B screen renders a raw T-ISO instant (EN+AR)', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final id in f2bScreenIds) {
          await pumpView(tester, f2bScreen(id, figma: false), locale);
          final text = allText(tester);
          expect(
            rawIso.hasMatch(text),
            isFalse,
            reason: '$id ${locale.languageCode} contains raw ISO instant',
          );
          expect(
            text.contains(figmaScheduled),
            isFalse,
            reason: '$id ${locale.languageCode} leaks scheduledAt',
          );
        }
      }
    });
  });
}
