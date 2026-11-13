import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_nav.dart';

import 'package:l10n/l10n.dart';

/// Reusable Platform Admin app header.
///
/// Two layers live in the shell: this app header (search, notifications,
/// help, user menu) and [PlatformContextBar] below it (page-provided
/// breadcrumbs + actions). Page-specific breadcrumbs never live here.
class PlatformHeader extends ConsumerWidget {
  const PlatformHeader({
    super.key,
    this.onSearchChanged,
    this.currentRoute,
    this.onNavigate,
  });

  final ValueChanged<String>? onSearchChanged;
  final String? currentRoute;
  final ValueChanged<String>? onNavigate;

  String _resolveCurrentRoute(BuildContext context) {
    if (currentRoute != null && currentRoute!.isNotEmpty) {
      return currentRoute!;
    }
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return ModalRoute.of(context)?.settings.name ?? '';
    }
  }

  void _navigate(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
      return;
    }
    try {
      context.go(route);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showMobileNav = constraints.maxWidth < 900;
        final isCompact = constraints.maxWidth < 600;
        final showIdentity = constraints.maxWidth >= 900;
        final horizontalPadding = isCompact ? 14.0 : 24.0;

        return Container(
          constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
          padding: EdgeInsetsDirectional.fromSTEB(
            horizontalPadding,
            12,
            horizontalPadding,
            12,
          ),
          decoration: const BoxDecoration(
            color: PtTheme.white,
            border: Border(bottom: BorderSide(color: PtTheme.border, width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showMobileNav) ...[
                IconButton(
                  key: const Key('btn-mobile-nav-menu'),
                  tooltip: strings.tKey(PlatformAdminKeys.headerTitle),
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 22,
                    color: PtTheme.ink,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: () => _openMobileNav(context),
                ),
                SizedBox(width: isCompact ? 4 : 8),
              ],
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 480 : 560,
                    ),
                    child: _HeaderSearchField(
                      isCompact: isCompact,
                      onChanged: onSearchChanged,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 6 : 12),
              _HeaderCircleAction(
                key: const Key('btn-header-notifications'),
                tooltip: strings.tKey(PlatformAdminKeys.headerNotifications),
                icon: Icons.notifications_none_rounded,
                semanticLabel: strings.tKey(
                  PlatformAdminKeys.headerNotifications,
                ),
                onPressed: () => _openNotificationsSheet(context),
              ),
              const SizedBox(width: 4),
              _HeaderCircleAction(
                key: const Key('btn-header-help'),
                tooltip: strings.tKey(PlatformAdminKeys.headerHelp),
                icon: Icons.help_outline_rounded,
                semanticLabel: strings.tKey(PlatformAdminKeys.headerHelp),
                onPressed: () => _openHelpSheet(context),
              ),
              SizedBox(width: isCompact ? 4 : 8),
              _UserMenu(showIdentity: showIdentity),
            ],
          ),
        );
      },
    );
  }

  void _openNotificationsSheet(BuildContext context) {
    final strings = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(uiStringsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PtTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
            child: Column(
              key: const Key('notifications-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.tKey(
                          PlatformAdminKeys.headerNotificationsTitle,
                        ),
                        style: PtTheme.font(
                          16,
                          lineHeight: 22,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.tKey(CommonKeys.buttonClose),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PtTheme.canvas,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: PtTheme.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 24,
                          color: PtTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.tKey(
                          PlatformAdminKeys.headerNotificationsEmpty,
                        ),
                        style: PtTheme.font(
                          14,
                          lineHeight: 20,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.tKey(
                          PlatformAdminKeys.headerNotificationsEmptyBody,
                        ),
                        style: PtTheme.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openHelpSheet(BuildContext context) {
    final strings = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(uiStringsProvider);
    final contact = strings.tKey(PlatformAdminKeys.headerHelpContact);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PtTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
            child: Column(
              key: const Key('help-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.tKey(PlatformAdminKeys.headerHelpTitle),
                        style: PtTheme.font(
                          16,
                          lineHeight: 22,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.tKey(CommonKeys.buttonClose),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.tKey(PlatformAdminKeys.headerHelpBody),
                  style: PtTheme.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: PtTheme.canvas,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        size: 20,
                        color: PtTheme.deepGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          contact,
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: contact));
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(contact),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(strings.tKey(CommonKeys.buttonCopy)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.tKey(PlatformAdminKeys.headerHelpDocs),
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w500,
                    color: PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMobileNav(BuildContext context) {
    final strings = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(uiStringsProvider);
    final platformTitle = strings.tKey(PlatformAdminKeys.headerTitle);
    final currentPath = _resolveCurrentRoute(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PtTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      platformTitle,
                      style: PtTheme.font(
                        16,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: PlatformNavList(
                    currentRoute: currentPath,
                    onNavigate: (route) {
                      Navigator.of(ctx).pop();
                      _navigate(context, route);
                    },
                    keyPrefix: 'mobile-nav-',
                    shrinkWrap: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSearchField extends ConsumerStatefulWidget {
  const _HeaderSearchField({required this.isCompact, this.onChanged});

  final bool isCompact;
  final ValueChanged<String>? onChanged;

  @override
  ConsumerState<_HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends ConsumerState<_HeaderSearchField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    // Keep the border width identical in both states so focusing never
    // shifts the layout; only the color changes to the emerald ring.
    final borderColor = _focused ? PtTheme.emerald : Colors.transparent;
    final hint = widget.isCompact
        ? strings.tKey(PlatformAdminKeys.headerSearchHintCompact)
        : strings.tKey(PlatformAdminKeys.headerSearchHint);

    return Container(
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: TextField(
        key: const Key('header-search'),
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: PtTheme.font(
          13,
          lineHeight: 18,
          weight: FontWeight.w400,
          color: PtTheme.ink,
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: hint,
          hintStyle: PtTheme.font(
            13,
            lineHeight: 18,
            weight: FontWeight.w400,
            color: PtTheme.muted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: PtTheme.muted,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  const _HeaderCircleAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: PtTheme.canvas,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20, color: PtTheme.muted),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.showIdentity});

  final bool showIdentity;

  String _roleLabel(dynamic strings, Session? session) {
    if (session == null) {
      return '';
    }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final auth = ref.watch(authControllerProvider);
    final session = auth.value;
    final displayName = session?.user.displayName.trim() ?? '';
    final email = session?.user.email.trim() ?? '';
    final roleLabel = _roleLabel(strings, session);
    final uiState = ref.watch(uiMessageControllerProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final menuLanguages = manifest?.languages ?? const <UiMessageLanguage>[];
    final activeCode = uiState.activeLanguage;

    final avatar = Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: PtTheme.emerald,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 20, color: PtTheme.white),
      ),
    );

    final Widget label = showIdentity && displayName.isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: PtTheme.font(
                        13,
                        lineHeight: 16,
                        weight: FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    if (roleLabel.isNotEmpty)
                      Text(
                        roleLabel,
                        style: PtTheme.font(
                          11,
                          lineHeight: 14,
                          weight: FontWeight.w400,
                          color: PtTheme.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              avatar,
            ],
          )
        : avatar;

    return PopupMenuButton<String>(
      key: const Key('btn-header-user-menu'),
      tooltip: strings.tKey(PlatformAdminKeys.headerAccount),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (menuContext) {
        return [
          if (displayName.isNotEmpty || email.isNotEmpty)
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (displayName.isNotEmpty)
                    Text(
                      displayName,
                      style: PtTheme.font(
                        13,
                        lineHeight: 16,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w400,
                        color: PtTheme.muted,
                      ),
                    ),
                ],
              ),
            ),
          if (displayName.isNotEmpty || email.isNotEmpty)
            const PopupMenuDivider(),
          for (final language in menuLanguages)
            PopupMenuItem<String>(
              key: Key('menu-language-${language.code}'),
              value: 'lang:${language.code}',
              child: Row(
                children: [
                  Icon(
                    language.code == activeCode
                        ? Icons.check_rounded
                        : Icons.translate_rounded,
                    size: 18,
                    color: language.code == activeCode
                        ? PtTheme.deepGreen
                        : PtTheme.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      language.displayName,
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        weight: FontWeight.w500,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                  Text(
                    language.code.toUpperCase(),
                    style: PtTheme.font(
                      12,
                      lineHeight: 16,
                      weight: FontWeight.w700,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuItem<String>(
            key: const Key('menu-sign-out'),
            value: 'signout',
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: PtTheme.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.tKey(CommonKeys.buttonSignOut),
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w500,
                      color: PtTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) async {
        if (value.startsWith('lang:')) {
          final code = value.substring('lang:'.length);
          await ref.read(uiMessageSwitcherProvider).switchTo(code);
          try {
            await ref.read(platformConfigApiProvider).setMeLanguage(code);
          } catch (_) {}
          return;
        }
        if (value == 'signout') {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) {
            try {
              context.go('/signin');
            } catch (_) {}
          }
        }
      },
      child: Semantics(
        button: true,
        label: displayName.isEmpty
            ? strings.tKey(PlatformAdminKeys.headerAccount)
            : '$displayName${roleLabel.isEmpty ? '' : ', $roleLabel'}',
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: label,
        ),
      ),
    );
  }
}
