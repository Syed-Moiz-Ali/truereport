import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../jobs_queue_style.dart';

/// The deck page header: eyebrow, brand mark + display title, counts line.
///
/// Soft mint squircle, never a logo image; the technician's avatar stays
/// top-right on every width. All copy resolves through [UiStrings].
class DeckHeader extends StatelessWidget {
  const DeckHeader({
    required this.toStart,
    required this.inProgress,
    required this.technicianName,
    required this.onProfile,
    super.key,
  });

  final int toStart;
  final int inProgress;
  final String technicianName;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final brand = context.brand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(TechnicianKeys.technicianDeckEyebrow),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: queueEyebrow(context),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: brand.container,
                        borderRadius: BorderRadius.circular(context.radii.lg),
                      ),
                      child: Icon(
                        Icons.build_rounded,
                        size: 22,
                        color: brand.onContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(TechnicianKeys.technicianDeckTitle),
                      style: queueDeckTitle(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t(TechnicianKeys.technicianQueueSummary, {
                  'toStart': toStart,
                  'inProgress': inProgress,
                }),
                style: queueText(
                  context,
                  13,
                  height: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          child: GestureDetector(
            onTap: onProfile,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: TechnicianAvatar(
                  name: technicianName,
                  size: 38,
                  semanticLabel: t(TechnicianKeys.technicianProfileTitle),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
