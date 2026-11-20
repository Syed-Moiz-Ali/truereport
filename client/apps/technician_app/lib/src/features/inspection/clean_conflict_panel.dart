import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';

class ConflictViewData {
  const ConflictViewData({
    required this.id,
    required this.itemCode,
    required this.clientPayload,
    required this.serverPayload,
  });

  final String? id;
  final String itemCode;
  final String? clientPayload;
  final String? serverPayload;
}

class ConflictPanel extends StatelessWidget {
  const ConflictPanel({
    required this.conflicts,
    required this.onReload,
    this.reloaded = false,
    super.key,
  });

  final List<ConflictViewData> conflicts;
  final ValueChanged<ConflictViewData> onReload;
  final bool reloaded;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    return AppCard(
      variant: AppCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TechnicianSectionTitle(
            title: t(TechnicianKeys.technicianSyncConflictTitle),
            subtitle: reloaded
                ? t(TechnicianKeys.technicianConflictReloaded)
                : t(TechnicianKeys.technicianConflictExists),
          ),
          if (conflicts.isEmpty) ...[
            SizedBox(height: spacing.sm),
            Text(
              t(TechnicianKeys.technicianNoConflicts),
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ] else
            for (final conflict in conflicts) ...[
              SizedBox(height: spacing.md),
              _ConflictCard(conflict: conflict, onReload: onReload),
            ],
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict, required this.onReload});

  final ConflictViewData conflict;
  final ValueChanged<ConflictViewData> onReload;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsetsDirectional.all(spacing.md),
      decoration: BoxDecoration(
        color: context.statusColors.warning.background,
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            conflict.itemCode,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.sm),
          _PayloadBlock(
            label: t(TechnicianKeys.technicianServerPayload),
            payload: conflict.serverPayload,
          ),
          SizedBox(height: spacing.sm),
          _PayloadBlock(
            label: t(TechnicianKeys.technicianClientPayload),
            payload: conflict.clientPayload,
          ),
          SizedBox(height: spacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              label: t(TechnicianKeys.technicianReloadServer),
              icon: Icons.refresh,
              variant: AppButtonVariant.tonal,
              onPressed: () => onReload(conflict),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayloadBlock extends StatelessWidget {
  const _PayloadBlock({required this.label, required this.payload});

  final String label;
  final String? payload;

  @override
  Widget build(BuildContext context) {
    final text = prettyPayload(payload);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: context.spacing.huge * 3),
          child: SingleChildScrollView(
            child: SelectableText(text, style: context.texts.bodySmall),
          ),
        ),
      ],
    );
  }
}
