import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/inspection_models.dart';

ChecklistItem _item(List<EvidenceRule> rules) => ChecklistItem.fromJson({
  'evidenceRules': rules.map((rule) => rule.toJson()).toList(),
});

void main() {
  test('defaults mirror the server: 1 photo, 1 video, 2 for a defect', () {
    final item = _item(const []);
    final clean = EvidenceRequirement.forResult(item, 'NO_ISSUE_OBSERVED');
    final defect = EvidenceRequirement.forResult(item, 'DEFECT_FOUND');

    expect(clean.minPhotos, 1);
    expect(clean.minVideos, 1);
    expect(defect.minPhotos, 2);
    expect(defect.minVideos, 1);
  });

  test('a rule can raise but never lower the server defaults', () {
    final item = _item([
      const EvidenceRule(
        resultCode: 'NO_ISSUE_OBSERVED',
        minPhotos: 0,
        minVideos: 0,
        minNotesChars: 12,
        requiredEvidenceType: null,
      ),
    ]);
    final requirement = EvidenceRequirement.forResult(
      item,
      'NO_ISSUE_OBSERVED',
    );

    expect(requirement.minPhotos, 1);
    expect(requirement.minVideos, 1);
    expect(requirement.minNotesChars, 12);
  });

  test('the highest matching rule wins for counts and notes', () {
    final item = _item([
      const EvidenceRule(
        resultCode: 'DEFECT_FOUND',
        minPhotos: 3,
        minVideos: 2,
        minNotesChars: 20,
        requiredEvidenceType: 'DOCUMENT',
      ),
      const EvidenceRule(
        resultCode: 'DEFECT_FOUND',
        minPhotos: 1,
        minVideos: 0,
        minNotesChars: 8,
        requiredEvidenceType: 'PHOTO',
      ),
    ]);
    final requirement = EvidenceRequirement.forResult(item, 'DEFECT_FOUND');

    expect(requirement.minPhotos, 3);
    expect(requirement.minVideos, 2);
    expect(requirement.minNotesChars, 8);
    expect(requirement.requiredEvidenceType, 'PHOTO');
    expect(requirement.requiresDocument, isFalse);
  });

  test('required type counts are resolved by evidence type', () {
    const requirement = EvidenceRequirement(
      minPhotos: 1,
      minVideos: 1,
      requiredEvidenceType: 'DOCUMENT',
      minNotesChars: 0,
    );

    expect(
      requirement.countFor('DOCUMENT', photos: 2, videos: 1, documents: 0),
      0,
    );
    expect(requirement.requiresDocument, isTrue);
  });
}
