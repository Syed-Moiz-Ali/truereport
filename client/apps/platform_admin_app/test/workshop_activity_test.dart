import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_activity.dart';

import 'support/ui_message_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('audit labels', () {
    test('humanizes known action, role, and reason codes in English', () {
      final strings = fakeEnUiStrings();
      expect(
        auditActionLabel(strings, 'WORKSHOP_REGISTERED'),
        'Workshop registered',
      );
      expect(auditRoleLabel(strings, 'PLATFORM_ADMIN'), 'Platform Admin');
      expect(auditReasonLabel(strings, 'INITIAL_SETUP'), 'Initial setup');
    });

    test('humanizes known action, role, and reason codes in Arabic', () {
      final strings = fakeArUiStrings();
      expect(
        auditActionLabel(strings, 'WORKSHOP_REGISTERED'),
        'تم تسجيل الورشة',
      );
      expect(auditRoleLabel(strings, 'PLATFORM_ADMIN'), 'مدير المنصة');
      expect(auditReasonLabel(strings, 'INITIAL_SETUP'), 'الإعداد الأولي');
    });

    test('humanizes unknown snake_case codes', () {
      final strings = fakeEnUiStrings();
      expect(auditActionLabel(strings, 'WORKSHOP_UPDATED'), 'Workshop Updated');
      expect(auditRoleLabel(strings, 'WORKSHOP_ADMIN'), 'Workshop Admin');
      expect(
        auditReasonLabel(strings, 'MANUAL_CORRECTION'),
        'Manual Correction',
      );
    });
  });

  group('auditTimestampLabel', () {
    test('formats English timestamps without raw ISO text', () {
      final formatted = auditTimestampLabel('2026-11-12T10:00:00Z', 'en');
      expect(formatted, isNot(contains('2026-11-12T10:00:00Z')));
      expect(formatted, contains('14:00'));
    });

    test('formats Arabic timestamps without raw ISO text', () {
      final formatted = auditTimestampLabel('2026-11-12T10:00:00Z', 'ar');
      expect(formatted, isNot(contains('2026-11-12T10:00:00Z')));
      expect(formatted, contains('14:00'));
    });

    test('invalid timestamps render an em dash', () {
      expect(auditTimestampLabel('not-a-date', 'en'), '—');
      expect(auditTimestampLabel('', 'en'), '—');
    });
  });
}
