import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/staff/staff_credentials_section.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/features/staff/staff_lifecycle_section.dart';
import 'package:workshop_admin_app/src/models.dart';

/// One staff member as a document: identity, status, credentials, details.
///
/// Everything rendered comes from `StaffMember` (name, role, status, masked
/// email) — no counters, shifts or sign-in history are invented. Actions write
/// through the calls this app already holds: `disableUser`, `reactivateUser`
/// and `resetTechnicianPassword`.
class StaffMemberPage extends ConsumerWidget {
  const StaffMemberPage({required this.memberId, this.initialName, super.key});

  final String memberId;

  /// Name from the roster row, so the bar is correct before the list loads.
  final String? initialName;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    StaffMember member, {
    required bool deactivate,
    required String reason,
  }) async {
    final api = ref.read(adminApiProvider);
    if (deactivate) {
      await api.disableUser(member.userId, reason);
    } else {
      await api.reactivateUser(member.userId, reason);
    }
    ref.invalidate(staffProvider);
  }

  Future<void> _resetPassword(
    BuildContext context,
    WidgetRef ref,
    StaffMember member,
    String password,
  ) async {
    await ref
        .read(adminApiProvider)
        .resetTechnicianPassword(member.userId, password);
    ref.invalidate(staffProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final staff = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaffPageBar(
              title: initialName ?? l10n.workshopStaffTitle,
              trailing: staff.value == null
                  ? null
                  : _member(staff.value!) == null
                  ? null
                  : StaffStatusPill(status: _member(staff.value!)!.status),
            ),
            Expanded(
              child: staff.when(
                loading: () => const _PageSkeleton(),
                error: (error, _) => _PageMessage(
                  title: l10n.error,
                  body: l10n.commonLoadFailed,
                  onRetry: () => ref.invalidate(staffProvider),
                ),
                data: (members) {
                  final member = _member(members);
                  if (member == null) {
                    return _PageMessage(
                      title: l10n.noTechnicians,
                      body: l10n.staffSubtitle,
                      onRetry: null,
                      onBack: () => Navigator.of(context).maybePop(),
                    );
                  }
                  return _Document(
                    member: member,
                    onDeactivate: (reason) => _setStatus(
                      context,
                      ref,
                      member,
                      deactivate: true,
                      reason: reason,
                    ),
                    onReactivate: (reason) => _setStatus(
                      context,
                      ref,
                      member,
                      deactivate: false,
                      reason: reason,
                    ),
                    onResetPassword: (password) =>
                        _resetPassword(context, ref, member, password),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  StaffMember? _member(List<StaffMember> members) {
    for (final member in members) {
      if (member.userId == memberId) {
        return member;
      }
    }
    return null;
  }
}

class _Document extends StatelessWidget {
  const _Document({
    required this.member,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onResetPassword,
  });

  final StaffMember member;
  final Future<void> Function(String reason) onDeactivate;
  final Future<void> Function(String reason) onReactivate;
  final Future<void> Function(String password) onResetPassword;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return SingleChildScrollView(
      padding: ws.pagePadding(MediaQuery.sizeOf(context).width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _Identity(member: member),
              const SizedBox(height: 28),
              staffHairline(context),
              const SizedBox(height: 24),
              StaffLifecycleSection(
                title: l10n.status,
                member: member,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              ),
              const SizedBox(height: 28),
              staffHairline(context),
              const SizedBox(height: 24),
              StaffCredentialsSection(
                title: l10n.staffResetPassword,
                onSubmit: onResetPassword,
              ),
              const SizedBox(height: 28),
              staffHairline(context),
              const SizedBox(height: 24),
              StaffSectionHead(number: '03', title: l10n.details),
              const SizedBox(height: 14),
              StaffFact(label: l10n.displayName, value: member.displayName),
              StaffFact(
                label: l10n.emailLabel,
                value: member.emailMasked,
                ltr: true,
              ),
              StaffFact(
                label: l10n.role,
                value: staffRoleLabel(context, member.role),
              ),
              StaffFact(
                label: l10n.status,
                value: staffStatusLabel(context, member.status),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final monogram = StaffMonogram(
          name: member.displayName,
          size: wide ? 84 : 64,
          filled: true,
        );
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              member.displayName,
              style: ws.dossierDisplay.copyWith(fontSize: wide ? 34 : 28),
            ),
            const SizedBox(height: 12),
            Text(
              staffRoleLabel(context, member.role),
              style: ws.meta.copyWith(color: ws.muted),
            ),
            const SizedBox(height: 8),
            Text(
              member.emailMasked,
              textDirection: TextDirection.ltr,
              style: ws.bodyStrong.copyWith(fontSize: 14, color: ws.ink),
            ),
          ],
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [monogram, const SizedBox(height: 16), text],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            monogram,
            const SizedBox(width: 24),
            Expanded(child: text),
          ],
        );
      },
    );
  }
}

class _PageMessage extends StatelessWidget {
  const _PageMessage({
    required this.title,
    required this.body,
    this.onRetry,
    this.onBack,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: ws.pagePadding(MediaQuery.sizeOf(context).width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ws.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ws.border),
                ),
                child: Icon(Icons.groups_outlined, size: 20, color: ws.muted),
              ),
              const SizedBox(height: 16),
              Text(title, style: ws.sectionTitle.copyWith(color: ws.ink)),
              const SizedBox(height: 6),
              Text(body, style: ws.body.copyWith(color: ws.muted)),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (onRetry != null)
                    WorkshopButton(
                      label: l10n.retryAction,
                      icon: Icons.refresh,
                      variant: WorkshopButtonVariant.secondary,
                      onPressed: onRetry,
                    ),
                  if (onRetry != null && onBack != null)
                    const SizedBox(width: 12),
                  if (onBack != null)
                    WorkshopButton(
                      label: l10n.commonBack,
                      variant: WorkshopButtonVariant.ghost,
                      onPressed: onBack,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton in the shape of the document: identity block, two sections, facts.
class _PageSkeleton extends StatefulWidget {
  const _PageSkeleton();

  @override
  State<_PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<_PageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulse.duration = const Duration(milliseconds: 1100);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.55;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.42,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: SingleChildScrollView(
        padding: ws.pagePadding(MediaQuery.sizeOf(context).width),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: ws.border,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(context, 320, 26),
                          const SizedBox(height: 12),
                          _bar(context, 120, 10),
                          const SizedBox(height: 10),
                          _bar(context, 200, 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                for (var i = 0; i < 2; i++) ...[
                  _bar(context, 90, 10),
                  const SizedBox(height: 18),
                  _bar(context, 160, 34),
                  const SizedBox(height: 26),
                  Container(height: 1, color: ws.border),
                  const SizedBox(height: 26),
                ],
                _bar(context, 90, 10),
                const SizedBox(height: 16),
                _bar(context, 420, 10),
                const SizedBox(height: 10),
                _bar(context, 360, 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.ws.border,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}
