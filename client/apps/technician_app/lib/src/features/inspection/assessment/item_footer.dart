import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../jobs/queue/deck/deck_primary.dart';
import '../../jobs/queue/jobs_queue_primitives.dart';

/// The pinned item footer: one 56 px primary naming the outcome, plus a
/// secondary capture shortcut while evidence is still owed.
///
/// Read-only callers pass the single Back action and no secondary.
class ItemFooter extends StatelessWidget {
  const ItemFooter({
    required this.primaryLabel,
    required this.onPrimary,
    this.saving = false,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool saving;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secondary = secondaryLabel;
    final secondaryAction = onSecondary;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeckPrimaryButton(
                label: primaryLabel,
                isLoading: saving,
                onPressed: saving ? null : onPrimary,
              ),
              if (secondary != null && secondaryAction != null) ...[
                const SizedBox(height: 8),
                QueueButton(
                  label: secondary,
                  variant: QueueButtonVariant.soft,
                  expand: true,
                  onPressed: secondaryAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
