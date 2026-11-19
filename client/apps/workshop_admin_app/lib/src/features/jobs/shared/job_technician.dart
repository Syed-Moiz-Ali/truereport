import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Resolves the displayed technician name without ever leaking a raw id.
///
/// `CleanJob.assignedTechnicianName` is authoritative when it is a real name.
/// If it is null, empty, or identical to the id (some mutation responses echo
/// the id), the staff directory resolves the id; an unresolvable id reads
/// "Unassigned" rather than a UUID.
String jobTechnicianName(
  AppLocalizations l10n,
  CleanJob job,
  List<StaffMember>? staff,
) {
  final id = job.assignedTechnicianId?.trim();
  if (id == null || id.isEmpty) {
    return l10n.unassigned;
  }
  final name = job.assignedTechnicianName?.trim();
  if (name != null && name.isNotEmpty && name != id) {
    return name;
  }
  for (final member in staff ?? const <StaffMember>[]) {
    if (member.userId == id) {
      final resolved = member.displayName.trim();
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
  }
  return l10n.unassigned;
}
