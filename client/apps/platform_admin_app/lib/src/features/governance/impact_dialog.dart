import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_states.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

import 'package:l10n/l10n.dart';

Future<void> showImpactDialog(
  BuildContext context,
  WidgetRef ref, {
  required String entityType,
  required String entityId,
}) async {
  ref.invalidate(impactProvider(ImpactKey(entityType, entityId)));
  final strings = ref.read(uiStringsProvider);
  await showPlatformDialog<void>(
    context: context,
    title: strings.tKey(PlatformAdminKeys.dialogImpactTitle),
    body: _ImpactBody(entityType: entityType, entityId: entityId),
    actionsBuilder: (dialogContext) => [
      PlatformSecondaryButton(
        label: ProviderScope.containerOf(
          dialogContext,
          listen: false,
        ).read(uiStringsProvider).tKey(CommonKeys.buttonClose),
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
    final strings = ref.watch(uiStringsProvider);
    final impact = ref.watch(impactProvider(ImpactKey(entityType, entityId)));

    return impact.when(
      loading: () => const PlatformLoadingView(),
      error: (error, stackTrace) => PlatformErrorView(
        message: strings.tKey(CommonKeys.statusUnhealthy),
        retryLabel: strings.tKey(CommonKeys.buttonRetry),
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
                status: data.blocked
                    ? strings.tKey(CommonKeys.statusBlocked)
                    : strings.tKey(CommonKeys.statusNotBlocked),
              ),
              PlatformMetaPill(label: data.entityType, value: data.entityId),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PlatformMetaPill(
                label: strings.tKey(
                  PlatformAdminKeys.dialogImpactAffectedTemplates,
                ),
                value: '${data.affectedTemplates}',
              ),
              PlatformMetaPill(
                label: strings.tKey(
                  PlatformAdminKeys.dialogImpactAffectedItems,
                ),
                value: '${data.affectedItems}',
              ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.dialogImpactAffectedJobs),
                value: '${data.affectedJobs}',
              ),
            ],
          ),
          if (data.templateCodes.isNotEmpty) ...[
            const SizedBox(height: 16),
            PlatformSectionHeader(
              title: strings.tKey(
                PlatformAdminKeys.dialogImpactAffectedTemplates,
              ),
            ),
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
            PlatformSectionHeader(
              title: strings.tKey(PlatformAdminKeys.dialogImpactAffectedItems),
            ),
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
            Text(data.messageEn, style: PtTheme.font(13, color: PtTheme.muted)),
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
