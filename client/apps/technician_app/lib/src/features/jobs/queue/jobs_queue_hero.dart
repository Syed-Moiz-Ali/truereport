import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import '../../../inspection_models.dart';
import '../../../reference_ui.dart';
import '../../../shared/technician_intl.dart';
import 'jobs_queue_format.dart';
import 'jobs_queue_primitives.dart';
import 'jobs_queue_style.dart';

/// The one focal job of the shift, shaped as a punched day pass.
class QueueNextUpBand extends ConsumerWidget {
  const QueueNextUpBand({required this.job, required this.onOpen, super.key});

  final JobSummary job;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final time = queueTimeLabel(job);
    final status = jobStatusLabel(ref, job.status);
    return Semantics(
      container: true,
      label: '${job.reference}, ${_vehicle(job)}, ${job.customerName}',
      child: ClipPath(
        clipper: const _PassClip(),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
          color: context.brand.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (time.isNotEmpty) ...[
                    Text(
                      time,
                      textDirection: TextDirection.ltr,
                      style: queueText(
                        context,
                        12.5,
                        weight: FontWeight.w700,
                        height: 16,
                        tabular: true,
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      status.toUpperCase(),
                      style: queueEyebrow(
                        context,
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    t(TechnicianKeys.technicianNextUp).toUpperCase(),
                    style: queueEyebrow(
                      context,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QueuePlate(
                job.vehiclePlate ?? job.reference,
                large: true,
                onDark: true,
              ),
              const SizedBox(height: 10),
              Text(
                _vehicle(job),
                maxLines: 2,
                style: queueText(
                  context,
                  24,
                  weight: FontWeight.w700,
                  height: 30,
                  tracking: -0.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                job.customerName,
                maxLines: 2,
                style: queueText(
                  context,
                  13.5,
                  height: 19,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: QueueProgressBar(
                      value: job.completedItems,
                      total: job.totalItems,
                      onDark: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatCountPairLocalized(
                      job.completedItems,
                      job.totalItems,
                      locale,
                    ),
                    textDirection: TextDirection.ltr,
                    style: queueText(
                      context,
                      12.5,
                      weight: FontWeight.w700,
                      height: 16,
                      tabular: true,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              QueueButton(
                label: t(TechnicianKeys.jobsOpenJob),
                variant: QueueButtonVariant.onDark,
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassClip extends CustomClipper<Path> {
  const _PassClip();

  @override
  Path getClip(Size size) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(QueueMetrics.radiusCard),
        ),
      );
    const notch = 9.0;
    return Path.combine(
      PathOperation.difference,
      body,
      Path()
        ..addOval(
          Rect.fromCircle(center: Offset(0, size.height * 0.72), radius: notch),
        )
        ..addOval(
          Rect.fromCircle(
            center: Offset(size.width, size.height * 0.72),
            radius: notch,
          ),
        ),
    );
  }

  @override
  bool shouldReclip(_PassClip oldClipper) => false;
}

String _vehicle(JobSummary job) {
  final year = job.vehicleYear;
  final base = '${job.vehicleMake} ${job.vehicleModel}'.trim();
  if (base.isEmpty) {
    return job.vehiclePlate ?? job.reference;
  }
  return year == null ? base : '$base $year';
}
