import 'package:l10n/l10n.dart';

/// Maps master-content lifecycle codes to localized labels.
String contentStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'DRAFT' => l10n.draft,
      'PUBLISHED' => l10n.published,
      'RETIRED' => l10n.retired,
      _ => status,
    };

/// Maps membership role codes to localized labels.
String memberRoleLabel(AppLocalizations l10n, String role) => switch (role) {
  'TECHNICIAN' => l10n.roleTechnician,
  'WORKSHOP_ADMIN' => l10n.roleWorkshopAdmin,
  'PLATFORM_ADMIN' => l10n.rolePlatformAdmin,
  _ => role,
};

/// Maps membership status codes to localized labels.
String memberStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'ACTIVE' => l10n.filterActive,
      'DISABLED' => l10n.disabled,
      'PENDING' => l10n.pending,
      _ => status,
    };
