import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'components/platform_states.dart';

class UiMessagesBootstrap extends ConsumerStatefulWidget {
  const UiMessagesBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UiMessagesBootstrap> createState() =>
      _UiMessagesBootstrapState();
}

class _UiMessagesBootstrapState extends ConsumerState<UiMessagesBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(uiMessageControllerProvider.notifier).bootstrap();
    });
  }

  void _syncLanguage() {
    final active = ref.read(uiMessageControllerProvider).activeLanguage;
    final current = ref.read(localeProvider);
    final target = localeForLanguage(active);
    if (current.languageCode != target.languageCode ||
        current.scriptCode != target.scriptCode ||
        current.countryCode != target.countryCode) {
      ref.read(localeProvider.notifier).setLocale(target);
    }
    ref.read(apiClientProvider).acceptLanguage = active;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(uiMessageControllerProvider.select((state) => state.ready), (
      _,
      ready,
    ) {
      if (ready) _syncLanguage();
    });
    ref.listen(
      uiMessageControllerProvider.select((state) => state.activeLanguage),
      (_, _) => _syncLanguage(),
    );
    final uiState = ref.watch(uiMessageControllerProvider);
    if (uiState.ready) return widget.child;
    final controller = ref.read(uiMessageControllerProvider.notifier);
    if (!uiState.booting && uiState.bootError != null) {
      final errorText = controller.tKey(CommonKeys.errorGeneric);
      final retryText = controller.tKey(CommonKeys.buttonRetry);
      if (errorText == CommonKeys.errorGeneric.qualified &&
          retryText == CommonKeys.buttonRetry.qualified) {
        return const _BootstrapRetryFallback();
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PlatformErrorView(
            message: errorText,
            retryLabel: retryText == CommonKeys.buttonRetry.qualified
                ? null
                : retryText,
            onRetry: () =>
                ref.read(uiMessageControllerProvider.notifier).bootstrap(),
          ),
        ),
      );
    }
    final loadingText = controller.tKey(CommonKeys.stateLoading);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PlatformLoadingView(
          message: loadingText == CommonKeys.stateLoading.qualified
              ? ''
              : loadingText,
        ),
      ),
    );
  }
}

class _BootstrapRetryFallback extends ConsumerWidget {
  const _BootstrapRetryFallback();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  ref.read(uiMessageControllerProvider.notifier).bootstrap(),
            ),
          ],
        ),
      ),
    );
  }
}
