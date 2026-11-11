import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_providers.dart';
import '../../platform_theme.dart';

Future<void> showImpactDialog(
  BuildContext context,
  WidgetRef ref, {
  required String entityType,
  required String entityId,
}) {
  ref.invalidate(impactProvider(ImpactKey(entityType, entityId)));
  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _ImpactDialog(entityType: entityType, entityId: entityId),
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

class _ImpactDialog extends ConsumerWidget {
  const _ImpactDialog({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final impact = ref.watch(impactProvider(ImpactKey(entityType, entityId)));

    return AlertDialog(
      title: Text(l10n.impactAnalysis),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: impact.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: PtTheme.deepGreen),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loading,
                    style: PtTheme.font(13, color: PtTheme.muted),
                  ),
                ],
              ),
            ),
            error: (error, stackTrace) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.unhealthy,
                  style: PtTheme.font(
                    14,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                    impactProvider(ImpactKey(entityType, entityId)),
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ImpactChip(
                      label: data.blocked ? l10n.blocked : l10n.notBlocked,
                      color: data.blocked ? PtTheme.rose : PtTheme.emerald,
                    ),
                    _ImpactChip(
                      label: '${data.entityType}: ${data.entityId}',
                      color: PtTheme.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatTile(
                      label: l10n.affectedTemplates,
                      value: '${data.affectedTemplates}',
                    ),
                    _StatTile(
                      label: l10n.affectedItems,
                      value: '${data.affectedItems}',
                    ),
                    _StatTile(
                      label: l10n.affectedJobs,
                      value: '${data.affectedJobs}',
                    ),
                  ],
                ),
                if (data.templateCodes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.affectedTemplates,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final code in data.templateCodes)
                        _ImpactChip(label: code, color: PtTheme.deepGreen),
                    ],
                  ),
                ],
                if (data.itemCodes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.affectedItems,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final code in data.itemCodes)
                        _ImpactChip(label: code, color: PtTheme.amber),
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: PtTheme.font(
              18,
              weight: FontWeight.w800,
              color: PtTheme.ink,
            ),
          ),
          Text(label, style: PtTheme.font(11, color: PtTheme.muted)),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
