import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

/// Shows the backend `409 TRANSLATION_REVIEW_REQUIRED` issue list.
///
/// The review screen lives in Platform Admin, so the workshop dialog lists the
/// exact entities, fields and languages that block publishing and says where to
/// review them. It never collapses the failure into "action failed".
Future<void> showTranslationIssuesDialog(
  BuildContext context,
  AppFailure failure,
) {
  final t = UiStrings.of(context);
  final issues = TranslationIssue.from(failure);
  final spacing = context.spacing;
  final ws = context.ws;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ws.surface,
      title: Text(t(WorkshopAdminKeys.translationReviewRequiredTitle)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(WorkshopAdminKeys.translationReviewRequiredBody),
                style: ws.body.copyWith(color: ws.muted),
              ),
              SizedBox(height: spacing.md),
              for (final issue in issues.take(8))
                Container(
                  margin: EdgeInsets.only(bottom: spacing.xs),
                  padding: EdgeInsets.all(spacing.sm),
                  decoration: BoxDecoration(
                    color: ws.canvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ws.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${issue.entityType} · ${issue.entityId} · '
                        '${issue.field} · ${issue.lang}',
                        style: ws.bodyStrong,
                      ),
                      if (issue.reason.isNotEmpty) ...[
                        SizedBox(height: spacing.xxs),
                        Text(
                          issue.reason,
                          style: ws.body.copyWith(color: ws.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              if (issues.length > 8)
                Text(
                  t(WorkshopAdminKeys.translationIssueMore, {
                    'count': issues.length - 8,
                  }),
                  style: ws.body.copyWith(color: ws.muted),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('translation-issues-close'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t(WorkshopAdminKeys.close)),
        ),
      ],
    ),
  );
}
