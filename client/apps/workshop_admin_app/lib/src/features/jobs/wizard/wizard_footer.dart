import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Back / Next / Create. The primary keeps the stable `jobs-wizard-next` key
/// on every step, and on a phone both actions are full-width 46 px targets.
class WizardFooter extends StatelessWidget {
  const WizardFooter({
    required this.isLast,
    required this.busy,
    required this.canGoBack,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final bool isLast;
  final bool busy;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final back = WorkshopButton(
      key: const Key('jobs-wizard-back'),
      label: l10n.commonBack,
      icon: Icons.chevron_left,
      variant: WorkshopButtonVariant.secondary,
      onPressed: busy || !canGoBack ? null : onBack,
      expand: true,
    );
    final next = WorkshopButton(
      key: const Key('jobs-wizard-next'),
      label: isLast ? l10n.jobsCreateCta : l10n.commonNext,
      icon: isLast ? Icons.check : Icons.chevron_right,
      isLoading: busy,
      onPressed: busy ? null : onNext,
      expand: true,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canGoBack) ...[back, SizedBox(height: spacing.sm)],
              next,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (canGoBack) ...[
              SizedBox(width: 160, child: back),
              SizedBox(width: spacing.sm),
            ],
            SizedBox(width: 200, child: next),
          ],
        );
      },
    );
  }
}
