import 'package:flutter/material.dart';

/// First-paint gate shown while the backend message bundle is loading.
///
/// The gate is state-only on purpose: with no bundle there is no copy to show,
/// so it renders a spinner in the app's surface colour instead of a blank page.
class UiMessageLoadingGate extends StatelessWidget {
  const UiMessageLoadingGate({super.key});

  /// Finder key applied by the bootstrap around the loading surface.
  static const Key gateKey = Key('ui-message-loading');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Semantics(
          container: true,
          liveRegion: true,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

/// Copy-free error + retry for a failed bundle load.
///
/// English is never shipped from Dart: the only word on screen comes from
/// Flutter's own [MaterialLocalizations.refreshIndicatorSemanticLabel], and the
/// action calls back into the app's `languageSelectionProvider.bootstrap()` so
/// the retry runs a real fetch rather than replaying a cached failure.
class UiMessageErrorGate extends StatelessWidget {
  const UiMessageErrorGate({required this.onRetry, super.key});

  /// Finder key applied by the bootstrap around the error surface.
  static const Key gateKey = Key('ui-message-error');
  static const Key retryKey = Key('ui-message-retry');

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refreshLabel = MaterialLocalizations.of(context)
        .refreshIndicatorSemanticLabel;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: retryKey,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(refreshLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(128, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
