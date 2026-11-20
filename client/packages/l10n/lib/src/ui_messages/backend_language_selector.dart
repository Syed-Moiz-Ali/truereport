import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_message_controller.dart';
import 'ui_message_manifest.dart';

/// The one language selector for all apps.
///
/// Purely manifest-driven: it renders whatever the backend advertises and
/// disappears when only one language is available. Styling uses [Theme] and
/// [InkWell] only, so this package never depends on `design_system`.
class BackendLanguageSelector extends ConsumerWidget {
  const BackendLanguageSelector({
    required this.client,
    this.keyPrefix = 'backend-language',
    this.alignment = WrapAlignment.start,
    this.compact = false,
    this.onChanged,
    super.key,
  });

  final String client;

  /// Prefix for each option's widget key, e.g. `settings-language-en`.
  final String keyPrefix;
  final WrapAlignment alignment;
  final bool compact;

  /// Called after the language actually changed.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(languageSelectionProvider(client));
    final manifest = selection.manifest;
    if (manifest == null || manifest.languages.length < 2) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final language in manifest.languages)
          _LanguageOption(
            key: Key('$keyPrefix-${language.code}'),
            language: language,
            selected: language.code == selection.activeLanguage,
            compact: compact,
            onTap: () async {
              final switched = await ref
                  .read(languageSelectionProvider(client).notifier)
                  .useLanguage(language.code);
              if (switched) onChanged?.call(language.code);
            },
          ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final UiMessageLanguage language;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(compact ? 10 : 12);

    return Semantics(
      button: true,
      selected: selected,
      label: language.displayName,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                minHeight: 44,
                minWidth: compact ? 44 : 88,
              ),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                language.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boots the shared language selection for [client] once per app lifetime.
class UiMessageBootstrap extends ConsumerStatefulWidget {
  const UiMessageBootstrap({
    required this.client,
    required this.child,
    this.onAuthFailure,
    super.key,
  });

  final String client;
  final Widget child;

  /// Called once when the bootstrap fails with 401/403.
  ///
  /// Apps wire this to the session layer so a dead token is cleared and the
  /// router sends the user to sign-in instead of retrying forever.
  final VoidCallback? onAuthFailure;

  @override
  ConsumerState<UiMessageBootstrap> createState() => _UiMessageBootstrapState();
}

class _UiMessageBootstrapState extends ConsumerState<UiMessageBootstrap> {
  bool _authFailureNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(languageSelectionProvider(widget.client).notifier).bootstrap();
    });
  }

  int? _statusOf(Object? error) {
    if (error == null) return null;
    try {
      final dynamic value = error;
      final status = value.statusCode;
      return status is int ? status : null;
    } on Object {
      return null;
    }
  }

  void _maybeNotifyAuthFailure(UiMessageState selection) {
    if (selection.bootError == null) {
      _authFailureNotified = false;
      return;
    }
    if (selection.booting || _authFailureNotified) return;
    final status = _statusOf(selection.bootError);
    if (status != 401 && status != 403) return;
    _authFailureNotified = true;
    final handler = widget.onAuthFailure;
    if (handler == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) handler();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(languageSelectionProvider(widget.client));
    if (selection.ready) return widget.child;

    _maybeNotifyAuthFailure(selection);

    final theme = Theme.of(context);
    if (!selection.booting && selection.bootError != null) {
      return ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: IconButton(
            key: const Key('ui-message-retry'),
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
            onPressed: () => ref
                .read(languageSelectionProvider(widget.client).notifier)
                .bootstrap(),
          ),
        ),
      );
    }
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
