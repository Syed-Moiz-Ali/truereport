import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_nav.dart';
import 'platform_rail.dart';
import 'platform_shell_sheets.dart';

/// The command deck's top bar.
///
/// One surface carries context (wordmark + active section), the page filter
/// (search, with a real keyboard shortcut), and the four global actions:
/// language, notifications, help and the account menu. At compact widths it
/// becomes a 56px context row plus an optional search row, with the full
/// navigation sheet behind the menu button.
class PlatformCommandBar extends ConsumerStatefulWidget {
  const PlatformCommandBar({
    super.key,
    required this.currentRoute,
    this.onSearchChanged,
    this.onNavigate,
  });

  final String currentRoute;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<PlatformCommandBar> createState() => _PlatformCommandBarState();
}

class _PlatformCommandBarState extends ConsumerState<PlatformCommandBar> {
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  bool _searchFocused = false;
  String _searchText = '';

  bool get _searchEnabled => widget.onSearchChanged != null;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_handleSearchFocus);
    HardwareKeyboard.instance.addHandler(_handleShortcut);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleShortcut);
    _searchFocus.removeListener(_handleSearchFocus);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchFocus() {
    if (!mounted) return;
    if (_searchFocused != _searchFocus.hasFocus) {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    }
  }

  bool _handleShortcut(KeyEvent event) {
    if (event is! KeyDownEvent || !_searchEnabled) return false;
    if (event.logicalKey != LogicalKeyboardKey.keyK) return false;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return false;
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
        // The rail is 76px wide; keep the bar out of its compact mode while
        // the rail is visible so navigation never appears twice on screen.
        final compact = constraints.maxWidth < 820;
        if (compact) {
          return _buildCompact(context, strings, section);
        }
        return _buildDesktop(context, strings, section, constraints.maxWidth);
      },
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    UiMessageStrings strings,
    String section,
    double width,
  ) {
    final showSection = width >= 1080;
    final showIdentity = width >= 1180;
    final showKeycap = width >= 1120;

    return Container(
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: Border(bottom: BorderSide(color: PtTheme.border, width: 1)),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 24,
        vertical: 8,
      ),
      child: Row(
        children: [
          Text(
            'TrueReport',
            style: PtTheme.font(
              15,
              lineHeight: 19,
              weight: FontWeight.w800,
              tracking: -0.3,
            ),
          ),
          if (showSection) ...[
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              color: PtTheme.border,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                section,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PtTheme.font(
                  12.5,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ),
          ],
          const SizedBox(width: 24),
          if (_searchEnabled)
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildSearchField(
                    strings,
                    compactHint: false,
                    showKeycap: showKeycap,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          const _LanguageSelector(),
          const SizedBox(width: 6),
          _CommandIconButton(
            key: const Key('btn-header-notifications'),
            tooltip: strings.tKey(PlatformAdminKeys.headerNotifications),
            icon: Icons.notifications_none_rounded,
            onPressed: () => showPlatformNotificationsSheet(context),
          ),
          const SizedBox(width: 4),
          _CommandIconButton(
            key: const Key('btn-header-help'),
            tooltip: strings.tKey(PlatformAdminKeys.headerHelp),
            icon: Icons.help_outline_rounded,
            onPressed: () => showPlatformHelpSheet(context),
          ),
          const SizedBox(width: 8),
          _UserMenu(showIdentity: showIdentity, onNavigate: _navigate),
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    UiMessageStrings strings,
    String section,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: Border(bottom: BorderSide(color: PtTheme.border, width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _MobileMenuButton(
                    label: strings.tKey(PlatformAdminKeys.headerTitle),
                    onPressed: () => showPlatformMobileNavSheet(
                      context,
                      currentRoute: widget.currentRoute,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const PlatformBrandMark(size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        15,
                        lineHeight: 19,
                        weight: FontWeight.w800,
                        tracking: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UserMenu(showIdentity: false, onNavigate: _navigate),
                ],
              ),
            ),
          ),
          if (_searchEnabled)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 10),
              child: _buildSearchField(
                strings,
                compactHint: true,
                showKeycap: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    UiMessageStrings strings, {
    required bool compactHint,
    required bool showKeycap,
  }) {
    return Container(
      height: PtTheme.controlHeight,
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(PtTheme.fieldRadius),
        border: Border.all(
          color: _searchFocused ? PtTheme.deepGreen : PtTheme.border,
          width: _searchFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, size: 18, color: PtTheme.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const Key('header-search'),
              focusNode: _searchFocus,
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchText = value);
                widget.onSearchChanged?.call(value);
              },
              textAlignVertical: TextAlignVertical.center,
              cursorColor: PtTheme.deepGreen,
              style: PtTheme.font(13, lineHeight: 18),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: compactHint
                    ? strings.tKey(PlatformAdminKeys.headerSearchHintCompact)
                    : strings.tKey(PlatformAdminKeys.headerSearchHint),
                hintStyle: PtTheme.font(
                  13,
                  lineHeight: 18,
                  color: PtTheme.muted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchText.isNotEmpty)
            _SearchClearButton(
              label: strings.tKey(CommonKeys.buttonClose),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchText = '');
                widget.onSearchChanged?.call('');
                _searchFocus.requestFocus();
              },
            )
          else if (showKeycap)
            const _ShortcutKeycap(),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _MobileMenuButton extends StatelessWidget {
  const _MobileMenuButton({required this.label, required this.onPressed});

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
            key: const Key('btn-mobile-nav-menu'),
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: PtTheme.border),
              ),
              child: const Icon(
                Icons.menu_rounded,
                size: 20,
                color: PtTheme.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchClearButton extends StatelessWidget {
  const _SearchClearButton({required this.label, required this.onPressed});

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
            key: const Key('btn-header-search-clear'),
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 30,
              height: 30,
              child: Icon(Icons.close_rounded, size: 16, color: PtTheme.muted),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutKeycap extends StatelessWidget {
  const _ShortcutKeycap();

  @override
  Widget build(BuildContext context) {
    final isApple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return IgnorePointer(
      child: Container(
        height: 24,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PtTheme.border),
        ),
        child: Center(
          child: Text(
            isApple ? '\u2318 K' : 'Ctrl K',
            style: PtTheme.font(
              10,
              lineHeight: 13,
              weight: FontWeight.w700,
              color: PtTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandIconButton extends StatelessWidget {
  const _CommandIconButton({
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
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: PtTheme.border),
              ),
              child: Icon(icon, size: 18, color: PtTheme.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sole primary language selector for the command bar.
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final uiState = ref.watch(uiMessageControllerProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final languages = manifest?.languages ?? const <UiMessageLanguage>[];
    final activeCode = uiState.activeLanguage;

    final activeLang = languages.firstWhere(
      (language) => language.code == activeCode,
      orElse: () => UiMessageLanguage(
        code: activeCode,
        direction: 'ltr',
        nativeName: activeCode.toUpperCase(),
      ),
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 768;
    final veryCompact = screenWidth < 480;
    final selectorText = isCompact
        ? activeLang.code.toUpperCase()
        : activeLang.nativeName.isNotEmpty &&
              activeLang.nativeName != activeLang.code.toUpperCase()
        ? '${activeLang.nativeName} (${activeLang.code.toUpperCase()})'
        : activeLang.code.toUpperCase();

    // A single-language manifest must not render an empty/broken dropdown.
    if (languages.length <= 1) {
      final label = activeLang.nativeName.isNotEmpty
          ? activeLang.nativeName
          : activeLang.code.toUpperCase();
      return Container(
        key: const Key('header-language-static'),
        height: 44,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: veryCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: PtTheme.canvas,
          borderRadius: BorderRadius.circular(PtTheme.controlRadius),
          border: Border.all(color: PtTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!veryCompact) ...[
              const Icon(
                Icons.translate_rounded,
                size: 15,
                color: PtTheme.muted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: PtTheme.font(11, lineHeight: 15, weight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      key: const Key('btn-header-language-selector'),
      tooltip: strings.tKey(PlatformAdminKeys.headerLanguageSelector),
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PtTheme.border),
      ),
      elevation: 3,
      itemBuilder: (ctx) => [
        for (final language in languages)
          PopupMenuItem<String>(
            key: Key('header-language-${language.code}'),
            value: language.code,
            child: Row(
              children: [
                Icon(
                  language.code == activeCode
                      ? Icons.check_rounded
                      : Icons.translate_rounded,
                  size: 16,
                  color: language.code == activeCode
                      ? PtTheme.deepGreen
                      : PtTheme.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    language.nativeName.isNotEmpty
                        ? language.nativeName
                        : language.displayName,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: language.code == activeCode
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  language.code.toUpperCase(),
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w600,
                    color: PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (code) async {
        await ref.read(uiMessageSwitcherProvider).switchTo(code);
        try {
          await ref.read(platformConfigApiProvider).setMeLanguage(code);
        } catch (_) {}
      },
      child: Container(
        height: 44,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: veryCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: PtTheme.canvas,
          borderRadius: BorderRadius.circular(PtTheme.controlRadius),
          border: Border.all(color: PtTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!veryCompact) ...[
              const Icon(
                Icons.translate_rounded,
                size: 15,
                color: PtTheme.muted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              selectorText,
              style: PtTheme.font(11, lineHeight: 15, weight: FontWeight.w700),
            ),
            if (!veryCompact) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: PtTheme.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.showIdentity, required this.onNavigate});

  final bool showIdentity;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final auth = ref.watch(authControllerProvider);
    final session = auth.value;
    final displayName = session?.user.displayName.trim() ?? '';
    final email = session?.user.email.trim() ?? '';
    final roleLabel = platformRoleLabel(strings, session);
    final initials = platformInitials(displayName);
    final uiState = ref.watch(uiMessageControllerProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final menuLanguages = manifest?.languages ?? const <UiMessageLanguage>[];
    final activeCode = uiState.activeLanguage;

    final activeLang = menuLanguages.firstWhere(
      (language) => language.code == activeCode,
      orElse: () => UiMessageLanguage(
        code: activeCode,
        direction: 'ltr',
        nativeName: activeCode.toUpperCase(),
      ),
    );

    final avatar = Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: PtTheme.deepGreen,
        shape: BoxShape.circle,
      ),
      child: initials.isEmpty
          ? const Icon(Icons.person_rounded, size: 18, color: PtTheme.white)
          : Text(
              initials,
              style: PtTheme.font(
                12,
                lineHeight: 15,
                weight: FontWeight.w800,
                color: PtTheme.white,
              ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: PtTheme.font(
                        12,
                        lineHeight: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (roleLabel.isNotEmpty)
                      Text(
                        roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: PtTheme.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              avatar,
            ],
          )
        : avatar;

    return PopupMenuButton<String>(
      key: const Key('btn-header-user-menu'),
      tooltip: strings.tKey(PlatformAdminKeys.headerAccount),
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PtTheme.border),
      ),
      elevation: 3,
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
                      ),
                    ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: PtTheme.font(
                        11,
                        lineHeight: 15,
                        color: PtTheme.muted,
                      ),
                    ),
                ],
              ),
            ),
          if (displayName.isNotEmpty || email.isNotEmpty)
            const PopupMenuDivider(),
          PopupMenuItem<String>(
            key: const Key('menu-item-language-info'),
            value: 'languages-settings',
            child: Row(
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 16,
                  color: PtTheme.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.tArgsKey(PlatformAdminKeys.headerUserMenuLanguage, {
                      'name': activeLang.nativeName.isNotEmpty
                          ? activeLang.nativeName
                          : activeLang.code.toUpperCase(),
                    }),
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            key: const Key('menu-sign-out'),
            value: 'signout',
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, size: 16, color: PtTheme.rose),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.tKey(CommonKeys.buttonSignOut),
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w600,
                      color: PtTheme.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) async {
        if (value == 'languages-settings') {
          onNavigate('/settings/languages');
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
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PtTheme.fieldRadius),
          ),
          child: label,
        ),
      ),
    );
  }
}
