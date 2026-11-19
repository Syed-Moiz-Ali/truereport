import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/staff/staff_create_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_member_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_role_filters.dart';
import 'package:workshop_admin_app/src/features/staff/staff_roster_row.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// The staff module front door: page header, pill filters, one table surface.
///
/// Same data and navigation as before — `staffProvider` for the page, the
/// member page for a tap, [StaffCreatePage] for the primary action — but the
/// shape is the jobs queue: a header row, hairline rows, pill status and one
/// bordered surface instead of a card-with-a-list-inside.
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
        builder: (_) => StaffMemberPage(memberId: member.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final staff = ref.watch(staffProvider);
    final members = staff.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.sizeOf(context).width;
        final wide = width >= 1000;
        return SingleChildScrollView(
          padding: ws.pagePadding(constraints.maxWidth),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.workshopStaffTitle,
                              style: ws.pageTitle.copyWith(
                                fontSize: width < 520 ? 26 : 30,
                                letterSpacing: -0.6,
                                color: ws.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.staffSubtitle,
                              style: ws.meta.copyWith(color: ws.muted),
                            ),
                          ],
                        ),
                      ),
                      TemplatePillButton(
                        label: l10n.create,
                        icon: Icons.person_add_alt_1_outlined,
                        onPressed: _create,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: WorkshopSearchField(
                        key: const Key('staff-search'),
                        controller: _search,
                        hint: l10n.search,
                        semanticLabel: l10n.search,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StaffRoleFilters(
                    counts: members == null ? null : _counts(members),
                    selected: _role,
                    onSelected: (value) => setState(() => _role = value),
                  ),
                  const SizedBox(height: 18),
                  staff.when(
                    loading: () => const StaffRosterSkeleton(),
                    error: (error, _) => _errorSurface,
                    data: (loaded) => _roster(loaded, wide),
                  ),
                  const SizedBox(height: 28),
                ],
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
    final spacing = context.spacing;
    return StaffSurface(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing.xl,
        spacing.xxl,
        spacing.xl,
        spacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 20, color: ws.danger),
          const SizedBox(height: 10),
          Text(l10n.error, style: ws.sectionTitle.copyWith(color: ws.ink)),
          const SizedBox(height: 6),
          Text(l10n.commonLoadFailed, style: ws.body.copyWith(color: ws.muted)),
          const SizedBox(height: 14),
          TemplatePillButton(
            label: l10n.retryAction,
            icon: Icons.refresh,
            variant: TemplatePillVariant.outline,
            onPressed: () => ref.invalidate(staffProvider),
          ),
        ],
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
    final visible = _visible(members);
    if (members.isEmpty) {
      return _EmptyRoster(onCreate: _create);
    }
    if (visible.isEmpty) {
      return _NoResults(
        onClear: () => setState(() {
          _search.clear();
          _role = '';
        }),
      );
    }
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return StaffSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wide) ...[
            Container(
              color: ws.canvas,
              padding: const EdgeInsetsDirectional.fromSTEB(18, 9, 14, 9),
              child: Row(
                children: [
                  Expanded(child: _head(context, l10n.staffTab)),
                  SizedBox(width: 110, child: _head(context, l10n.role)),
                  SizedBox(width: 150, child: _head(context, l10n.status)),
                  SizedBox(
                    width: 220,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 10),
                      child: _head(context, l10n.emailLabel),
                    ),
                  ),
                  const SizedBox(width: 25),
                ],
              ),
            ),
            Container(height: 1, color: ws.border),
          ],
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) Container(height: 1, color: ws.border),
            StaffRosterRow(
              member: visible[i],
              wide: wide,
              onTap: () => _open(visible[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _head(BuildContext context, String label) => Text(
    label.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.ws.eyebrow.copyWith(color: context.ws.muted),
  );
}

/// First-run / all-accounts-removed state, drawn in the table surface.
class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    return StaffSurface(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing.xl,
        spacing.xxxl,
        spacing.xl,
        spacing.xxxl,
      ),
      child: Column(
        children: [
          const StaffGlyph(size: 52),
          const SizedBox(height: 18),
          Text(
            l10n.noTechnicians,
            textAlign: TextAlign.center,
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 18),
          TemplatePillButton(
            label: l10n.createTechnicianTitle,
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onCreate,
          ),
        ],
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
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    return StaffSurface(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing.xl,
        spacing.xxxl,
        spacing.xl,
        spacing.xxxl,
      ),
      child: Column(
        children: [
          const StaffGlyph(size: 52),
          const SizedBox(height: 18),
          Text(
            l10n.noResults,
            textAlign: TextAlign.center,
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 18),
          TemplatePillButton(
            label: l10n.jobsClearFilters,
            variant: TemplatePillVariant.outline,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
