import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Shows the 409 publish-gate issue list with a link to the review queue.
///
/// Returns true when the operator opened the queue.
Future<bool> showTranslationIssuesDialog(
  BuildContext context,
  AppFailure failure,
) async {
  final issues = TranslationIssue.from(failure);
  final strings = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(uiStringsProvider);
  final lang = issues.isEmpty ? '' : issues.first.lang;
  final opened = await showPlatformDialog<bool>(
    context: context,
    title: strings.tKey(PlatformAdminKeys.pageTranslationReviewBlockedTitle),
    maxWidth: 640,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.pageTranslationReviewBlockedBody),
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
        ),
        const SizedBox(height: 12),
        for (final issue in issues.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TranslationIssueRow(issue: issue, strings: strings),
          ),
        if (issues.length > 8)
          Text(
            strings.tArgsKey(PlatformAdminKeys.pageTranslationReviewIssueMore, {
              'count': issues.length - 8,
            }),
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
      ],
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: Text(strings.tKey(CommonKeys.buttonClose)),
      ),
      PlatformPrimaryButton(
        key: const Key('translation-issues-open-review'),
        label: strings.tKey(PlatformAdminKeys.pageTranslationReviewBlockedOpen),
        onPressed: () => Navigator.of(dialogContext).pop(true),
      ),
    ],
  );
  if (opened != true || !context.mounted) return false;
  final query = lang.isEmpty ? '' : '?lang=$lang';
  context.go('/configuration/translations$query');
  return true;
}

/// One issue line: entity, field, language and reason.
class TranslationIssueRow extends StatelessWidget {
  const TranslationIssueRow({
    required this.issue,
    required this.strings,
    super.key,
  });

  final TranslationIssue issue;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${issue.entityType} · ${issue.entityId} · ${issue.field} · '
            '${issue.lang}',
            style: PtTheme.font(12, weight: FontWeight.w700),
          ),
          if (issue.reason.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              issue.reason,
              style: PtTheme.font(12, lineHeight: 17, color: PtTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}
