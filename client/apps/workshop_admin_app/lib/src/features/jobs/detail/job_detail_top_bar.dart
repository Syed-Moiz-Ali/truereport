import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Page top bar: back, workspace context, reference, refresh and the
/// secondary lifecycle overflow. Destructive actions stay inside the menu.
class JobDetailTopBar extends StatelessWidget {
  const JobDetailTopBar({
    required this.job,
    required this.canAssign,
    required this.canCancel,
    required this.busy,
    required this.onRefresh,
    required this.onAssign,
    required this.onCancel,
    super.key,
  });

  final CleanJob? job;
  final bool canAssign;
  final bool canCancel;
  final bool busy;
  final VoidCallback onRefresh;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return JobPageTopBar(
      title: l10n.jobsDetailTitle,
      breadcrumbs: [l10n.jobsTab, if (job != null) job!.reference],
      actions: [
        WorkshopIconButton(
          key: const Key('job-detail-refresh'),
          icon: Icons.refresh,
          semanticLabel: l10n.refresh,
          onPressed: onRefresh,
        ),
        _TopBarMoreMenu(
          canAssign: canAssign && !busy,
          canCancel: canCancel && !busy,
          onAssign: onAssign,
          onCancel: onCancel,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

class _TopBarMoreMenu extends StatelessWidget {
  const _TopBarMoreMenu({
    required this.canAssign,
    required this.canCancel,
    required this.onAssign,
    required this.onCancel,
    required this.onRefresh,
  });

  final bool canAssign;
  final bool canCancel;
  final VoidCallback onAssign;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return PopupMenuButton<String>(
      key: const Key('job-detail-top-more'),
      tooltip: l10n.jobDetailMoreActions,
      position: PopupMenuPosition.under,
      color: ws.surface,
      onSelected: (value) {
        switch (value) {
          case 'assign':
            onAssign();
          case 'cancel':
            onCancel();
          default:
            onRefresh();
        }
      },
      itemBuilder: (context) => [
        if (canAssign)
          _menuItem(
            context,
            value: 'assign',
            icon: Icons.person_add_alt_1_outlined,
            label: l10n.reassign,
          ),
        if (canCancel)
          _menuItem(
            context,
            value: 'cancel',
            icon: Icons.cancel_outlined,
            label: l10n.cancelJob,
            danger: true,
          ),
        _menuItem(
          context,
          value: 'refresh',
          icon: Icons.refresh,
          label: l10n.refresh,
        ),
      ],
      child: Semantics(
        button: true,
        label: l10n.jobDetailMoreActions,
        child: Container(
          width: ws.touchTarget,
          height: ws.touchTarget,
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.controlRadius),
            border: Border.all(color: ws.border),
          ),
          child: Icon(Icons.more_horiz, size: 20, color: ws.ink),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    bool danger = false,
  }) {
    final ws = context.ws;
    final color = danger ? ws.danger : ws.ink;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: context.spacing.sm),
          Text(label, style: ws.body.copyWith(color: color)),
        ],
      ),
    );
  }
}
