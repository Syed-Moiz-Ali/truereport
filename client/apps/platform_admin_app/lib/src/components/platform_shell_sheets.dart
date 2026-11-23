import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_nav.dart';
import 'shell/platform_identity_strip.dart';

/// Overlays owned by the shell: notifications, help, and the full navigation
/// sheet used at compact widths. Keeping them in one file means the command
/// bar and the mobile dock open exactly the same surfaces.

const _sheetMaxWidth = 544.0;

String platformRoleLabel(UiMessageStrings strings, Session? session) {
  if (session == null) return '';
  if (session.user.platformAdmin) {
    return strings.tKey(CommonKeys.rolePlatformAdmin);
  }
  switch (session.role) {
    case Role.platformAdmin:
      return strings.tKey(CommonKeys.rolePlatformAdmin);
    case Role.workshopAdmin:
      return strings.tKey(CommonKeys.roleWorkshopAdmin);
    case Role.technician:
      return strings.tKey(CommonKeys.roleTechnician);
  }
}

String platformInitials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    final value = parts.first;
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Future<void> _showSheet(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: PtTheme.ink.withValues(alpha: 0.32),
    constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
        child: _SheetSurface(child: builder(ctx)),
      );
    },
  );
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PtTheme.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 20),
          child: child,
        ),
      ),
    );
  }
}

