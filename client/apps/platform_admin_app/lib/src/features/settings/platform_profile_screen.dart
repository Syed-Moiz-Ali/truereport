import 'dart:async';

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../components/platform_shell_sheets.dart';
import '../../platform_features.dart';
import '../../platform_providers.dart';
import '../workshops/workshop_activity.dart';
import 'profile_password_dialog.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Platform Profile: who you are, what you can change, and where the admin
/// destinations live — in that order.
///
/// Deliberately not a dashboard: no giant counters here. The health signal is a
/// row in Administration, account actions sit in the Account list (password,
/// sign out), and the only preferences are language and direction.
class PlatformProfileScreen extends ConsumerStatefulWidget {
  const PlatformProfileScreen({super.key});

  @override
  ConsumerState<PlatformProfileScreen> createState() =>
      _PlatformProfileScreenState();
}

class _PlatformProfileScreenState extends ConsumerState<PlatformProfileScreen> {
  bool _seeding = false;
  String? _toastMessage;
  bool _toastError = false;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _toastMessage = null);
    });
  }

  Future<void> _changePassword() async {
    final changed = await showProfilePasswordDialog(context);
    if (changed == true && mounted) {
      _showToast(
        ref
            .read(uiStringsProvider)
            .tKey(PlatformAdminKeys.pageProfilePasswordSuccess),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/signin');
  }

  Future<void> _seedChecklist() async {
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _SeedConfirmDialog(
        strings: strings,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _seeding = true);
    try {
      final result = await ref.read(platformConfigActionsProvider).seed();
      if (!mounted) return;
      _showToast(
        strings.tArgsKey(PlatformAdminKeys.toastSeedSuccess, <String, Object?>{
          'created': result.created,
          'skipped': result.skipped,
        }),
      );
    } on Object {
      if (!mounted) return;
      _showToast(
        strings.tKey(PlatformAdminKeys.toastSeedFailed),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);

    return PlatformShell(
      currentRoute: '/profile',
      showSearch: false,
      showStrip: false,
      child: PlatformPage(
        maxWidth: 1040,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IdentityCard(),
                const SizedBox(height: 26),
                DeckGroupLabel(
                  label: strings.tKey(PlatformAdminKeys.pageProfileAccount),
                ),
                const SizedBox(height: 10),
                _ProfileCard(
                  children: [
                    _AccountRows(
                      strings: strings,
                      onChangePassword: _changePassword,
                      onSignOut: _signOut,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DeckGroupLabel(
                  label: strings.tKey(PlatformAdminKeys.pageProfilePreferences),
                ),
                const SizedBox(height: 10),
                _ProfileCard(children: [_PreferenceRows(strings: strings)]),
                const SizedBox(height: 24),
                DeckGroupLabel(
                  label: strings.tKey(
                    PlatformAdminKeys.pageProfileAdministration,
                  ),
                ),
                const SizedBox(height: 10),
                _ProfileCard(children: [_AdminRows(strings: strings)]),
                const SizedBox(height: 24),
                DeckGroupLabel(
                  label: strings.tKey(PlatformAdminKeys.pageProfileAdvanced),
                ),
                const SizedBox(height: 10),
                _ProfileCard(
                  children: [
                    _SeedRow(
                      strings: strings,
                      trailing: DeckButton(
                        label: strings.tKey(
                          PlatformAdminKeys.buttonSeedLoadDefault,
                        ),
                        icon: Icons.cloud_download_outlined,
                        primary: false,
                        loading: _seeding,
                        onPressed: _seeding ? null : _seedChecklist,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_toastMessage != null)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: DeckToast(
                    message: _toastMessage!,
                    isError: _toastError,
                    dismissLabel: strings.tKey(CommonKeys.buttonClose),
                    onDismiss: () => setState(() => _toastMessage = null),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Identity band: the person, nothing else. Actions live in the Account list.
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final auth = ref.watch(authControllerProvider);
    final palette = DeckPalette.of(context);

    return DeckReveal(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.hero,
          borderRadius: BorderRadius.circular(DeckRadius.hero),
        ),
        child: auth.when(
          loading: () => const Row(
            children: [
              DeckSkeleton(width: 64, height: 64, radius: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeckSkeleton(width: 200, height: 26, radius: 8),
                    SizedBox(height: 8),
                    DeckSkeleton(width: 160, height: 14, radius: 7),
                  ],
                ),
              ),
            ],
          ),
          error: (_, _) => Text(
            strings.tKey(CommonKeys.stateError),
            style: DeckType.style(15, 20, FontWeight.w600, Colors.white),
          ),
          data: (session) {
            if (session == null) return const SizedBox.shrink();
            final name = session.user.displayName.trim();
            final email = session.user.email.trim();
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final avatar = Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    platformInitials(name),
                    style: DeckType.style(
                      22,
                      26,
                      FontWeight.w800,
                      Colors.white,
                    ),
                  ),
                );
                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.isEmpty
                          ? strings.tKey(PlatformAdminKeys.pageProfileTitle)
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DeckType.style(
                        24,
                        30,
                        FontWeight.w800,
                        Colors.white,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DeckType.style(
                          13,
                          19,
                          FontWeight.w400,
                          palette.heroMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        platformRoleLabel(strings, session).toUpperCase(),
                        style: DeckType.style(
                          10.5,
                          14,
                          FontWeight.w800,
                          Colors.white,
                          tracking: 0.6,
                        ),
                      ),
                    ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [avatar, const SizedBox(height: 16), identity],
                  );
                }
                return Row(
                  children: [
                    avatar,
                    const SizedBox(width: 18),
                    Expanded(child: identity),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The account list: read-only facts plus the two actions that belong to an
/// account (change password, sign out).
class _AccountRows extends ConsumerWidget {
  const _AccountRows({
    required this.strings,
    required this.onChangePassword,
    required this.onSignOut,
  });

  final UiMessageStrings strings;
  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final palette = DeckPalette.of(context);
    final name = auth?.user.displayName.trim() ?? '';
    final email = auth?.user.email.trim() ?? '';
    final role = auth == null ? '' : platformRoleLabel(strings, auth);
    return Column(
      children: [
        _InfoRow(
          label: strings.tKey(PlatformAdminKeys.pageProfileFieldName),
          value: name.isEmpty
              ? strings.tKey(PlatformAdminKeys.pageProfileTitle)
              : name,
        ),
        const _Hairline(),
        _InfoRow(
          label: strings.tKey(PlatformAdminKeys.pageProfileFieldEmail),
          value: email.isEmpty ? '—' : email,
        ),
        const _Hairline(),
        _InfoRow(
          label: strings.tKey(PlatformAdminKeys.pageProfileFieldRole),
          value: role.isEmpty ? '—' : role,
        ),
        const _Hairline(),
        _InfoRow(
          label: strings.tKey(PlatformAdminKeys.pageProfileFieldPassword),
          value: strings.tKey(PlatformAdminKeys.pageProfilePasswordMasked),
          trailing: _InlineAction(
            key: const Key('profile-change-password'),
            label: strings.tKey(PlatformAdminKeys.pageProfileChangePassword),
            onTap: onChangePassword,
          ),
        ),
        const _Hairline(),
        _TapRow(
          key: const Key('profile-sign-out'),
          onTap: onSignOut,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 17, color: palette.danger),
              const SizedBox(width: 8),
              Text(
                strings.tKey(CommonKeys.buttonSignOut),
                style: DeckType.style(13, 18, FontWeight.w700, palette.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceRows extends ConsumerWidget {
  const _PreferenceRows({required this.strings});

  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeckPalette.of(context);
    final manifest = ref.watch(platformUiManifestProvider);
    final active = ref.watch(uiMessageControllerProvider).activeLanguage;
    final languages = manifest?.languages ?? const <UiMessageLanguage>[];
    final current = languages.where((item) => item.code == active).firstOrNull;
    final direction = (current?.isRtl ?? false)
        ? strings.tKey(PlatformAdminKeys.pageProfileDirectionRtl)
        : strings.tKey(PlatformAdminKeys.pageProfileDirectionLtr);

    Widget? languageControl;
    if (languages.length > 1) {
      languageControl = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('profile-language'),
          value: languages.any((item) => item.code == active) ? active : null,
          isDense: true,
          borderRadius: BorderRadius.circular(DeckRadius.tile),
          style: DeckType.style(13, 18, FontWeight.w600, palette.ink),
          icon: Icon(Icons.expand_more_rounded, size: 18, color: palette.muted),
          items: [
            for (final language in languages)
              DropdownMenuItem<String>(
                value: language.code,
                child: Text(
                  language.nativeName.isEmpty
                      ? language.code.toUpperCase()
                      : language.nativeName,
                ),
              ),
          ],
          onChanged: (code) async {
            if (code == null || code == active) return;
            await ref.read(uiMessageSwitcherProvider).switchTo(code);
            try {
              await ref.read(platformConfigApiProvider).setMeLanguage(code);
            } catch (_) {
              // Local switch already applied; the preference can retry later.
            }
          },
        ),
      );
    }

    return Column(
      children: [
        _InfoRow(
          label: strings.tKey(PlatformAdminKeys.pageProfileFieldLanguage),
          // The dropdown itself shows the language, so the row must not repeat
          // the name next to it.
          value: languageControl == null
              ? (current?.nativeName.isNotEmpty == true
                    ? current!.nativeName
                    : active.toUpperCase())
              : '',
          trailing: languageControl,
        ),
        const _Hairline(),
        _InfoRow(
          label: strings.tKey(PlatformAdminKeys.pageProfileFieldDirection),
          value: direction,
        ),
      ],
    );
  }
}

class _AdminRows extends ConsumerWidget {
  const _AdminRows({required this.strings});

  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeckPalette.of(context);
    final workflowEditing = ref.watch(workflowEditingEnabledProvider);
    final languages = ref.watch(platformLanguagesProvider);
    final audit = ref.watch(auditEventsProvider);
    final health = ref.watch(configHealthProvider);

    final rows = <Widget>[
      _NavRow(
        icon: Icons.translate_rounded,
        title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
        route: '/profile/languages',
        meta: languages.maybeWhen(
          data: (list) {
            final names = list
                .where((item) => item.isLive)
                .map((item) => item.nativeName)
                .where((name) => name.isNotEmpty)
                .join(' · ');
            return names.isEmpty ? null : names;
          },
          orElse: () => null,
        ),
        chip: languages.maybeWhen(
          data: (list) {
            if (list.isEmpty) return null;
            final live = list.where((item) => item.isLive).length;
            final setup = list.where((item) => item.isInSetup).length;
            return DeckChip(
              label: strings.tArgsKey(
                PlatformAdminKeys.sidebarLanguagesStatus,
                <String, Object?>{'live': '$live', 'setup': '$setup'},
              ),
              color: palette.accent,
              soft: palette.accentSoft,
            );
          },
          orElse: () => null,
        ),
      ),
      const _Hairline(),
      _NavRow(
        icon: Icons.rate_review_outlined,
        title: strings.tKey(PlatformAdminKeys.settingsTranslationReviewTitle),
        route: '/configuration/translations',
      ),
      const _Hairline(),
      _NavRow(
        icon: Icons.account_tree_outlined,
        title: strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
        route: '/checklist/option-sets',
      ),
      const _Hairline(),
      _NavRow(
        icon: Icons.policy_outlined,
        title: strings.tKey(PlatformAdminKeys.settingsAuditTitle),
        route: '/audit-log',
        meta: audit.maybeWhen(
          data: (events) {
            if (events.isEmpty) return null;
            final latest = events.first;
            return '${humanizeAuditCode(latest.action)} · '
                '${auditTimestampLabel(latest.occurredAt, Localizations.localeOf(context).toString())}';
          },
          orElse: () => null,
        ),
        chip: audit.maybeWhen(
          data: (events) {
            if (events.isEmpty) {
              return DeckChip(
                label: strings.tKey(PlatformAdminKeys.settingsAuditNoEvents),
                color: palette.faint,
                soft: palette.surface,
              );
            }
            // The API caps the page at 5000 rows: a full page is "5000+".
            final capped = events.length >= 5000;
            return DeckChip(
              label: strings.tArgsKey(
                capped
                    ? PlatformAdminKeys.settingsAuditEventsCountCapped
                    : PlatformAdminKeys.settingsAuditEventsCount,
                <String, Object?>{'count': '${events.length}'},
              ),
              color: palette.accent,
              soft: palette.accentSoft,
            );
          },
          orElse: () => null,
        ),
      ),
      const _Hairline(),
      _NavRow(
        icon: Icons.health_and_safety_outlined,
        title: strings.tKey(PlatformAdminKeys.pageHealthTitle),
        route: '/checklist/health',
        meta: health.maybeWhen(
          data: (data) {
            final issues = data.checks.where((check) => !check.ok).length;
            if (issues == 0) return null;
            final first = data.checks.firstWhere((check) => !check.ok);
            return first.messageEn.isNotEmpty
                ? first.messageEn
                : humanizeAuditCode(first.code);
          },
          orElse: () => null,
        ),
        chip: health.maybeWhen(
          data: (data) {
            final issues = data.checks.where((check) => !check.ok).length;
            if (issues == 0) {
              return DeckChip(
                label: strings.tKey(CommonKeys.statusHealthy),
                color: palette.success,
                soft: palette.success.withValues(alpha: 0.12),
              );
            }
            return DeckChip(
              label: strings.tArgsKey(
                issues == 1
                    ? PlatformAdminKeys.pageProfileHealthIssue
                    : PlatformAdminKeys.pageProfileHealthIssues,
                <String, Object?>{'count': '$issues'},
              ),
              color: palette.warning,
              soft: palette.warning.withValues(alpha: 0.14),
            );
          },
          orElse: () => null,
        ),
      ),
      if (workflowEditing) ...[
        const _Hairline(),
        _NavRow(
          icon: Icons.swap_horiz_rounded,
          title: strings.tKey(PlatformAdminKeys.referenceTransitionsTitle),
          route: '/configuration/transitions',
        ),
      ],
    ];
    return Column(children: rows);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return DeckReveal(
      delay: 40,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(DeckRadius.card),
          border: Border.all(color: palette.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DeckRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: DeckPalette.of(context).border,
    );
  }
}

/// Label on the left, value on the right, optional control after it.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            18,
            compact ? 12 : 14,
            18,
            compact ? 12 : 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: compact ? 118 : 180,
                child: Text(
                  label,
                  style: DeckType.style(
                    12.5,
                    17,
                    FontWeight.w500,
                    palette.muted,
                  ),
                ),
              ),
              Expanded(
                child: value.isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        value,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DeckType.style(
                          13,
                          19,
                          FontWeight.w600,
                          palette.ink,
                        ),
                      ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        );
      },
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({required this.onTap, required this.child, super.key});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeckRadius.chip),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: Text(
              label,
              style: DeckType.style(
                12,
                16,
                FontWeight.w700,
                DeckPalette.of(context).accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.route,
    this.meta,
    this.chip,
  });

  final IconData icon;
  final String title;
  final String route;
  final String? meta;
  final Widget? chip;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Semantics(
      button: true,
      label: meta == null ? title : '$title, $meta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(DeckRadius.tile),
                  ),
                  child: Icon(icon, size: 18, color: palette.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DeckType.style(
                          13.5,
                          18,
                          FontWeight.w600,
                          palette.ink,
                        ),
                      ),
                      if (meta != null && meta!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DeckType.style(
                            12,
                            16,
                            FontWeight.w400,
                            palette.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (chip != null) ...[const SizedBox(width: 12), chip!],
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({required this.strings, required this.trailing});

  final UiMessageStrings strings;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 14, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceTitle),
                style: DeckType.style(13.5, 18, FontWeight.w600, palette.ink),
              ),
              const SizedBox(height: 4),
              Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceBody),
                style: DeckType.style(12, 17, FontWeight.w400, palette.muted),
              ),
            ],
          );
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 12), trailing],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              trailing,
            ],
          );
        },
      ),
    );
  }
}

class _SeedConfirmDialog extends StatelessWidget {
  const _SeedConfirmDialog({
    required this.strings,
    required this.onCancel,
    required this.onConfirm,
  });

  final UiMessageStrings strings;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(DeckRadius.dialog),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceTitle),
                style: DeckType.style(18, 24, FontWeight.w700, palette.ink),
              ),
              const SizedBox(height: 10),
              Text(
                strings.tKey(PlatformAdminKeys.dialogSeedConfirm),
                style: DeckType.style(13, 20, FontWeight.w400, palette.muted),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DeckButton(
                    label: strings.tKey(CommonKeys.buttonCancel),
                    primary: false,
                    onPressed: onCancel,
                  ),
                  const SizedBox(width: 10),
                  DeckButton(
                    label: strings.tKey(
                      PlatformAdminKeys.pageProfileSeedConfirm,
                    ),
                    onPressed: onConfirm,
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
