import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../jobs/queue/jobs_queue_primitives.dart';
import '../../jobs/queue/jobs_queue_style.dart';

/// The item header in the deck language: back, item number + section,
/// 24/800 label, instruction, standard and the safety pill.
///
/// Identity text wraps; nothing here truncates.
class ItemHeader extends StatelessWidget {
  const ItemHeader({
    required this.eyebrow,
    required this.label,
    required this.safety,
    required this.onBack,
    this.instruction,
    this.spec,
    super.key,
  });

  final String eyebrow;
  final String label;
  final String? instruction;
  final String? spec;
  final bool safety;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final specText = (spec ?? '').trim();
    final instructionText = (instruction ?? '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: GestureDetector(
            onTap: onBack,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                size: 21,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eyebrow, maxLines: 2, style: queueEyebrow(context)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: queueText(
                  context,
                  24,
                  weight: FontWeight.w800,
                  height: 29,
                  tracking: -0.5,
                ),
              ),
              if (instructionText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  instructionText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: queueBody(context, color: colors.onSurfaceVariant),
                ),
              ],
              if (specText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        specText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: queueMeta(
                          context,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (safety) ...[
                const SizedBox(height: 8),
                QueueStatusChip(
                  label: UiStrings.of(context)(
                    TechnicianKeys.technicianSafetyCritical,
                  ),
                  tone: StatusTone.danger,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
