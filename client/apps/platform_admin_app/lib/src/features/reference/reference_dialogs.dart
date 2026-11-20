import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../platform_theme.dart';

/// Shows the impact counts fetched before retiring and asks for confirmation.
Future<bool?> showReferenceRetireDialog({
  required BuildContext context,
  required UiMessageStrings strings,
  required String code,
  required ReferenceImpact impact,
}) {
  return showPlatformDialog<bool>(
    context: context,
    title: strings.tKey(PlatformAdminKeys.referenceImpactTitle),
    body: Container(
      key: const Key('reference-impact-dialog'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            impact.isEmpty
                ? strings.tKey(PlatformAdminKeys.referenceImpactClean)
                : strings.tArgsKey(
                    PlatformAdminKeys.referenceImpactCounts,
                    <String, Object?>{
                      'items': impact.items,
                      'jobs': impact.jobs,
                      'templates': impact.templates,
                      'documents': impact.documents,
                    },
                  ),
            style: PtTheme.font(13, lineHeight: 19),
          ),
          const SizedBox(height: 10),
          Text(
            strings.tArgsKey(PlatformAdminKeys.referenceImpactConfirm, {
              'code': code,
            }),
            style: PtTheme.bodyMuted,
          ),
        ],
      ),
    ),
    actionsBuilder: (dialogContext) => <Widget>[
      PlatformSecondaryButton(
        label: strings.tKey(CommonKeys.buttonCancel),
        onPressed: () => Navigator.of(dialogContext).pop(false),
      ),
      PlatformDestructiveButton(
        key: const Key('reference-impact-retire'),
        label: strings.tKey(PlatformAdminKeys.referenceRetire),
        icon: Icons.archive_outlined,
        onPressed: () => Navigator.of(dialogContext).pop(true),
      ),
    ],
  );
}

/// Shown when the server answers 409 `REFERENCE_IN_USE`.
///
/// The record stays published; the dialog only reports the real counts.
Future<void> showReferenceInUseDialog({
  required BuildContext context,
  required UiMessageStrings strings,
  required ReferenceImpact impact,
}) {
  return showPlatformDialog<void>(
    context: context,
    title: strings.tKey(PlatformAdminKeys.referenceInUseTitle),
    body: Container(
      key: const Key('reference-in-use-dialog'),
      child: Text(
        strings.tArgsKey(
          PlatformAdminKeys.referenceInUseBody,
          <String, Object?>{
            'items': impact.items,
            'jobs': impact.jobs,
            'templates': impact.templates,
            'documents': impact.documents,
          },
        ),
        style: PtTheme.font(13, lineHeight: 19),
      ),
    ),
    actionsBuilder: (dialogContext) => <Widget>[
      PlatformSecondaryButton(
        key: const Key('reference-in-use-close'),
        label: strings.tKey(CommonKeys.buttonClose),
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    ],
  );
}
