import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../platform_brand_icon.dart';
import '../platform_nav.dart';
import '../platform_shell_sheets.dart';

/// Platform Admin identity strip — direction A "Docked Command".
///
/// 44px, one line: brand mark, product name (desktop), active section, search
/// (desktop inline, compact second row), language pill, notifications, help,
/// account menu. It is the only place the workspace is named.
///
/// Mirrors the workshop `ShellIdentityStrip` contract: directional insets,
/// never wraps, never grows, RTL-safe.
class PlatformIdentityStrip extends ConsumerStatefulWidget {
  const PlatformIdentityStrip({
    super.key,
    required this.currentRoute,
    this.onSearchChanged,
    this.onNavigate,
  });

  final String currentRoute;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<PlatformIdentityStrip> createState() =>
      _PlatformIdentityStripState();
}

class _PlatformIdentityStripState extends ConsumerState<PlatformIdentityStrip> {
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  bool _searchFocused = false;
  String _searchText = '';

  bool get _searchEnabled => widget.onSearchChanged != null;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onFocus);
    HardwareKeyboard.instance.addHandler(_shortcut);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_shortcut);
    _searchFocus.removeListener(_onFocus);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!mounted) return;
    if (_searchFocused != _searchFocus.hasFocus) {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    }
  }

  bool _shortcut(KeyEvent event) {
    if (event is! KeyDownEvent || !_searchEnabled) return false;
    if (event.logicalKey != LogicalKeyboardKey.keyK) return false;
    final kb = HardwareKeyboard.instance;
    if (!kb.isControlPressed && !kb.isMetaPressed) return false;
    _searchFocus.requestFocus();
    return true;
  }

  void _navigate(String route) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
      return;
    }
    try {
      context.go(route);
    } catch (_) {}
  }

  String _sectionLabel(UiMessageStrings strings) {
    // Audit log lives inside the profile ledger but keeps its own route:
    // label it directly so the strip names the open page.
    if (widget.currentRoute == '/audit-log') {
      return strings.tKey(PlatformAdminKeys.pageAuditTitle);
    }
    // The settings route reads "Profile" (new catalog key).
    if (widget.currentRoute.startsWith('/profile')) {
      return strings.tKey(PlatformAdminKeys.pageProfileTitle);
    }
    for (final entry in PlatformNavData.primaryItems) {
      if (entry.isActive(widget.currentRoute)) {
        return strings.tKey(entry.labelKey);
      }
    }
    return strings.tKey(PlatformAdminKeys.headerTitle);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final section = _sectionLabel(strings);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final showWordmark = constraints.maxWidth >= 900;
        final searchWidth = constraints.maxWidth >= 1100 ? 280.0 : 180.0;
        return Container(
          decoration: const BoxDecoration(
            color: PtTheme.white,
            border: Border(bottom: BorderSide(color: PtTheme.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
                  child: Row(
                    children: [
                      const PlatformBrandMark(size: 26),
                      if (showWordmark) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'TrueReport',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 17 / 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: PtTheme.ink,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 18,
                          margin: const EdgeInsetsDirectional.symmetric(
                            horizontal: 10,
                          ),
                          color: PtTheme.border,
                        ),
                      ] else
                        const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w600,
                            color: PtTheme.muted,
                          ),
                        ),
                      ),
                      if (_searchEnabled && !compact) ...[
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SizedBox(
                            width: searchWidth,
                            child: _StripSearch(
                              focus: _searchFocus,
                              controller: _searchController,
                              focused: _searchFocused,
                              hasText: _searchText.isNotEmpty,
                              strings: strings,
                              onChanged: (v) {
                                setState(() => _searchText = v);
                                widget.onSearchChanged?.call(v);
                              },
                              onClear: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                                widget.onSearchChanged?.call('');
                                _searchFocus.requestFocus();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const _LanguagePill(),
                      const SizedBox(width: 4),
                      _StripIcon(
                        key: const Key('btn-header-notifications'),
                        tooltip: 'Notifications',
                        icon: Icons.notifications_none_rounded,
                        onPressed: () =>
                            showPlatformNotificationsSheet(context),
                      ),
                      _StripIcon(
                        key: const Key('btn-header-help'),
                        tooltip: 'Help',
                        icon: Icons.help_outline_rounded,
                        onPressed: () => showPlatformHelpSheet(context),
                      ),
                      _AccountButton(onNavigate: _navigate),
                    ],
                  ),
                ),
              ),
              if (_searchEnabled && compact)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
                  child: _StripSearch(
                    focus: _searchFocus,
                    controller: _searchController,
                    focused: _searchFocused,
                    hasText: _searchText.isNotEmpty,
                    strings: strings,
                    compactHint: true,
                    onChanged: (v) {
                      setState(() => _searchText = v);
                      widget.onSearchChanged?.call(v);
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchText = '');
                      widget.onSearchChanged?.call('');
                      _searchFocus.requestFocus();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StripSearch extends StatelessWidget {
  const _StripSearch({
    required this.focus,
    required this.controller,
    required this.focused,
    required this.hasText,
    required this.strings,
    required this.onChanged,
    required this.onClear,
    this.compactHint = false,
  });

  final FocusNode focus;
  final TextEditingController controller;
  final bool focused;
  final bool hasText;
  final UiMessageStrings strings;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool compactHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: focused ? PtTheme.deepGreen : PtTheme.border,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, size: 15, color: PtTheme.muted),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              key: const Key('header-search'),
              focusNode: focus,
              controller: controller,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: PtTheme.deepGreen,
              style: PtTheme.font(12.5, lineHeight: 17),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                hintStyle: PtTheme.font(
                  12,
                  lineHeight: 16,
                  color: PtTheme.muted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText) _ClearButton(onPressed: onClear) else const _Keycap(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('btn-header-search-clear'),
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(Icons.close_rounded, size: 14, color: PtTheme.muted),
        ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap();
  @override
  Widget build(BuildContext context) {
    final apple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return IgnorePointer(
      child: Container(
        height: 20,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PtTheme.border),
        ),
        child: Center(
          child: Text(
            apple ? '⌘K' : 'Ctrl K',
            style: PtTheme.font(
              9.5,
              lineHeight: 12,
              weight: FontWeight.w700,
              color: PtTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _StripIcon extends StatelessWidget {
  const _StripIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 44,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: PtTheme.canvas,
                    shape: BoxShape.circle,
                    border: Border.all(color: PtTheme.border),
                  ),
                  child: Icon(icon, size: 16, color: PtTheme.muted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Language pill: one tap target, labelled with the active language.
class _LanguagePill extends ConsumerWidget {
  const _LanguagePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiMessageControllerProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final languages = manifest?.languages ?? const <UiMessageLanguage>[];
    final active = uiState.activeLanguage.toUpperCase();

    if (languages.length <= 1) {
      return Container(
        height: 32,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: PtTheme.canvas,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PtTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded, size: 13, color: PtTheme.muted),
            const SizedBox(width: 5),
            Text(
              active,
              style: PtTheme.font(11, lineHeight: 14, weight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      key: const Key('btn-header-language-selector'),
      tooltip: 'Language',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PtTheme.border),
      ),
      itemBuilder: (ctx) => [
        for (final l in languages)
          PopupMenuItem<String>(
            value: l.code,
            child: Text(l.nativeName.isNotEmpty ? l.nativeName : l.code),
          ),
      ],
      onSelected: (code) async {
        await ref.read(uiMessageSwitcherProvider).switchTo(code);
        try {
          await ref.read(platformConfigApiProvider).setMeLanguage(code);
        } catch (_) {}
      },
      child: Container(
        height: 32,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: PtTheme.canvas,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PtTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded, size: 13, color: PtTheme.muted),
            const SizedBox(width: 5),
            Text(
              active,
              style: PtTheme.font(11, lineHeight: 14, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountButton extends ConsumerWidget {
  const _AccountButton({required this.onNavigate});
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final auth = ref.watch(authControllerProvider);
    final session = auth.value;
    final name = session?.user.displayName.trim() ?? '';
    final initials = platformInitials(name);

    return PopupMenuButton<String>(
      key: const Key('btn-header-user-menu'),
      tooltip: strings.tKey(PlatformAdminKeys.headerAccount),
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PtTheme.border),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 15, color: PtTheme.rose),
              const SizedBox(width: 8),
              Text(
                strings.tKey(CommonKeys.buttonSignOut),
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w600,
                  color: PtTheme.rose,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (v) async {
        if (v == 'signout') {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) {
            try {
              context.go('/signin');
            } catch (_) {}
          }
        }
      },
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: PtTheme.deepGreen,
            shape: BoxShape.circle,
          ),
          child: initials.isEmpty
              ? const Icon(Icons.person_rounded, size: 16, color: PtTheme.white)
              : Text(
                  initials,
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w800,
                    color: PtTheme.white,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Brand mark shared by the strip and the nav sheet.
class PlatformBrandMark extends StatelessWidget {
  const PlatformBrandMark({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'TrueReport',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: PtTheme.deepGreen,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.string(
            platformBrandIconSvg,
            width: size * 0.5,
            height: size * 0.5,
            colorFilter: const ColorFilter.mode(PtTheme.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
