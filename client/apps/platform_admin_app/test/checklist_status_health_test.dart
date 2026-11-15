import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/checklist/checklist_health_labels.dart';
import 'package:platform_admin_app/src/features/checklist/checklist_status.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';

import 'support/ui_message_fixtures.dart';

void main() {
  group('checklistStatusLabel', () {
    test('localizes standard statuses in English', () {
      final strings = fakeEnUiStrings();
      expect(checklistStatusLabel(strings, 'ACTIVE'), 'Active');
      expect(checklistStatusLabel(strings, 'DRAFT'), 'Draft');
      expect(checklistStatusLabel(strings, 'PUBLISHED'), 'Published');
      expect(checklistStatusLabel(strings, 'RETIRED'), 'Retired');
      expect(checklistStatusLabel(strings, 'REVIEW'), 'In review');
      expect(checklistStatusLabel(strings, 'IN_REVIEW'), 'In review');
    });

    test('localizes standard statuses in Arabic', () {
      final strings = fakeArUiStrings();
      expect(checklistStatusLabel(strings, 'ACTIVE'), 'نشط');
      expect(checklistStatusLabel(strings, 'DRAFT'), 'مسودة');
      expect(checklistStatusLabel(strings, 'PUBLISHED'), 'منشور');
      expect(checklistStatusLabel(strings, 'RETIRED'), 'متقاعد');
      expect(checklistStatusLabel(strings, 'REVIEW'), 'قيد المراجعة');
      expect(checklistStatusLabel(strings, 'IN_REVIEW'), 'قيد المراجعة');
    });

    test(
      'humanizes unknown snake_case statuses instead of leaking raw code',
      () {
        final strings = fakeEnUiStrings();
        expect(
          checklistStatusLabel(strings, 'PENDING_APPROVAL'),
          'Pending Approval',
        );
        expect(
          checklistStatusLabel(strings, 'WAITING_FOR_SIGN_OFF'),
          'Waiting For Sign Off',
        );
        expect(checklistStatusLabel(strings, ''), '—');
      },
    );
  });

  group('checklistHealthLabels', () {
    test('provides human-readable titles in English and Arabic', () {
      final en = fakeEnUiStrings();
      final ar = fakeArUiStrings();

      const transCheck = HealthCheck(
        code: 'TRANSLATIONS',
        severity: 'OK',
        messageEn: '',
        messageAr: '',
        affected: 0,
        references: [],
      );
      expect(healthCheckTitle(en, transCheck), 'Translation completeness');
      expect(healthCheckTitle(ar, transCheck), 'اكتمال الترجمة');

      const safetyCheck = HealthCheck(
        code: 'SAFETY_EVIDENCE',
        severity: 'ERROR',
        messageEn: '',
        messageAr: '',
        affected: 2,
        references: [],
      );
      expect(
        healthCheckTitle(en, safetyCheck),
        'Safety-critical evidence rules',
      );
      expect(healthCheckTitle(ar, safetyCheck), 'قواعد أدلة السلامة الحرجة');

      const bandsCheck = HealthCheck(
        code: 'MEASUREMENT_BANDS',
        severity: 'ERROR',
        messageEn: '',
        messageAr: '',
        affected: 1,
        references: [],
      );
      expect(healthCheckTitle(en, bandsCheck), 'Measurement band continuity');
      expect(healthCheckTitle(ar, bandsCheck), 'استمرارية نطاقات القياس');
    });

    test('humanizes unknown health codes', () {
      final en = fakeEnUiStrings();
      const unknownCheck = HealthCheck(
        code: 'CUSTOM_CHECK_FAILURE',
        severity: 'WARNING',
        messageEn: '',
        messageAr: '',
        affected: 1,
        references: [],
      );
      expect(healthCheckTitle(en, unknownCheck), 'Custom Check Failure');
    });

    test('localizes severity labels and affected counts', () {
      final en = fakeEnUiStrings();
      final ar = fakeArUiStrings();

      expect(healthSeverityLabel(en, 'OK', isOk: true), 'Healthy');
      expect(healthSeverityLabel(ar, 'OK', isOk: true), 'سليم');
      expect(healthSeverityLabel(en, 'WARNING'), 'Warning');
      expect(healthSeverityLabel(ar, 'WARNING'), 'تحذير');
      expect(healthSeverityLabel(en, 'ERROR'), 'Error');
      expect(healthSeverityLabel(ar, 'ERROR'), 'خطأ');

      expect(healthAffectedCountLabel(en, 5), '5 affected');
      expect(healthAffectedCountLabel(ar, 5), '5 متأثر');
    });

    test('uses only the active-language health message', () {
      const check = HealthCheck(
        code: 'TRANSLATIONS',
        severity: 'OK',
        messageEn: 'English body',
        messageAr: 'Arabic body',
        affected: 0,
        references: [],
      );
      expect(healthCheckMessage(fakeEnUiStrings(), check), 'English body');
      expect(healthCheckMessage(fakeArUiStrings(), check), 'Arabic body');
    });

    test('prefers a resolvable messageKey over legacy messages', () {
      const check = HealthCheck(
        code: 'TRANSLATIONS',
        severity: 'OK',
        messageEn: 'English body',
        messageAr: 'Arabic body',
        messageKey: 'platform_admin.page.health.title',
        affected: 0,
        references: [],
      );
      expect(
        healthCheckMessage(fakeEnUiStrings(), check),
        'Configuration health',
      );
    });
  });
}
