import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_assignment.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_customer_vehicle.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_inspection.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_review_publication.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_states.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_summary.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Scrollable body composition: identity band, then two columns at ≥1000 px
/// (start: customer+vehicle, inspection; end: assignment, review+publication).
class JobDetailBody extends StatelessWidget {
  const JobDetailBody({required this.job, required this.banner, super.key});

  final CleanJob job;
  final String? banner;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return SingleChildScrollView(
      padding: ws.pagePaddingOf(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner != null) ...[
                  JobDetailConflictBanner(message: banner!),
                  SizedBox(height: spacing.lg),
                ],
                if (job.version == null) ...[
                  const JobDetailVersionNote(),
                  SizedBox(height: spacing.lg),
                ],
                JobDetailSummary(job: job),
                SizedBox(height: spacing.xxl),
                LayoutBuilder(
                  builder: (context, _) {
                    final start = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JobDetailCustomerVehicle(job: job),
                        SizedBox(height: spacing.xxl),
                        JobDetailInspection(job: job),
                      ],
                    );
                    final end = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JobDetailAssignment(job: job),
                        SizedBox(height: spacing.xxl),
                        JobDetailReviewPublication(job: job),
                      ],
                    );
                    final wide = MediaQuery.sizeOf(context).width >= 1000;
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          start,
                          SizedBox(height: spacing.xxl),
                          end,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: start),
                        SizedBox(width: spacing.xl),
                        Expanded(flex: 5, child: end),
                      ],
                    );
                  },
                ),
                SizedBox(height: spacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
