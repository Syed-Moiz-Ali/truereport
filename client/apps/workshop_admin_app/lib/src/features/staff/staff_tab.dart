import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/staff/create_technician_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Workshop Admin staff screen (Overview / Roster).
///
/// Roster core only, from the existing server-scoped staff endpoint
/// (`staffProvider`): one page header (title + subtitle + Create), one
/// toolbar (search + counted role chips) and one roster surface built from
/// the payload's own fields — `displayName`, `role`, `status`, `emailMasked`.
///
/// Layout: a single [WorkshopCard] table from 900 px (header row + divided
/// rows, 64 px minimum) and the same data as stacked rows inside one card
/// below that. No active-job counts, bays, shifts or certifications are
/// rendered: those fields do not exist on [StaffMember] (reported data gap).
///
/// The per-member kebab keeps the existing temporary-password reset flow
/// ([showResetPasswordDialog] → `resetTechnicianPassword`) and the Create
/// action keeps opening the screen-6 [CreateTechnicianSheet].
class StaffTab extends ConsumerStatefulWidget {
  const StaffTab({super.key});

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab> {
  final _search = TextEditingController();

  /// '' = all; otherwise a C0 role code (TECHNICIAN / WORKSHOP_ADMIN).
  String _role = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await CreateTechnicianSheet.showCreateTechnicianSheet(
      context,
    );
    if (created != null) {
      ref.invalidate(staffProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final staff = ref.watch(staffProvider);
    final members = staff.value;

    return WorkshopPageScroll(
      children: [
        WorkshopPageHeader(
          title: l10n.workshopStaffTitle,
          subtitle: l10n.staffSubtitle,
          primaryAction: WorkshopButton(
            label: l10n.create,
            icon: Icons.person_add_alt_1_outlined,
            onPressed: _create,
          ),
        ),
        SizedBox(height: spacing.lg),
        WorkshopToolbar(
          search: WorkshopSearchField(
            key: const Key('staff-search'),
            controller: _search,
            hint: l10n.search,
            semanticLabel: l10n.search,
            onChanged: (_) => setState(() {}),
          ),
          filters: [
            _filter(l10n, '', l10n.filterAll, members),
            _filter(l10n, 'TECHNICIAN', l10n.staffFilterTechnicians, members),
            _filter(l10n, 'WORKSHOP_ADMIN', l10n.staffFilterAdmins, members),
          ],
        ),
        SizedBox(height: spacing.xl),
        staff.when(
          loading: () => const WorkshopSkeleton(lines: 6, card: true),
          error: (error, _) => WorkshopErrorState(
            title: l10n.error,
            body: l10n.genericError,
            retryLabel: l10n.retryAction,
            onRetry: () => ref.invalidate(staffProvider),
          ),
          data: (all) => _roster(context, l10n, all),
        ),
      ],
    );
  }

  Widget _roster(
    BuildContext context,
    AppLocalizations l10n,
    List<StaffMember> all,
  ) {
    final query = _search.text.trim().toLowerCase();
    final filtered = all
        .where((member) {
          if (_role.isNotEmpty && member.role != _role) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return member.displayName.toLowerCase().contains(query) ||
              member.emailMasked.toLowerCase().contains(query);
        })
        .toList(growable: false);

    if (all.isEmpty) {
      return WorkshopEmptyState(
        title: l10n.noTechnicians,
        body: l10n.staffSubtitle,
        icon: Icons.groups_outlined,
        action: WorkshopButton(
          label: l10n.create,
          icon: Icons.person_add_alt_1_outlined,
          onPressed: _create,
        ),
      );
    }
    if (filtered.isEmpty) {
      return WorkshopEmptyState(
        title: l10n.noResults,
        body: l10n.noTechnicians,
        icon: Icons.groups_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _table(context, l10n, filtered)
          : _stacked(context, l10n, filtered),
    );
  }

  /// Desktop roster: one card, a header row and hairline-divided rows.
  Widget _table(
    BuildContext context,
    AppLocalizations l10n,
    List<StaffMember> members,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    final rows = <Widget>[];
    for (var index = 0; index < members.length; index++) {
      if (index > 0) {
        rows.add(const WorkshopDivider());
      }
      rows.add(_tableRow(context, l10n, members[index]));
    }
    return WorkshopCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    // Align the header with the name text after the avatar.
                    padding: EdgeInsetsDirectional.only(start: ws.touchTarget),
                    child: _headerCell(context, l10n.displayName),
                  ),
                ),
                Expanded(flex: 2, child: _headerCell(context, l10n.role)),
                Expanded(flex: 2, child: _headerCell(context, l10n.status)),
                Expanded(flex: 3, child: _headerCell(context, l10n.emailLabel)),
                SizedBox(width: ws.touchTarget),
              ],
            ),
          ),
          const WorkshopDivider(),
          ...rows,
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label) {
    final ws = context.ws;
    return Text(
      label,
      maxLines: 1,
      style: ws.eyebrow.copyWith(color: ws.muted),
    );
  }

  Widget _tableRow(
    BuildContext context,
    AppLocalizations l10n,
    StaffMember member,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      key: Key('staff-${member.userId}'),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: spacing.massive),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  WorkshopAvatar(
                    initials: _initials(member.displayName),
                    semanticLabel: member.displayName,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      member.displayName,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                memberRoleLabel(l10n, member.role),
                style: ws.body.copyWith(color: ws.muted),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _statusBadge(l10n, member.status),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                member.emailMasked,
                textDirection: TextDirection.ltr,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ),
            SizedBox(
              width: ws.touchTarget,
              child: _StaffActions(
                userId: member.userId,
                displayName: member.displayName,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Phone roster: the same fields stacked inside one card.
  Widget _stacked(
    BuildContext context,
    AppLocalizations l10n,
    List<StaffMember> members,
  ) {
    final rows = <Widget>[];
    for (var index = 0; index < members.length; index++) {
      if (index > 0) {
        rows.add(const WorkshopDivider());
      }
      rows.add(_stackedRow(context, l10n, members[index]));
    }
    return WorkshopCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _stackedRow(
    BuildContext context,
    AppLocalizations l10n,
    StaffMember member,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      key: Key('staff-${member.userId}'),
      padding: EdgeInsetsDirectional.all(spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkshopAvatar(
            initials: _initials(member.displayName),
            semanticLabel: member.displayName,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.displayName,
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
                SizedBox(height: spacing.xxs),
                Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      memberRoleLabel(l10n, member.role),
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                    _statusBadge(l10n, member.status),
                  ],
                ),
                SizedBox(height: spacing.xs),
                Text(
                  member.emailMasked,
                  textDirection: TextDirection.ltr,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ],
            ),
          ),
          _StaffActions(userId: member.userId, displayName: member.displayName),
        ],
      ),
    );
  }

  Widget _statusBadge(AppLocalizations l10n, String status) {
    return WorkshopStatusBadge(
      label: memberStatusLabel(l10n, status),
      tone: status == 'ACTIVE'
          ? WorkshopStatusTone.success
          : WorkshopStatusTone.neutral,
    );
  }

  Widget _filter(
    AppLocalizations l10n,
    String value,
    String label,
    List<StaffMember>? all,
  ) {
    final count = all == null
        ? null
        : value.isEmpty
        ? all.length
        : all.where((member) => member.role == value).length;
    return WorkshopFilterChip(
      label: label,
      count: count,
      selected: _role == value,
      onTap: () => setState(() => _role = value),
    );
  }
}

String _initials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}

class _StaffActions extends ConsumerWidget {
  const _StaffActions({required this.userId, required this.displayName});

  final String userId;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: '$displayName · ${l10n.actions}',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value != 'resetPassword') {
          return;
        }
        final password = await showResetPasswordDialog(context);
        if (password == null || !context.mounted) {
          return;
        }
        try {
          await ref
              .read(adminApiProvider)
              .resetTechnicianPassword(userId, password);
          ref.invalidate(staffProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
          }
        } on Object {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'resetPassword',
          child: Text(l10n.temporaryPassword),
        ),
      ],
    );
  }
}

String? staffPasswordError(AppLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.requiredField;
  }
  if (value.length < 12) {
    return l10n.requiredField;
  }
  return null;
}

Future<String?> showResetPasswordDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.temporaryPassword),
      content: Form(
        key: formKey,
        child: AppTextField(
          controller: controller,
          label: l10n.temporaryPassword,
          hint: l10n.temporaryPassword,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          validator: (value) => staffPasswordError(l10n, value),
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: l10n.confirm,
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(controller.text);
            }
          },
        ),
      ],
    ),
  ).then((value) {
    return value;
  });
}
