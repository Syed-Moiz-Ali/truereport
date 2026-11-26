import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'fieldwork_ui.dart';

/// Asked right after a photo lands: mark it or keep it as is.
///
/// The marked photo uploads as an *additional* photo through the existing
/// queue; nothing leaves the item screen. When the chosen result is a defect,
/// marking is the emphasized action and keeping the photo goes quiet.
class MarkPrompt extends StatelessWidget {
  const MarkPrompt({
    required this.photoBytes,
    required this.defect,
    required this.onMark,
    required this.onDismiss,
    super.key,
  });

  final Uint8List? photoBytes;
  final bool defect;
  final VoidCallback onMark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final tone = defect
        ? context.statusColors.danger
        : context.statusColors.warning;
    final bytes = photoBytes;
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(FieldworkMetrics.controlRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: bytes != null
                ? Image.memory(
                    bytes,
                    height: 132,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, _, _) => const _PromptPlaceholder(),
                  )
                : const _PromptPlaceholder(),
          ),
          const SizedBox(height: 12),
          Text(
            t(TechnicianKeys.technicianSessionMarkPrompt),
            style: fieldworkText(
              context,
              15,
              weight: FontWeight.w800,
              height: 20,
              tracking: -0.2,
              color: tone.foreground,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            t(TechnicianKeys.technicianMarkupHint),
            style: fieldworkText(
              context,
              12,
              height: 17,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (defect) ...[
            FieldworkButton(
              label: t(TechnicianKeys.technicianMarkDamage),
              icon: Icons.brush_outlined,
              expand: true,
              onPressed: onMark,
            ),
            const SizedBox(height: 6),
            FieldworkButton(
              label: t(TechnicianKeys.technicianSessionUseAsIs),
              variant: FieldworkButtonVariant.text,
              height: FieldworkMetrics.secondaryHeight,
              expand: true,
              onPressed: onDismiss,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: FieldworkButton(
                    label: t(TechnicianKeys.technicianMarkDamage),
                    icon: Icons.brush_outlined,
                    variant: FieldworkButtonVariant.tonal,
                    height: FieldworkMetrics.secondaryHeight,
                    expand: true,
                    onPressed: onMark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FieldworkButton(
                    label: t(TechnicianKeys.technicianSessionUseAsIs),
                    variant: FieldworkButtonVariant.ghost,
                    height: FieldworkMetrics.secondaryHeight,
                    expand: true,
                    onPressed: onDismiss,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PromptPlaceholder extends StatelessWidget {
  const _PromptPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 26,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            UiStrings.of(context)(TechnicianKeys.technicianSessionNoPhoto),
            style: fieldworkText(
              context,
              12.5,
              weight: FontWeight.w600,
              height: 17,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
