import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/staff/staff_create_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_member_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_role_tabs.dart';
import 'package:workshop_admin_app/src/features/staff/staff_roster_row.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Workshop Admin staff section — the roster.
///
/// The roster is an index, not a workspace: it lists who is on the team and
/// what state their account is in, and every row opens the member's own page
/// where the status and the temporary password are changed. Create opens a
/// full page. Reads `staffProvider` only; no job counts, bays or shifts are
/// shown because [StaffMember] does not carry them.
class StaffTab extends ConsumerStatefulWidget {
  const StaffTab({super.key});

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab> {
  final _search = TextEditingController();

  /// '' = every role, otherwise a C0 role code.
  String _role = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final created = await Navigator.of(context).push<PlatformAccount>(
      MaterialPageRoute<PlatformAccount>(
        builder: (_) => const StaffCreatePage(),
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    ref.invalidate(staffProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.accountCreated)));
  }

  void _open(StaffMember member) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StaffMemberPage(
          memberId: member.userId,
          initialName: member.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(staffProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final ws = context.ws;
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: ws.pagePadding(constraints.maxWidth),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: staff.when(
                loading: () => const StaffRosterSkeleton(),
                error: (error, _) => _errorSurface,
                data: (members) => _roster(members, wide),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget get _errorSurface {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return StaffLedgerSurface(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(28, 40, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ws.dangerSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.priority_high_rounded,
                size: 20,
                color: ws.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.error, style: ws.sectionTitle.copyWith(color: ws.ink)),
            const SizedBox(height: 6),
            Text(
              l10n.commonLoadFailed,
              style: ws.body.copyWith(color: ws.muted),
            ),
            const SizedBox(height: 18),
            WorkshopButton(
              label: l10n.retryAction,
              icon: Icons.refresh,
              variant: WorkshopButtonVariant.secondary,
              onPressed: () => ref.invalidate(staffProvider),
            ),
          ],
        ),
      ),
    );
  }

  List<StaffMember> _visible(List<StaffMember> members) {
    final query = _search.text.trim().toLowerCase();
    return members
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
  }

  Map<String, int> _counts(List<StaffMember> members) => {
    '': members.length,
    'TECHNICIAN': members.where((m) => m.role == 'TECHNICIAN').length,
    'WORKSHOP_ADMIN': members.where((m) => m.role == 'WORKSHOP_ADMIN').length,
  };

  Widget _roster(List<StaffMember> members, bool wide) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final visible = _visible(members);
    return StaffLedgerSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inlineTools = constraints.maxWidth >= 640;
          final roomy = constraints.maxWidth >= 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.workshopStaffTitle,
                                  style: ws.ledgerTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('${members.length}', style: ws.countFigure),
                            ],
                          ),
                        ),
                        if (inlineTools && members.isNotEmpty) ...[
                          SizedBox(width: 240, child: _searchField()),
                          const SizedBox(width: 12),
                          WorkshopButton(
                            label: l10n.create,
                            icon: Icons.person_add_alt_1_outlined,
                            onPressed: _create,
                          ),
                        ],
                      ],
                    ),
                    if (!inlineTools && members.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _searchField()),
                          const SizedBox(width: 12),
                          WorkshopButton(
                            label: l10n.create,
                            icon: Icons.person_add_alt_1_outlined,
                            onPressed: _create,
                          ),
                        ],
                      ),
                    ],
                    if (members.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      StaffRoleTabs(
                        counts: _counts(members),
                        selected: _role,
                        onSelected: (value) => setState(() => _role = value),
                      ),
                    ],
                  ],
                ),
              ),
              staffHairline(context),
              if (members.isEmpty)
                _EmptyRoster(onCreate: _create)
              else if (visible.isEmpty)
                _NoResults(
                  onClear: () => setState(() {
                    _search.clear();
                    _role = '';
                  }),
                )
              else
                for (final member in visible)
                  StaffRosterRow(
                    member: member,
                    wide: wide,
                    roomy: roomy,
                    onTap: () => _open(member),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    final l10n = AppLocalizations.of(context);
    return WorkshopSearchField(
      key: const Key('staff-search'),
      controller: _search,
      hint: l10n.search,
      semanticLabel: l10n.search,
      onChanged: (_) => setState(() {}),
    );
  }
}

/// First-run / all-accounts-removed state, drawn in the ledger itself.
class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 44, 28, 44),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(40, ws.accentSoft),
              Transform.translate(
                offset: const Offset(-8, 0),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ws.surface,
                    borderRadius: BorderRadius.circular(52 * 0.36),
                    border: Border.all(color: ws.border),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 22,
                    color: ws.accent,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(-16, 0),
                child: _chip(32, ws.accentSoft),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.noTechnicians,
            textAlign: TextAlign.center,
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              l10n.staffSubtitle,
              textAlign: TextAlign.center,
              style: ws.body.copyWith(color: ws.muted),
            ),
          ),
          const SizedBox(height: 20),
          WorkshopButton(
            label: l10n.create,
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }

  Widget _chip(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 32),
      child: Column(
        children: [
          Text(
            l10n.noResults,
            textAlign: TextAlign.center,
            style: ws.body.copyWith(color: ws.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noTechnicians,
            textAlign: TextAlign.center,
            style: ws.meta.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 14),
          WorkshopButton(
            label: l10n.jobsClearFilters,
            variant: WorkshopButtonVariant.secondary,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
