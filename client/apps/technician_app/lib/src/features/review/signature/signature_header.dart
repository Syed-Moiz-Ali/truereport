import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../../inspection_models.dart';
import '../../jobs/queue/jobs_queue_format.dart';
import '../../jobs/queue/jobs_queue_primitives.dart';
import '../../jobs/queue/jobs_queue_style.dart';

/// Deck header for the signature screen: back, vehicle identity, plate +
/// reference. Mirrors the summary header minus its status/count line — the
/// card below already names the job of this screen.
class SignatureHeader extends StatelessWidget {
  const SignatureHeader({required this.job, required this.onBack, super.key});

  final JobSummary? job;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final vehicle = job == null ? '' : queueVehicleLabel(job!);
    final plate = (job?.vehiclePlate ?? '').trim();
    final reference = (job?.reference ?? '').trim();
    final showReference =
        reference.isNotEmpty && plate.isNotEmpty && plate != reference;
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
              Text(
                vehicle,
                maxLines: 2,
                style: queueText(
                  context,
                  24,
                  weight: FontWeight.w800,
                  height: 29,
                  tracking: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  QueuePlate(plate.isNotEmpty ? plate : reference),
                  if (showReference)
                    Text(
                      reference,
                      textDirection: TextDirection.ltr,
                      style: queueText(
                        context,
                        12.5,
                        height: 18,
                        tabular: true,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The screen title row inside the signing card.
class SignatureCardTitle extends StatelessWidget {
  const SignatureCardTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      UiStrings.of(context)(TechnicianKeys.technicianSignatureTitle),
      style: queueText(
        context,
        16,
        weight: FontWeight.w700,
        height: 22,
        tracking: -0.1,
      ),
    );
  }
}
