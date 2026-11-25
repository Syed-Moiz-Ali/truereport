import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../jobs/queue/jobs_queue_primitives.dart';
import '../../jobs/queue/jobs_queue_style.dart';

/// Asked right after a photo lands: mark it or keep it as is.
///
/// The marked photo uploads as an *additional* photo through the existing
/// queue; nothing leaves the item screen. When the chosen result is a defect,
/// marking is the emphasized primary action.
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
    final bytes = photoBytes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                bytes,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, _, _) => const _PromptPlaceholder(),
              ),
            ),
          ] else
            const _PromptPlaceholder(),
          const SizedBox(height: 12),
          Text(
            t(TechnicianKeys.technicianSessionMarkPrompt),
            style: queueText(
              context,
              16,
              weight: FontWeight.w700,
              height: 22,
              tracking: -0.1,
            ),
          ),
          const SizedBox(height: 12),
          if (defect) ...[
            QueueButton(
              label: t(TechnicianKeys.technicianMarkDamage),
              variant: QueueButtonVariant.primary,
              icon: Icons.brush_outlined,
              expand: true,
              onPressed: onMark,
            ),
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    t(TechnicianKeys.technicianSessionUseAsIs),
                    style: queueText(
                      context,
                      14,
                      weight: FontWeight.w700,
                      height: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: QueueButton(
                    label: t(TechnicianKeys.technicianMarkDamage),
                    variant: QueueButtonVariant.soft,
                    icon: Icons.brush_outlined,
                    expand: true,
                    onPressed: onMark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: QueueButton(
                    label: t(TechnicianKeys.technicianSessionUseAsIs),
                    variant: QueueButtonVariant.soft,
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
    final colors = context.colors;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 24,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            UiStrings.of(context)(TechnicianKeys.technicianSessionNoPhoto),
            style: queueText(
              context,
              14,
              weight: FontWeight.w600,
              height: 20,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
