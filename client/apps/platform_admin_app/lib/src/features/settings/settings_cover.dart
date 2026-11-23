import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell_sheets.dart';
import '../../platform_providers.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Region 0 — the identity cover (Direction A "Identity Hero").
///
/// A dark band carries the person: avatar, name, role, the language switch
/// and sign-out. Everything renders from existing providers; loading shows
/// the band's own skeleton, error shows a retry — never a spinner.
class SettingsCover extends ConsumerWidget {
  const SettingsCover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final auth = ref.watch(authControllerProvider);

    return DeckReveal(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DeckRadius.hero),
        child: Container(
          color: DeckPalette.of(context).hero,
          padding: const EdgeInsets.all(24),
          child: auth.when(
            loading: () => const _CoverSkeleton(),
            error: (_, _) => _CoverError(
              message: strings.tKey(CommonKeys.stateError),
              retryLabel: strings.tKey(CommonKeys.buttonRetry),
              onRetry: () => ref.invalidate(authControllerProvider),
            ),
            data: (session) {
              if (session == null) return const _CoverSkeleton();
              return _CoverBody(strings: strings, session: session);
            },
          ),
        ),
      ),
    );
  }
}

class _CoverBody extends StatelessWidget {
  const _CoverBody({required this.strings, required this.session});

  final UiMessageStrings strings;
  final Session session;

  @override
  Widget build(BuildContext context) {
    final name = session.user.displayName.trim();
    final email = session.user.email.trim();
    final title = name.isNotEmpty
        ? name
        : strings.tKey(PlatformAdminKeys.headerAccount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final identity = _Identity(
          title: title,
          email: email,
          role: platformRoleLabel(strings, session),
          initials: platformInitials(name),
        );
        const actions = SizedBox(width: 220, child: _CoverActions());
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 24),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [identity, const SizedBox(height: 20), actions],
        );
      },
    );
  }
}

/// Identity block shared by both layouts. Extracted so the wide Row keeps a
/// single definition site.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.title,
    required this.email,
    required this.role,
    required this.initials,
  });

  final String title;
  final String email;
  final String role;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: initials.isEmpty
              ? const Icon(Icons.person_rounded, size: 28, color: Colors.white)
              : Text(
                  initials,
                  style: DeckType.style(22, 26, FontWeight.w800, Colors.white),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: title,
                child: Text(
                  title,
                  style: DeckType.style(26, 32, FontWeight.w800, Colors.white),
                  maxLines: 2,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Tooltip(
                  message: email,
                  child: Text(
                    email,
                    style: DeckType.style(
                      13,
                      19,
                      FontWeight.w400,
                      DeckPalette.of(context).heroMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (role.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: DeckType.style(
                      10.5,
                      14,
                      FontWeight.w800,
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverActions extends ConsumerWidget {
  const _CoverActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final palette = DeckPalette.of(context);
    final uiState = ref.watch(uiMessageControllerProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final active = uiState.activeLanguage;

    Widget languageControl;
    final languages = manifest?.languages ?? const <UiMessageLanguage>[];
    if (languages.length <= 1) {
      final only = languages.isEmpty
          ? null
          : (languages.first.nativeName.isNotEmpty
                ? languages.first.nativeName
                : languages.first.code.toUpperCase());
      languageControl = only == null
          ? const SizedBox.shrink()
          : Text(
              only,
              style: DeckType.style(13, 19, FontWeight.w600, Colors.white),
            );
    } else {
      // One fixed row of equal thirds: the rail is 220px, so three
      // code chips always fit and never stack into a tower.
      languageControl = Row(
        children: [
          for (var i = 0; i < languages.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CoverLangChip(
                code: languages[i].code.toUpperCase(),
                active: languages[i].code == active,
                onTap: languages[i].code == active
                    ? null
                    : () async {
                        await ref
                            .read(uiMessageSwitcherProvider)
                            .switchTo(languages[i].code);
                        try {
                          await ref
                              .read(platformConfigApiProvider)
                              .setMeLanguage(languages[i].code);
                        } catch (_) {}
                      },
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        languageControl,
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: strings.tKey(CommonKeys.buttonSignOut),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  try {
                    context.go('/signin');
                  } catch (_) {}
                }
              },
              borderRadius: BorderRadius.circular(DeckRadius.button),
              child: Container(
                height: DeckSize.buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DeckRadius.button),
                  border: Border.all(
                    color: palette.danger.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  strings.tKey(CommonKeys.buttonSignOut),
                  style: DeckType.style(
                    13,
                    18,
                    FontWeight.w600,
                    palette.danger,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverLangChip extends StatelessWidget {
  const _CoverLangChip({required this.code, required this.active, this.onTap});

  final String code;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Semantics(
      button: true,
      selected: active,
      label: code,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeckRadius.chip),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DeckRadius.chip),
              border: Border.all(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              code,
              style: DeckType.style(
                11,
                14,
                FontWeight.w800,
                active ? palette.hero : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverSkeleton extends StatelessWidget {
  const _CoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DeckSkeleton(width: 64, height: 64, radius: 32),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DeckSkeleton(width: 200, height: 28, radius: 8),
              SizedBox(height: 8),
              DeckSkeleton(width: 160, height: 14, radius: 7),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverError extends StatelessWidget {
  const _CoverError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: DeckType.style(16, 22, FontWeight.w600, Colors.white),
        ),
        const SizedBox(height: 14),
        DeckButton(
          label: retryLabel,
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
