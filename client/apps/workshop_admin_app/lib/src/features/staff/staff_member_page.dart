import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/staff/staff_credentials_section.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/features/staff/staff_lifecycle_section.dart';
import 'package:workshop_admin_app/src/features/staff/staff_member_states.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// One staff member as a record: identity, account state, actions, then the
/// facts and the password/lifecycle work in a 5/4 split.
///
/// Everything rendered comes from `StaffMember` (name, role, status, masked
/// email) � no counters, shifts or sign-in history are invented. Actions write
/// through the calls this app already holds: `disableUser`, `reactivateUser`
/// and `resetTechnicianPassword`.
class StaffMemberPage extends ConsumerStatefulWidget {
  const StaffMemberPage({required this.memberId, super.key});

  final String memberId;

  @override
  ConsumerState<StaffMemberPage> createState() => _StaffMemberPageState();
}

class _StaffMemberPageState extends ConsumerState<StaffMemberPage> {
  final _credentialsKey = GlobalKey();
  final _lifecycleKey = GlobalKey();
  bool _lifecycleOpen = false;
  bool _highlightReset = false;
  Timer? _resetPulse;

  @override
  void dispose() {
    _resetPulse?.cancel();
    super.dispose();
  }

  Future<void> _setStatus(
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

  Future<void> _resetPassword(StaffMember member, String password) async {
    await ref
        .read(adminApiProvider)
        .resetTechnicianPassword(member.userId, password);
    ref.invalidate(staffProvider);
  }

  /// The primary action sends the admin to the password card. On a phone that
  /// is a scroll; on a wide screen it is a short border pulse so the card is
  /// unmistakably the place to type.
  void _focusReset() {
    final target = _credentialsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
    _resetPulse?.cancel();
    setState(() => _highlightReset = true);
    _resetPulse = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _highlightReset = false);
      }
    });
  }

  void _openLifecycle() {
    setState(() => _lifecycleOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _lifecycleKey.currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
      }
    });
  }

  StaffMember? _member(List<StaffMember> members) {
    for (final member in members) {
      if (member.userId == widget.memberId) {
        return member;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final staff = ref.watch(staffProvider);
    final loaded = staff.value;
    final member = loaded == null ? null : _member(loaded);

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaffPageBar(
              title:
                  member?.displayName ??
                  t(WorkshopAdminKeys.workshopStaffTitle),
              trailing: member == null
                  ? null
                  : StaffStatusPill(status: member.status),
            ),
            Expanded(
              child: staff.when(
                loading: () => const StaffMemberSkeleton(),
                error: (error, _) => StaffMemberMessage(
                  title: t(WorkshopAdminKeys.error),
                  body: t(WorkshopAdminKeys.commonLoadFailed),
                  onRetry: () => ref.invalidate(staffProvider),
                ),
                data: (members) {
                  final value = _member(members);
                  if (value == null) {
                    return StaffMemberMessage(
                      title: t(WorkshopAdminKeys.noTechnicians),
                      body: t(WorkshopAdminKeys.staffSubtitle),
                      onBack: () => Navigator.of(context).maybePop(),
                    );
                  }
                  return _record(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _record(StaffMember member) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      padding: ws.pagePadding(width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _identity(member),
              const SizedBox(height: 18),
              _statusStrip(member),
              const SizedBox(height: 14),
              _actions(member),
              const SizedBox(height: 18),
              JobSplitColumns(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkshopSectionHeader(title: t(WorkshopAdminKeys.details)),
                    SizedBox(height: spacing.sm),
                    WorkshopCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StaffFact(
                            label: t(WorkshopAdminKeys.displayName),
                            value: member.displayName,
                          ),
                          StaffFact(
                            label: t(WorkshopAdminKeys.emailLabel),
                            value: member.emailMasked,
                            ltr: true,
                          ),
                          StaffFact(
                            label: t(WorkshopAdminKeys.role),
                            value: staffRoleLabel(ref, member.role),
                          ),
                          StaffFact(
                            label: t(WorkshopAdminKeys.status),
                            value: staffStatusLabel(ref, member.status),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: AlignmentDirectional.topStart,
                      child: _lifecycleOpen
                          ? Padding(
                              padding: EdgeInsetsDirectional.only(
                                bottom: spacing.lg,
                              ),
                              child: StaffLifecycleSection(
                                key: _lifecycleKey,
                                member: member,
                                open: _lifecycleOpen,
                                onClose: () =>
                                    setState(() => _lifecycleOpen = false),
                                onDeactivate: (reason) => _setStatus(
                                  member,
                                  deactivate: true,
                                  reason: reason,
                                ),
                                onReactivate: (reason) => _setStatus(
                                  member,
                                  deactivate: false,
                                  reason: reason,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    StaffCredentialsSection(
                      key: _credentialsKey,
                      highlighted: _highlightReset,
                      onSubmit: (password) => _resetPassword(member, password),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity(StaffMember member) {
    final ws = context.ws;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final monogram = StaffMonogram(
          name: member.displayName,
          size: 84,
          filled: true,
        );
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              member.displayName,
              style: ws.pageTitle.copyWith(
                fontSize: wide ? 32 : 26,
                letterSpacing: -0.7,
                color: ws.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  staffRoleLabel(ref, member.role),
                  style: ws.meta.copyWith(color: ws.muted),
                ),
                Text(
                  '�\u00A0${member.emailMasked}',
                  textDirection: TextDirection.ltr,
                  style: ws.meta.copyWith(color: ws.ink),
                ),
              ],
            ),
          ],
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [monogram, const SizedBox(height: 18), text],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            monogram,
            const SizedBox(width: 22),
            Expanded(child: text),
          ],
        );
      },
    );
  }

  /// The two account states this module has, as a state strip.
  ///
  /// This is deliberately not a progress rail: Active ? Disabled is a
  /// transition, not a later stage. The current state is inked, the other two
  /// stay quiet outlines, and no connector is drawn between them.
  Widget _statusStrip(StaffMember member) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    // No invitation flow exists: staff are created with credentials, so only
    // Active and Disabled are named. Labels resolve through the API.
    // gate-allow: codes
    const states = ['ACTIVE', 'DISABLED'];

    Widget pill(String status) {
      final current = status == member.status;
      final label = staffStatusLabel(ref, status);
      return Semantics(
        selected: current,
        label: label,
        child: ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: current ? ws.ink : ws.canvas,
              borderRadius: BorderRadius.circular(context.radii.pill),
              border: Border.all(color: current ? ws.ink : ws.border),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                style: ws.meta.copyWith(
                  color: current ? ws.canvas : ws.muted,
                  fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final label = Text(
      t(WorkshopAdminKeys.status).toUpperCase(),
      style: ws.eyebrow.copyWith(color: ws.muted),
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.md,
        ),
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: BorderRadius.circular(ws.cardLargeRadius),
          border: Border.all(color: ws.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pills = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final state in states) pill(state)],
            );
            if (constraints.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [label, const SizedBox(height: 10), pills],
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [label, const SizedBox(width: 18), pills],
            );
          },
        ),
      ),
    );
  }

  Widget _actions(StaffMember member) {
    final t = UiStrings.of(context);
    final active = member.status == 'ACTIVE';
    final disabled = member.status == 'DISABLED';
    final pills = <Widget>[
      TemplatePillButton(
        label: t(WorkshopAdminKeys.staffResetPassword),
        icon: Icons.lock_reset,
        onPressed: _focusReset,
      ),
      if ((active || disabled) && !_lifecycleOpen)
        TemplatePillButton(
          label: disabled
              ? t(WorkshopAdminKeys.reactivate)
              : t(WorkshopAdminKeys.deactivate),
          icon: disabled ? Icons.lock_open_outlined : Icons.lock_outline,
          variant: disabled
              ? TemplatePillVariant.outline
              : TemplatePillVariant.danger,
          onPressed: _openLifecycle,
        ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: pills);
  }
}
