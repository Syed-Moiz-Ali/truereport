import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/review/signoff_screen.dart';
import 'package:technician_app/src/inspection_models.dart';

Blocker _blocker(String code, {String? itemCode}) =>
    Blocker(code: code, itemCode: itemCode, messageEn: code, messageAr: code);

void main() {
  test('an item blocker opens that item and encodes its code', () {
    expect(
      technicianBlockerRoute(
        'job-1',
        _blocker('ITEM_NOT_ASSESSED', itemCode: 'BRAKE PAD/01'),
      ),
      '/jobs/job-1/items/BRAKE%20PAD%2F01',
    );
  });

  test('signature and conflict blockers open their own screens', () {
    expect(
      technicianBlockerRoute('job-1', _blocker('SIGNATURE_MISSING')),
      '/jobs/job-1/signature',
    );
    expect(
      technicianBlockerRoute('job-1', _blocker('SYNC_CONFLICT', itemCode: 'A')),
      '/sync',
    );
  });

  test('a job-level blocker with no destination is not tappable', () {
    expect(
      technicianBlockerRoute('job-1', _blocker('SCORE_NOT_COMPUTABLE')),
      isNull,
    );
  });

  test('completion is blocked by any summary blocker or open conflict', () {
    expect(
      technicianCanComplete(
        completing: false,
        blockers: const [],
        conflicts: 0,
        itemsTotal: 4,
      ),
      isTrue,
    );
    expect(
      technicianCanComplete(
        completing: false,
        blockers: [_blocker('ITEM_NOT_ASSESSED', itemCode: 'A')],
        conflicts: 0,
        itemsTotal: 4,
      ),
      isFalse,
    );
    expect(
      technicianCanComplete(
        completing: false,
        blockers: const [],
        conflicts: 1,
        itemsTotal: 4,
      ),
      isFalse,
    );
    expect(
      technicianCanComplete(
        completing: false,
        blockers: const [],
        conflicts: 0,
        itemsTotal: 0,
      ),
      isFalse,
    );
  });
}
