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
    test(
      'resolves known action, entity, role, and reason codes in English',
      () {
        final strings = fakeEnUiStrings();
        expect(
          auditActionLabel(strings, 'WORKSHOP_REGISTERED'),
          'Workshop registered',
        );
        expect(
          auditActionLabel(strings, 'MASTER_ITEM_PUBLISHED'),
          'Item published',
        );
        expect(auditActionLabel(strings, 'PUBLISH_ITEM'), 'Item published');
        expect(
          auditActionLabel(strings, 'CATEGORY_CREATED'),
          'Category created',
        );
        expect(
          auditActionLabel(strings, 'CREATE_CATEGORY'),
          'Category created',
        );
        expect(auditEntityLabel(strings, 'WORKSHOP'), 'Workshop');
        expect(auditEntityLabel(strings, 'MASTER_ITEM'), 'Master item');
        expect(auditEntityLabel(strings, 'CATEGORY'), 'Category');
        expect(auditEntityLabel(strings, 'MASTER_TEMPLATE'), 'Master template');
        expect(auditEntityLabel(strings, 'OPTION_SET'), 'Option set');
        expect(auditRoleLabel(strings, 'PLATFORM_ADMIN'), 'Platform Admin');
        expect(auditRoleLabel(strings, 'WORKSHOP_ADMIN'), 'Workshop Admin');
        expect(auditRoleLabel(strings, 'TECHNICIAN'), 'Technician');
        expect(auditReasonLabel(strings, 'INITIAL_SETUP'), 'Initial setup');
        expect(
          auditReasonLabel(strings, 'MANUAL_CORRECTION'),
          'Manual correction',
        );
        expect(auditActionLabel(strings, 'LOGIN_FAILED'), 'Sign-in failed');
        expect(
          auditActionLabel(strings, 'TOTP_SUCCEEDED'),
          'Two-factor verification succeeded',
        );
        expect(
          auditReasonLabel(strings, 'INVALID_CREDENTIALS'),
          'Invalid credentials',
        );
      },
    );

    test('resolves known action, entity, role, and reason codes in Arabic', () {
      final strings = fakeArUiStrings();
      expect(
        auditActionLabel(strings, 'WORKSHOP_REGISTERED'),
        'تم تسجيل الورشة',
      );
      expect(
        auditActionLabel(strings, 'MASTER_ITEM_PUBLISHED'),
        'تم نشر العنصر',
      );
      expect(auditActionLabel(strings, 'PUBLISH_ITEM'), 'تم نشر العنصر');
      expect(auditActionLabel(strings, 'CATEGORY_CREATED'), 'تم إنشاء التصنيف');
      expect(auditActionLabel(strings, 'CREATE_CATEGORY'), 'تم إنشاء التصنيف');
      expect(auditEntityLabel(strings, 'WORKSHOP'), 'ورشة');
      expect(auditEntityLabel(strings, 'MASTER_ITEM'), 'عنصر رئيسي');
      expect(auditEntityLabel(strings, 'CATEGORY'), 'تصنيف');
      expect(auditEntityLabel(strings, 'MASTER_TEMPLATE'), 'قالب رئيسي');
      expect(auditEntityLabel(strings, 'OPTION_SET'), 'مجموعة خيارات');
      expect(auditRoleLabel(strings, 'PLATFORM_ADMIN'), 'مدير المنصة');
      expect(auditRoleLabel(strings, 'WORKSHOP_ADMIN'), 'مدير الورشة');
      expect(auditRoleLabel(strings, 'TECHNICIAN'), 'فني');
      expect(auditReasonLabel(strings, 'INITIAL_SETUP'), 'الإعداد الأولي');
      expect(auditReasonLabel(strings, 'PUBLISH'), 'نشر');
      expect(auditActionLabel(strings, 'LOGIN_FAILED'), 'فشل تسجيل الدخول');
      expect(auditActionLabel(strings, 'TOTP_SUCCEEDED'), 'نجح التحقق بخطوتين');
      expect(
        auditReasonLabel(strings, 'INVALID_CREDENTIALS'),
        'بيانات اعتماد غير صالحة',
      );
    });

    test('humanizes unknown snake_case codes', () {
      final strings = fakeEnUiStrings();
      expect(
        auditActionLabel(strings, 'WORKSHOP_ARCHIVED'),
        'Workshop archived',
      );
      expect(auditEntityLabel(strings, 'SHED'), 'Shed');
      expect(auditRoleLabel(strings, 'AUDITOR'), 'Auditor');
      expect(auditReasonLabel(strings, 'UNMAPPED_REASON'), 'Unmapped reason');
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
