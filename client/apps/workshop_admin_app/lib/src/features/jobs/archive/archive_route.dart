import 'package:flutter/material.dart';

import 'legacy_archive_page.dart';

/// Pushes the quarantined read-only surface. Kept in `archive/` so no other
/// jobs file has to name the legacy model or page class.
Future<void> openArchive(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const LegacyArchivePage()),
  );
}