class _SheetGrip extends StatelessWidget {
  const _SheetGrip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: PtTheme.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(uiStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetGrip(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: PtTheme.font(
                  17,
                  lineHeight: 22,
                  weight: FontWeight.w800,
                  tracking: -0.2,
                ),
              ),
            ),
            _SheetCloseButton(
              label: strings.tKey(CommonKeys.buttonClose),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: PtTheme.border),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: PtTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

void showPlatformNotificationsSheet(BuildContext context) {
  _showSheet(
    context,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final strings = ref.watch(uiStringsProvider);
        return Column(
          key: const Key('notifications-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              title: strings.tKey(PlatformAdminKeys.headerNotificationsTitle),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 26, 20, 24),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PtTheme.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: PtTheme.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                      color: PtTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.tKey(PlatformAdminKeys.headerNotificationsEmpty),
                    textAlign: TextAlign.center,
                    style: PtTheme.font(
                      14.5,
                      lineHeight: 20,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.tKey(
                      PlatformAdminKeys.headerNotificationsEmptyBody,
                    ),
                    textAlign: TextAlign.center,
                    style: PtTheme.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Help
// ---------------------------------------------------------------------------

void showPlatformHelpSheet(BuildContext context) {
  _showSheet(
    context,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final strings = ref.watch(uiStringsProvider);
        final contact = strings.tKey(PlatformAdminKeys.headerHelpContact);
        return Column(
          key: const Key('help-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              title: strings.tKey(PlatformAdminKeys.headerHelpTitle),
            ),
            const SizedBox(height: 10),
            Text(
              strings.tKey(PlatformAdminKeys.headerHelpBody),
              style: PtTheme.bodyMuted,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PtTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: PtTheme.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 19,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      contact,
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SheetPillButton(
                    key: const Key('btn-help-copy-contact'),
                    label: strings.tKey(CommonKeys.buttonCopy),
                    icon: Icons.copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: contact));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(contact),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.tKey(PlatformAdminKeys.headerHelpDocs),
              style: PtTheme.font(12, lineHeight: 16, color: PtTheme.muted),
            ),
          ],
        );
      },
    ),
  );
}

class _SheetPillButton extends StatelessWidget {
  const _SheetPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: PtTheme.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full navigation sheet (compact widths)
// ---------------------------------------------------------------------------

void showPlatformMobileNavSheet(
  BuildContext context, {
  required String currentRoute,
  ValueChanged<String>? onNavigate,
}) {
  _showSheet(
    context,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final strings = ref.watch(uiStringsProvider);
        final auth = ref.watch(authControllerProvider);
        final session = auth.value;
        final displayName = session?.user.displayName.trim() ?? '';
        final email = session?.user.email.trim() ?? '';
        final role = platformRoleLabel(strings, session);
        final manifest = ref.watch(platformUiManifestProvider);
        final languages = manifest?.languages ?? const <UiMessageLanguage>[];
        final activeLanguage = ref.watch(
          uiMessageControllerProvider.select((state) => state.activeLanguage),
        );

        void go(String route) {
          Navigator.of(ctx).pop();
          if (onNavigate != null) {
            onNavigate(route);
            return;
          }
          try {
            context.go(route);
          } catch (_) {}
        }

        return Column(
          key: const Key('mobile-nav-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetGrip(),
            const SizedBox(height: 14),
            Row(
              children: [
                const PlatformBrandMark(size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TrueReport',
                        style: PtTheme.font(
                          15,
                          lineHeight: 19,
                          weight: FontWeight.w800,
                          tracking: -0.2,
                        ),
                      ),
                      Text(
                        strings.tKey(PlatformAdminKeys.headerTitle),
                        style: PtTheme.font(
                          11,
                          lineHeight: 14,
                          weight: FontWeight.w600,
                          color: PtTheme.muted,
                          tracking: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _SheetCloseButton(
                  label: strings.tKey(CommonKeys.buttonClose),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in PlatformNavData.primaryItems)
              _NavSheetRow(
                key: Key('mobile-nav-${entry.id}'),
                icon: entry.icon,
                label: strings.tKey(entry.labelKey),
                active: entry.isActive(currentRoute),
                onTap: () => go(entry.route),
              ),
            const SizedBox(height: 12),
            Container(height: 1, color: PtTheme.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    key: const Key('btn-mobile-notifications'),
                    icon: Icons.notifications_none_rounded,
                    label: strings.tKey(PlatformAdminKeys.headerNotifications),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      showPlatformNotificationsSheet(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    key: const Key('btn-mobile-help'),
                    icon: Icons.help_outline_rounded,
                    label: strings.tKey(PlatformAdminKeys.headerHelp),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      showPlatformHelpSheet(context);
                    },
                  ),
                ),
              ],
            ),
            if (languages.length > 1) ...[
              const SizedBox(height: 18),
              Text(
                strings.tKey(PlatformAdminKeys.headerLanguageSelector),
                style: PtTheme.font(
                  10,
                  lineHeight: 13,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                  tracking: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in languages)
                    _LanguageChip(
                      key: Key('mobile-language-${language.code}'),
                      label: language.nativeName.isNotEmpty
                          ? language.nativeName
                          : language.code.toUpperCase(),
                      code: language.code.toUpperCase(),
                      active: language.code == activeLanguage,
                      onTap: () async {
                        await ref
                            .read(uiMessageSwitcherProvider)
                            .switchTo(language.code);
                        try {
                          await ref
                              .read(platformConfigApiProvider)
                              .setMeLanguage(language.code);
                        } catch (_) {}
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PtTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: PtTheme.deepGreen,
                      shape: BoxShape.circle,
                    ),
                    child: displayName.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 19,
                            color: PtTheme.white,
                          )
                        : Text(
                            platformInitials(displayName),
                            style: PtTheme.font(
                              13,
                              lineHeight: 16,
                              weight: FontWeight.w800,
                              color: PtTheme.white,
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
                          displayName.isNotEmpty
                              ? displayName
                              : strings.tKey(PlatformAdminKeys.headerAccount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            12.5,
                            lineHeight: 16,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          role.isNotEmpty ? role : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SheetPillButton(
                    key: const Key('btn-mobile-sign-out'),
                    label: strings.tKey(CommonKeys.buttonSignOut),
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      final controller = ref.read(
                        authControllerProvider.notifier,
                      );
                      Navigator.of(ctx).pop();
                      await controller.signOut();
                      if (context.mounted) {
                        try {
                          context.go('/signin');
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _NavSheetRow extends StatelessWidget {
  const _NavSheetRow({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            hoverColor: PtTheme.canvas,
            child: Container(
              height: 48,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFEAF4EF) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: active ? PtTheme.deepGreen : PtTheme.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        13.5,
                        lineHeight: 18,
                        weight: active ? FontWeight.w700 : FontWeight.w600,
                        color: active ? PtTheme.deepGreen : PtTheme.ink,
                      ),
                    ),
                  ),
                  if (active)
                    const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: PtTheme.deepGreen,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
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
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 46,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PtTheme.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: PtTheme.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PtTheme.font(
                      12,
                      lineHeight: 16,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    super.key,
    required this.label,
    required this.code,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '$label ($code)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 32,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active ? PtTheme.deepGreen : PtTheme.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? PtTheme.deepGreen : PtTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: PtTheme.font(
                    11.5,
                    lineHeight: 15,
                    weight: FontWeight.w700,
                    color: active ? PtTheme.white : PtTheme.ink,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  code,
                  style: PtTheme.font(
                    10,
                    lineHeight: 13,
                    weight: FontWeight.w700,
                    color: active
                        ? PtTheme.white.withValues(alpha: 0.75)
                        : PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
