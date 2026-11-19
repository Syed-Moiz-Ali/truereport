import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_error_banner.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_step_rail.dart';

/// Wizard page geometry: a vertical step rail beside a focused form on
/// desktop, a wrapping rail above the form on narrow screens. The page keeps
/// state; this region keeps the layout.
class WizardLayout extends StatelessWidget {
  const WizardLayout({
    required this.current,
    required this.labels,
    required this.error,
    required this.stepBody,
    required this.footer,
    super.key,
  });

  final int current;
  final List<String> labels;
  final String? error;
  final Widget stepBody;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final form = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!wide) ...[
                WizardStepRail(current: current, labels: labels),
                SizedBox(height: spacing.lg),
              ],
              if (error != null) ...[
                WizardErrorBanner(message: error!),
                SizedBox(height: spacing.md),
              ],
              WorkshopCard(
                padding: ws.cardPaddingFor(constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WorkshopSectionHeader(
                      title: labels[current],
                      subtitle: current == 0 ? l10n.scheduleJobSubtitle : null,
                    ),
                    SizedBox(height: spacing.lg),
                    stepBody,
                  ],
                ),
              ),
              SizedBox(height: spacing.lg),
              footer,
            ],
          ),
        );
        return SingleChildScrollView(
          padding: ws.pagePaddingOf(context),
          child: Center(
            child: wide
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: spacing.xl,
                            ),
                            child: WorkshopCard(
                              child: WizardStepRail(
                                current: current,
                                labels: labels,
                                vertical: true,
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Center(child: form)),
                      ],
                    ),
                  )
                : form,
          ),
        );
      },
    );
  }
}
