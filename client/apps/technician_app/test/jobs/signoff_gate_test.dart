/// Characterization tests for the sign-off completion gate.
///
/// `technicianCanComplete` is the single decision behind the Complete button:
/// blockers, open sync conflicts and an empty checklist always refuse it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/review/signoff_screen.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../support/fixtures.dart';

void main() {
  group('technicianCanComplete', () {
    test('true when nothing blocks a non-empty, conflict-free inspection', () {
      expect(
        technicianCanComplete(
          completing: false,
          blockers: const <Blocker>[],
          conflicts: 0,
          itemsTotal: 30,
        ),
        isTrue,
      );
    });

    test('false when a blocker is open', () {
      expect(
        technicianCanComplete(
          completing: false,
          blockers: <Blocker>[blocker(code: 'SIGNATURE_MISSING')],
          conflicts: 0,
          itemsTotal: 30,
        ),
        isFalse,
      );
    });

    test('false when an inspection item blocker is open', () {
      expect(
        technicianCanComplete(
          completing: false,
          blockers: <Blocker>[
            blocker(
              code: 'EVIDENCE_MISSING',
              itemCode: 'brake_pads_front',
              messageEn: 'Photo evidence is missing.',
            ),
          ],
          conflicts: 0,
          itemsTotal: 30,
        ),
        isFalse,
      );
    });

    test('false when a sync conflict is open', () {
      expect(
        technicianCanComplete(
          completing: false,
          blockers: const <Blocker>[],
          conflicts: 1,
          itemsTotal: 30,
        ),
        isFalse,
      );
    });

    test('false when the checklist has zero items', () {
      expect(
        technicianCanComplete(
          completing: false,
          blockers: const <Blocker>[],
          conflicts: 0,
          itemsTotal: 0,
        ),
        isFalse,
      );
    });

    test('false while a completion request is already in flight', () {
      expect(
        technicianCanComplete(
          completing: true,
          blockers: const <Blocker>[],
          conflicts: 0,
          itemsTotal: 30,
        ),
        isFalse,
      );
    });
  });
}
