import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:platform_admin_app/src/features/checklist/checklist_date.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('formats checklist item dates without raw ISO text', () {
    final en = checklistUpdatedAtLabel('2026-11-10T08:00:00Z', 'en');
    expect(en, isNot(contains('2026-11-10T08:00:00Z')));
    expect(en, contains('12:00'));

    final ar = checklistUpdatedAtLabel('2026-11-10T08:00:00Z', 'ar');
    expect(ar, isNot(contains('2026-11-10T08:00:00Z')));
    expect(ar, isNotEmpty);
  });

  test('invalid checklist dates render an em dash', () {
    expect(checklistUpdatedAtLabel('', 'en'), '—');
    expect(checklistUpdatedAtLabel('not-a-date', 'en'), '—');
  });
}
