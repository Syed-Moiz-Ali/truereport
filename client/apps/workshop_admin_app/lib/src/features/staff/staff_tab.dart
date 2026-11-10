import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/staff/create_technician_sheet.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

/// Workshop Admin staff screen (Overview / Roster).
///
/// Roster core only, from the existing server-scoped staff endpoint
/// (`staffProvider`): a [WorkshopHeader] title +
/// client-side search + role filter chips with client-side counts + one
/// [WorkshopStaffCard] per member (initials tile + status dot from `status`,
/// displayName, neutral role label, masked email, password-reset menu).
/// The "+ Add" trigger opens the screen-6 create-Technician sheet
/// ([CreateTechnicianSheet.showCreateTechnicianSheet]).
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffProvider);
    final counts = staff.maybeWhen(
      data: (members) => members,
      orElse: () => null,
    );
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;
    final displayName = session?.user.displayName.trim() ?? '';
    final workshopName = session != null && session.memberships.isNotEmpty
        ? session.memberships.first.workshopName
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: context.spacing.lg,
            end: context.spacing.lg,
            top: context.spacing.lg,
          ),
          child: WorkshopHeader(
            semanticLabel: l10n.workshopStaffTitle,
            title: l10n.workshopStaffTitle,
            search: AppTextField(
              key: const Key('staff-search'),
              controller: _search,
              label: l10n.search,
              hint: l10n.search,
              prefixIcon: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              AppButton(
                label: l10n.create,
                onPressed: () async {
                  final created =
                      await CreateTechnicianSheet.showCreateTechnicianSheet(
                        context,
                      );
                  if (created != null) {
                    ref.invalidate(staffProvider);
                  }
                },
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.tonal,
              ),
            ],
            user: displayName.isEmpty
                ? null
                : WorkshopUserChip(
                    initials: _initials(displayName),
                    displayName: displayName,
                    workshopName: workshopName,
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.spacing.lg,
            vertical: context.spacing.sm,
          ),
          child: Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              _filter(context, l10n, '', l10n.filterAll, counts),
              _filter(
                context,
                l10n,
                'TECHNICIAN',
                l10n.staffFilterTechnicians,
                counts,
              ),
              _filter(
                context,
                l10n,
                'WORKSHOP_ADMIN',
                l10n.staffFilterAdmins,
                counts,
              ),
            ],
          ),
        ),
        Expanded(
          child: staff.when(
            loading: () => Padding(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              child: const LoadingSkeleton(lines: 4),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () => ref.invalidate(staffProvider),
                  retryLabel: l10n.retryAction,
                ),
              ),
            ),
            data: (members) {
              final query = _search.text.trim().toLowerCase();
              final filtered = members.where((member) {
                if (_role.isNotEmpty && member.role != _role) {
                  return false;
                }
                if (query.isEmpty) {
                  return true;
                }
                return member.displayName.toLowerCase().contains(query) ||
                    member.emailMasked.toLowerCase().contains(query);
              }).toList(growable: false);
              if (filtered.isEmpty) {
                return Padding(
                  padding: EdgeInsetsDirectional.all(context.spacing.lg),
                  child: EmptyState(
                    title: l10n.noResults,
                    body: l10n.noTechnicians,
                    icon: Icons.groups_outlined,
                  ),
                );
              }
              return SingleChildScrollView(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 640
                        ? 1
                        : constraints.maxWidth < AppBreakpoints.tablet
                        ? 2
                        : 3;
                    final gap = context.spacing.sm;
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final member in filtered)
                          SizedBox(
                            width: columns == 1
                                ? constraints.maxWidth
                                : cardWidth,
                            child: WorkshopStaffCard(
                              key: Key('staff-${member.userId}'),
                              displayName: member.displayName,
                              statusActive: member.status == 'ACTIVE',
                              roleLabel: memberRoleLabel(l10n, member.role),
                              detail: Text(member.emailMasked),
                              trailing: _StaffActions(
                                userId: member.userId,
                                displayName: member.displayName,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filter(
    BuildContext context,
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
    return AppSelectableText(
      label: count == null ? label : '$label (${_formatCount(context, count)})',
      selected: _role == value,
      onTap: () => setState(() => _role = value),
    );
  }
}

String _formatCount(BuildContext context, int value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format(value);
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
