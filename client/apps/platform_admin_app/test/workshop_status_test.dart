import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_status.dart';

import 'support/ui_message_fixtures.dart';

void main() {
  group('workshopStatusLabel', () {
    test('localizes every canonical workshop status in English', () {
      final strings = fakeEnUiStrings();
      expect(workshopStatusLabel(strings, 'ACTIVE'), 'Active');
      expect(workshopStatusLabel(strings, 'INACTIVE'), 'Inactive');
      expect(workshopStatusLabel(strings, 'STANDBY'), 'Standby');
      expect(workshopStatusLabel(strings, 'RETIRED'), 'Retired');
      expect(workshopStatusLabel(strings, 'DEPOT HUB'), 'Depot hub');
    });

    test('localizes every canonical workshop status in Arabic', () {
      final strings = fakeArUiStrings();
      expect(workshopStatusLabel(strings, 'ACTIVE'), 'نشط');
      expect(workshopStatusLabel(strings, 'INACTIVE'), 'غير نشط');
      expect(workshopStatusLabel(strings, 'STANDBY'), 'احتياطي');
      expect(workshopStatusLabel(strings, 'RETIRED'), 'متقاعد');
      expect(workshopStatusLabel(strings, 'DEPOT HUB'), 'مركز توزيع');
    });

    test('normalizes backend casing and separators', () {
      final strings = fakeEnUiStrings();
      expect(workshopStatusLabel(strings, ' active '), 'Active');
      expect(workshopStatusLabel(strings, 'depot_hub'), 'Depot hub');
      expect(workshopStatusLabel(strings, 'depot-hub'), 'Depot hub');
      expect(normalizeWorkshopStatus('  depot_hub '), 'DEPOT HUB');
    });

    test('humanizes unknown free-form statuses', () {
      final strings = fakeEnUiStrings();
      expect(workshopStatusLabel(strings, 'OUT_OF_SERVICE'), 'Out Of Service');
      expect(workshopStatusLabel(strings, 'on hold'), 'On Hold');
    });

    test('renders an em dash for an empty status', () {
      expect(workshopStatusLabel(fakeEnUiStrings(), '   '), '—');
    });

    test('localizes member and template statuses in Arabic', () {
      final strings = fakeArUiStrings();
      expect(workshopMemberStatusLabel(strings, 'ACTIVE'), 'نشط');
      expect(workshopMemberStatusLabel(strings, 'DISABLED'), 'معطّل');
      expect(workshopTemplateStatusLabel(strings, 'PUBLISHED'), 'منشور');
      expect(workshopTemplateStatusLabel(strings, 'DRAFT'), 'مسودة');
    });
  });
}
