import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/checklist/checklist_plural.dart';

import 'support/ui_message_fixtures.dart';

void main() {
  test('category counts use singular, dual, and plural labels', () {
    final en = fakeEnUiStrings();
    expect(checklistCategoryCountLabel(en, 0), '0 categories');
    expect(checklistCategoryCountLabel(en, 1), '1 category');
    expect(checklistCategoryCountLabel(en, 2), '2 categories');
    expect(checklistCategoryCountLabel(en, 3), '3 categories');

    final ar = fakeArUiStrings();
    expect(checklistCategoryCountLabel(ar, 0), '0 فئات');
    expect(checklistCategoryCountLabel(ar, 1), 'فئة واحدة');
    expect(checklistCategoryCountLabel(ar, 2), 'فئتان');
  });

  test('item counts use singular, dual, and plural labels', () {
    final en = fakeEnUiStrings();
    expect(checklistItemCountLabel(en, 0), '0 items');
    expect(checklistItemCountLabel(en, 1), '1 item');
    expect(checklistItemCountLabel(en, 2), '2 items');
    expect(checklistItemCountLabel(en, 3), '3 items');

    final ar = fakeArUiStrings();
    expect(checklistItemCountLabel(ar, 0), '0 عناصر');
    expect(checklistItemCountLabel(ar, 1), 'عنصر واحد');
    expect(checklistItemCountLabel(ar, 2), 'عنصران');
  });
}
