import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_states.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

Future<void> showImpactDialog(
  BuildContext context,
  WidgetRef ref, {
  required String entityType,
  required String entityId,
}) async {
  ref.invalidate(impactProvider(ImpactKey(entityType, entityId)));
  final l10n = AppLocalizations.of(context);
  await showPlatformDialog<void>(
    context: context,
    title: l10n.impactAnalysis,
    body: _ImpactBody(entityType: entityType, entityId: entityId),
    actionsBuilder: (dialogContext) => [
      PlatformSecondaryButton(
        label: AppLocalizations.of(dialogContext).close,
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    ],
  );
}

Future<void> showImpactForEntity(
  BuildContext context,
  WidgetRef ref, {
  required String entityType,
  required String entityId,
}) {
  return showImpactDialog(
    context,
    ref,
    entityType: entityType,
    entityId: entityId,
  );
}

class _ImpactBody extends ConsumerWidget {
  const _ImpactBody({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final impact = ref.watch(impactProvider(ImpactKey(entityType, entityId)));

    return impact.when(
      loading: () => const PlatformLoadingView(),
      error: (error, stackTrace) => PlatformErrorView(
        message: l10n.unhealthy,
        retryLabel: l10n.retry,
        onRetry: () =>
            ref.invalidate(impactProvider(ImpactKey(entityType, entityId))),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformStatusChip(
                status: data.blocked ? l10n.blocked : l10n.notBlocked,
              ),
              PlatformMetaPill(
                label: data.entityType,
                value: data.entityId,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PlatformMetaPill(
                label: l10n.affectedTemplates,
                value: '${data.affectedTemplates}',
              ),
              PlatformMetaPill(
                label: l10n.affectedItems,
                value: '${data.affectedItems}',
              ),
              PlatformMetaPill(
                label: l10n.affectedJobs,
                value: '${data.affectedJobs}',
              ),
            ],
          ),
          if (data.templateCodes.isNotEmpty) ...[
            const SizedBox(height: 16),
            PlatformSectionHeader(title: l10n.affectedTemplates),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in data.templateCodes)
                  PlatformStatusChip(status: code),
              ],
            ),
          ],
          if (data.itemCodes.isNotEmpty) ...[
            const SizedBox(height: 16),
            PlatformSectionHeader(title: l10n.affectedItems),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in data.itemCodes)
                  PlatformStatusChip(status: code),
              ],
            ),
          ],
          if (data.messageEn.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              data.messageEn,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
          if (data.messageAr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data.messageAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}
