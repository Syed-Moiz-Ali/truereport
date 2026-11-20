import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_models.dart';
import '../../../platform_theme.dart';
import '../workshop_status.dart';
import 'atlas_ui.dart';

int workshopStaffTotal(HierarchyWorkshop workshop) {
  return workshop.admins.length +
      workshop.technicians.length +
      workshop.pendingInvitations.length;
}

/// Record header shared by the workspace pane and the full detail page.
class WorkshopRecordHeader extends StatelessWidget {
  const WorkshopRecordHeader({
    super.key,
    required this.strings,
    required this.workshop,
    required this.onEdit,
    required this.onToggleStatus,
    this.onViewDetails,
  });

  final UiMessageStrings strings;
  final HierarchyWorkshop workshop;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final isActive = workshop.status.toUpperCase() == 'ACTIVE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AtlasMonogram(name: workshop.name, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            workshop.name,
                            style: Atlas.text(
                              23,
                              weight: FontWeight.w800,
                              tracking: -0.5,
                              height: 1.2,
                            ),
                          ),
                          AtlasPill(
                            label: workshopStatusLabel(
                              strings,
                              workshop.status,
                            ),
                            tone: workshopTone(workshop.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: PtTheme.muted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              (workshop.branchName ?? '').trim().isEmpty
                                  ? '—'
                                  : workshop.branchName!,
                              style: Atlas.text(12.5, color: PtTheme.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onViewDetails != null)
                  AtlasButton(
                    label: strings.tKey(PlatformAdminKeys.buttonViewDetails),
                    icon: Icons.arrow_outward_rounded,
                    onPressed: onViewDetails,
                  ),
                AtlasButton(
                  label: strings.tKey(CommonKeys.buttonEdit),
                  icon: Icons.edit_outlined,
                  variant: AtlasButtonVariant.secondary,
                  onPressed: onEdit,
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: PtTheme.border,
                ),
                AtlasButton(
                  label: strings.tKey(
                    isActive
                        ? PlatformAdminKeys.buttonWorkshopDeactivate
                        : PlatformAdminKeys.buttonWorkshopReactivate,
                  ),
                  variant: AtlasButtonVariant.ghostDanger,
                  onPressed: onToggleStatus,
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: actions,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: 20),
                actions,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const Divider(height: 1, color: PtTheme.border),
      ],
    );
  }
}

/// The record's focal instrument: a capacity dial plus ruled figures.
class WorkshopInstrumentBand extends StatelessWidget {
  const WorkshopInstrumentBand({
    super.key,
    required this.strings,
    required this.workshop,
  });

  final UiMessageStrings strings;
  final HierarchyWorkshop workshop;

