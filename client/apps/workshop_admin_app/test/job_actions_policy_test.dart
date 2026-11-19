import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';

/// Table-driven proof of the single action policy (M3/M5/M6/M12).
void main() {
  group('jobActionsFor — every status', () {
    final cases = <String, JobActions>{
      'DRAFT': jobActionsFor(status: 'DRAFT', consentGranted: false),
      'SCHEDULED': jobActionsFor(status: 'SCHEDULED', consentGranted: false),
      'ASSIGNED': jobActionsFor(status: 'ASSIGNED', consentGranted: false),
      'IN_PROGRESS': jobActionsFor(
        status: 'IN_PROGRESS',
        consentGranted: false,
      ),
      'PENDING_REVIEW': jobActionsFor(
        status: 'PENDING_REVIEW',
        consentGranted: true,
      ),
      'APPROVED+consent': jobActionsFor(
        status: 'APPROVED',
        consentGranted: true,
      ),
      'APPROVED-no-consent': jobActionsFor(
        status: 'APPROVED',
        consentGranted: false,
      ),
      'PUBLISHED': jobActionsFor(status: 'PUBLISHED', consentGranted: true),
      'REJECTED': jobActionsFor(status: 'REJECTED', consentGranted: true),
      'CANCELLED': jobActionsFor(status: 'CANCELLED', consentGranted: true),
      'unknown': jobActionsFor(status: 'AWAITING_PARTS', consentGranted: true),
      'empty': jobActionsFor(status: '', consentGranted: true),
    };

    test('assignable only in DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS', () {
      for (final entry in cases.entries) {
        final expected = const {
          'DRAFT',
          'SCHEDULED',
          'ASSIGNED',
          'IN_PROGRESS',
        }.contains(entry.key);
        expect(
          entry.value.canAssign,
          expected,
          reason: '${entry.key}.canAssign',
        );
      }
    });

    test('approve and reject only in PENDING_REVIEW', () {
      for (final entry in cases.entries) {
        final pending = entry.key == 'PENDING_REVIEW';
        expect(
          entry.value.canApprove,
          pending,
          reason: '${entry.key}.canApprove',
        );
        expect(
          entry.value.canReject,
          pending,
          reason: '${entry.key}.canReject',
        );
      }
    });

    test('cancel never in CANCELLED, PUBLISHED, APPROVED, REJECTED', () {
      const forbidden = {'CANCELLED', 'PUBLISHED', 'REJECTED'};
      for (final entry in cases.entries) {
        final expected =
            !forbidden.contains(entry.key) &&
            !entry.key.startsWith('APPROVED') &&
            entry.key != 'unknown' &&
            entry.key != 'empty';
        expect(
          entry.value.canCancel,
          expected,
          reason: '${entry.key}.canCancel',
        );
      }
    });

    test('terminal statuses are read-only', () {
      for (final status in const ['CANCELLED', 'PUBLISHED', 'REJECTED']) {
        final actions = cases[status]!;
        expect(actions.readOnly, isTrue, reason: status);
        expect(actions.canAssign, isFalse, reason: status);
        expect(actions.canCancel, isFalse, reason: status);
      }
      expect(cases['CANCELLED']!.primary, JobPrimaryAction.openJob);
      expect(cases['REJECTED']!.primary, JobPrimaryAction.openJob);
      expect(cases['PUBLISHED']!.primary, JobPrimaryAction.publicLink);
    });

    test('APPROVED hides assign and cancel and needs consent to publish', () {
      final blocked = cases['APPROVED-no-consent']!;
      expect(blocked.canAssign, isFalse);
      expect(blocked.canCancel, isFalse);
      expect(blocked.primary, JobPrimaryAction.none);
      expect(blocked.readOnly, isFalse);

      final ready = cases['APPROVED+consent']!;
      expect(ready.canAssign, isFalse);
      expect(ready.canCancel, isFalse);
      expect(ready.primary, JobPrimaryAction.publishChecklist);
    });

    test('version is required for every mutating action', () {
      for (final status in const [
        'DRAFT',
        'SCHEDULED',
        'ASSIGNED',
        'IN_PROGRESS',
        'PENDING_REVIEW',
      ]) {
        expect(cases[status]!.requiresVersion, isTrue, reason: status);
      }
      for (final status in const [
        'APPROVED+consent',
        'APPROVED-no-consent',
        'PUBLISHED',
        'REJECTED',
        'CANCELLED',
      ]) {
        expect(cases[status]!.requiresVersion, isFalse, reason: status);
      }
    });

    test('unknown status never invents an action and never mutates', () {
      final unknown = cases['unknown']!;
      expect(unknown.primary, JobPrimaryAction.openJob);
      expect(unknown.canAssign, isFalse);
      expect(unknown.canCancel, isFalse);
      expect(unknown.readOnly, isTrue);
      expect(unknown.requiresVersion, isFalse);
    });

    test('each status has exactly one primary kind', () {
      expect(cases['DRAFT']!.primary, JobPrimaryAction.assign);
      expect(cases['SCHEDULED']!.primary, JobPrimaryAction.assign);
      expect(cases['ASSIGNED']!.primary, JobPrimaryAction.openJob);
      expect(cases['IN_PROGRESS']!.primary, JobPrimaryAction.openJob);
      expect(cases['PENDING_REVIEW']!.primary, JobPrimaryAction.reviewApprove);
      expect(cases['PUBLISHED']!.primary, JobPrimaryAction.publicLink);
      expect(cases['REJECTED']!.primary, JobPrimaryAction.openJob);
      expect(cases['CANCELLED']!.primary, JobPrimaryAction.openJob);
    });
  });
}
