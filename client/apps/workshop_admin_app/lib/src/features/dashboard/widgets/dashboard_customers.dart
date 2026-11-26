import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_controls.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Customer pulse for the selected range: distinct customers served, repeat
/// customers, and the five busiest. Names are the ones already on the jobs.
class DashboardCustomersCard extends StatelessWidget {
  const DashboardCustomersCard({
    required this.customers,
    required this.onOpenQueue,
    super.key,
  });

  final DashboardCustomers customers;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final maxJobs = customers.top.isEmpty
        ? 1
        : customers.top
              .map((customer) => customer.jobs)
              .fold<int>(1, (best, value) => value > best ? value : best);

    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t(WorkshopAdminKeys.dashCustomersTitle),
                  style: DashboardType.cardTitle(ws),
                ),
              ),
              QueueTextAction(
                label: t(WorkshopAdminKeys.dashViewAll),
                onTap: onOpenQueue,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CustomerStat(
                  label: t(WorkshopAdminKeys.dashCustomersServed),
                  value: number.format(customers.served),
                  color: ws.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CustomerStat(
                  label: t(WorkshopAdminKeys.dashCustomersRepeat),
                  value: number.format(customers.repeat),
                  color: ws.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: ws.border),
          if (customers.top.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 14),
              child: Text(
                t(WorkshopAdminKeys.dashCustomersEmpty),
                style: ws.meta.copyWith(color: ws.muted),
              ),
            )
          else
            for (var index = 0; index < customers.top.length; index++) ...[
              if (index > 0) Container(height: 1, color: ws.border),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            customers.top[index].name,
                            style: ws.body.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: ws.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DashboardShape.pill,
                            ),
                            child: Container(
                              height: 4,
                              color: ws.canvas,
                              child: FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor:
                                    (customers.top[index].jobs / maxJobs).clamp(
                                      0,
                                      1,
                                    ),
                                child: ColoredBox(color: ws.accent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      t(WorkshopAdminKeys.dashJobsCount, {
                        'count': customers.top[index].jobs,
                      }),
                      style: ws.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ws.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _CustomerStat extends StatelessWidget {
  const _CustomerStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: ws.meta.copyWith(fontSize: 11.5, color: ws.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: DashboardType.tileNumber(ws)),
      ],
    );
  }
}
