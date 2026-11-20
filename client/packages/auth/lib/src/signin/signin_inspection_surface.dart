import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'signin_example.dart';
import 'signin_primitives.dart';
import 'signin_keys.dart';

/// The bay window: the labelled example job, its vehicle drawn top-down, and
/// the checklist as 24 physical ticks.
///
/// This is the screen's only image and its only motion. Everything on it is an
/// example, stated in copy and in semantics — never a claim about the user's
/// data. The chassis drawing is pinned LTR by [WorkshopChassisMark]; labels and
/// rows mirror with the page.
///
/// RTL note: only data-like Latin runs (`exampleVehicle`, the plate/customer
/// line, the technician's name) are wrapped in LTR. The progress figure is
/// **not** isolated — the ARB already isolates the percent, and forcing an LTR
/// base on the whole phrase reorders the Arabic counts.
class SigninInspectionSurface extends StatelessWidget {
  const SigninInspectionSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final t = UiStrings.of(context);
    final progress = t(SignInKeys.signInExampleProgress, {'done': exampleDone, 'total': exampleTotal, 'percent': examplePercent});

    return Semantics(
      container: true,
      label: '${t(SignInKeys.signInExampleLabel)} · $exampleVehicle',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxWidth >= 600;
          return Container(
            color: ws.ink,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: WorkshopGridPainter(
                        color: ws.onAccent.withValues(alpha: 0.05),
                        step: 56,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: roomy ? 96 : 32,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: WorkshopChassisMark(
                      width: roomy ? 340 : 260,
                      color: ws.onAccent.withValues(alpha: 0.26),
                    ),
                  ),
                ),
                // Fill the surface: a loose Stack child made the Column size to
                // its widest child, which collapsed the checklist row to the
                // left third and wrapped the Arabic figure.
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      roomy ? spacing.massive : spacing.xxl,
                      spacing.xl,
                      spacing.xxl,
                      spacing.xl,
                    ),
                    // Stretch so the checklist row and the technician row span
                    // the surface instead of collapsing to intrinsic width.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: ws.onAccent.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Flexible(
                              child: Text(
                                t(SignInKeys.signInExampleLabel).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ws.eyebrow.copyWith(
                                  color: ws.onAccent.withValues(alpha: 0.62),
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.sm),
                        _ltr(
                          Text(
                            exampleVehicle,
                            style: ws.pageTitle.copyWith(
                              color: ws.onAccent,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.xs),
                        _ltr(
                          Text(
                            '$examplePlate  ·  $exampleCustomer',
                            style: ws.meta.copyWith(
                              color: ws.onAccent.withValues(alpha: 0.62),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // `Expanded` (not `Flexible` + `Spacer`): the two
                            // flexible children used to split the free space
                            // evenly, so the figure sat mid-row and the Arabic
                            // phrase wrapped.
                            Expanded(
                              child: Text(
                                t(SignInKeys.signInExampleChecklist),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ws.eyebrow.copyWith(
                                  color: ws.onAccent.withValues(alpha: 0.62),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Text(
                              progress,
                              maxLines: 1,
                              softWrap: false,
                              style: ws.sectionTitle.copyWith(
                                color: ws.onAccent,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.md),
                        // Decorative: the same figure is visible immediately
                        // above, so a semantic label here would announce twice.
                        WorkshopTickSpine(
                          done: exampleDone,
                          total: exampleTotal,
                          fillColor: ws.onAccent.withValues(alpha: 0.85),
                          trackColor: ws.onAccent.withValues(alpha: 0.16),
                        ),
                        SizedBox(height: spacing.lg),
                        Row(
                          children: [
                            const WorkshopAvatar(
                              initials: exampleInitials,
                              semanticLabel: exampleTechnician,
                              size: 22,
                            ),
                            SizedBox(width: spacing.sm),
                            Expanded(
                              child: _ltr(
                                Text(
                                  '$exampleTechnician · '
                                  '${t(SignInKeys.roleLeadTechnician)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ws.meta.copyWith(color: ws.onAccent),
                                ),
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Text(
                              t(SignInKeys.signInExampleStarted, {'minutes': exampleStartedMinutes}),
                              style: ws.meta.copyWith(
                                color: ws.onAccent.withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Latin, numeric and plate values must never be reordered by Arabic bidi.
Widget _ltr(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);