  @override
  Widget build(BuildContext context) {
    final figures = [
      (
        '${workshopStaffTotal(workshop)}',
        strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
      ),
      (
        '${workshop.technicians.length}',
        strings.tKey(PlatformAdminKeys.sectionWorkshopTechnicians),
      ),
      (
        '${workshop.pendingInvitations.length}',
        strings.tKey(PlatformAdminKeys.sectionWorkshopPendingInvitations),
      ),
      (
        '${workshop.bayCount}',
        strings.tKey(PlatformAdminKeys.fieldWorkshopBays),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final dial = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AtlasGauge(value: workshop.assignedCapacityPercent),
            const SizedBox(height: 6),
            Text(
              strings.tKey(PlatformAdminKeys.fieldWorkshopAssignedCapacity),
              style: Atlas.text(
                10.5,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
          ],
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  dial,
                  const SizedBox(width: 24),
                  Expanded(
                    child: Wrap(
                      runSpacing: 16,
                      children: [
                        for (var i = 0; i < 2; i++)
                          SizedBox(
                            width: (constraints.maxWidth - 120) / 2,
                            child: _Figure(
                              value: figures[i].$1,
                              label: figures[i].$2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 2; i < figures.length; i++)
                    Expanded(
                      child: _Figure(
                        value: figures[i].$1,
                        label: figures[i].$2,
                      ),
                    ),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            dial,
            const SizedBox(width: 30),
            for (var i = 0; i < figures.length; i++) ...[
              if (i > 0) Container(width: 1, height: 52, color: PtTheme.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _Figure(value: figures[i].$1, label: figures[i].$2),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Atlas.text(
            36,
            weight: FontWeight.w800,
            tracking: -1,
            tabular: true,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Atlas.text(11, weight: FontWeight.w600, color: PtTheme.muted),
        ),
      ],
    );
  }
}

/// Two-column overview: ruled facts on the left, people on the right.
class WorkshopOverview extends StatelessWidget {
  const WorkshopOverview({
    super.key,
    required this.strings,
    required this.workshop,
  });

  final UiMessageStrings strings;
  final HierarchyWorkshop workshop;

  @override
  Widget build(BuildContext context) {
    final contact = (workshop.contactEmail ?? '').trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final facts = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasKeyRow(
              label: strings.tKey(PlatformAdminKeys.fieldWorkshopBranch),
              value: (workshop.branchName ?? '').trim().isEmpty
                  ? '—'
                  : workshop.branchName!,
            ),
            AtlasKeyRow(
              label: strings.tKey(PlatformAdminKeys.fieldWorkshopContactEmail),
              value: contact.isEmpty ? '—' : contact,
            ),
            AtlasKeyRow(
              label: strings.tKey(PlatformAdminKeys.fieldWorkshopBays),
              value: '${workshop.bayCount}',
            ),
            AtlasKeyRow(
              label: strings.tKey(PlatformAdminKeys.fieldWorkshopCapacity),
              value: '${workshop.assignedCapacityPercent}%',
            ),
            AtlasKeyRow(
              label: strings.tKey(CommonKeys.tableStatus),
              value: workshopStatusLabel(strings, workshop.status),
              last: true,
            ),
          ],
        );
        final people = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupHeader(
              label: strings.tKey(PlatformAdminKeys.sectionWorkshopAdmins),
              count: workshop.admins.length,
            ),
            const SizedBox(height: 10),
            if (workshop.admins.isEmpty)
              Text(
                strings.tKey(PlatformAdminKeys.emptyWorkshopAdminsBody),
                style: Atlas.text(12, color: PtTheme.muted),
              )
            else
              for (final admin in workshop.admins) _PersonRow(account: admin),
            const SizedBox(height: 22),
            _GroupHeader(
              label: strings.tKey(PlatformAdminKeys.sectionWorkshopTechnicians),
              count: workshop.technicians.length,
            ),
            const SizedBox(height: 10),
            if (workshop.technicians.isEmpty)
              Text(
                strings.tKey(PlatformAdminKeys.emptyWorkshopTechniciansTitle),
                style: Atlas.text(12, color: PtTheme.muted),
              )
            else
              for (final technician in workshop.technicians)
                _PersonRow(account: technician),
            const SizedBox(height: 22),
            _GroupHeader(
              label: strings.tKey(
                PlatformAdminKeys.sectionWorkshopPendingInvitations,
              ),
              count: workshop.pendingInvitations.length,
            ),
            const SizedBox(height: 10),
            if (workshop.pendingInvitations.isEmpty)
              Text(
                strings.tKey(
                  PlatformAdminKeys.emptyWorkshopPendingInvitationsTitle,
                ),
                style: Atlas.text(12, color: PtTheme.muted),
              )
            else
              for (final invite in workshop.pendingInvitations)
                _PersonRow(account: invite, pending: true),
          ],
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              facts,
              const SizedBox(height: 24),
              const Divider(height: 1, color: PtTheme.border),
              const SizedBox(height: 20),
              people,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: facts),
            const SizedBox(width: 32),
            Container(width: 1, height: 260, color: PtTheme.border),
            const SizedBox(width: 32),
            Expanded(flex: 2, child: people),
          ],
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Atlas.eyebrow)),
        Text(
          '$count',
          style: Atlas.text(
            11,
            weight: FontWeight.w700,
            tabular: true,
            color: PtTheme.muted,
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.account, this.pending = false});

  final PlatformAccount account;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pending ? Atlas.amberTint : Atlas.neutralTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              Atlas.initials(account.displayName),
              style: Atlas.text(
                11,
                weight: FontWeight.w700,
                color: pending ? PtTheme.amber : PtTheme.muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.displayName,
                  style: Atlas.text(12.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Atlas.text(10.5, color: PtTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
