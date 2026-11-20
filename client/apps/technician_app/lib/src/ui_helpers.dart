import 'package:design_system/design_system.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/reference_ui.dart';

/// Labels and tones for item-contract enum codes.
///
/// The maps live in `/reference/enums/result` and `/reference/enums/severity`.
/// These helpers only resolve served records; an unknown code is humanized.
String resultLabel(Iterable<ReferenceRecord>? records, String result) =>
    referenceStatusCodeLabel(records, result);

String severityLabel(Iterable<ReferenceRecord>? records, String severity) =>
    referenceStatusCodeLabel(records, severity);

StatusTone resultTone(Iterable<ReferenceRecord>? records, String? result) {
  if (result == null || result.trim().isEmpty) {
    return StatusTone.neutral;
  }
  return referenceStatusCodeTone(records, result);
}
