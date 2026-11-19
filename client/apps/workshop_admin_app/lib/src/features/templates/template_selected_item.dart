import 'package:workshop_admin_app/src/models.dart';

/// One ordered entry in the template sequence.
///
/// Carries the labels the builder needs to render a row and the master item
/// version id the save payload sends. Same shape as the previous builder's
/// private item, made public so the step widgets can take it.
class TemplateSelectedItem {
  const TemplateSelectedItem({
    required this.masterItemVersionId,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.labelEn,
    required this.labelAr,
    required this.instructionEn,
    required this.instructionAr,
    required this.versionNo,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.stableCode,
  });

  final String masterItemVersionId;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String labelEn;
  final String labelAr;
  final String instructionEn;
  final String instructionAr;
  final int versionNo;
  final String noteRequirement;
  final String evidenceRequirement;
  final String stableCode;

  factory TemplateSelectedItem.fromView(TemplateItemView item) =>
      TemplateSelectedItem(
        masterItemVersionId: item.masterItemVersionId,
        categoryLabelEn: item.categoryLabelEn,
        categoryLabelAr: item.categoryLabelAr,
        labelEn: item.labelEn,
        labelAr: item.labelAr,
        instructionEn: item.instructionEn,
        instructionAr: item.instructionAr,
        versionNo: item.versionNo,
        noteRequirement: item.noteRequirement,
        evidenceRequirement: item.evidenceRequirement,
        stableCode: item.stableCode,
      );

  factory TemplateSelectedItem.fromPublished(PublishedItem item) {
    final en = item.version.translation('en');
    final ar = item.version.translation('ar');
    return TemplateSelectedItem(
      masterItemVersionId: item.versionId,
      categoryLabelEn: item.categoryLabelEn,
      categoryLabelAr: item.categoryLabelAr,
      labelEn: en.label,
      labelAr: ar.label,
      instructionEn: en.instruction,
      instructionAr: ar.instruction,
      versionNo: item.version.versionNo,
      noteRequirement: item.version.noteRequirement,
      evidenceRequirement: item.version.evidenceRequirement,
      stableCode: item.stableCode,
    );
  }

  String label(bool arabic) => arabic ? labelAr : labelEn;
  String category(bool arabic) => arabic ? categoryLabelAr : categoryLabelEn;
}
