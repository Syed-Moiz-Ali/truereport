import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../features/languages/language_workspace_screen.dart';
import '../platform_config_models.dart';
import '../platform_providers.dart';
import '../platform_theme.dart';
import '../reference_status_lookup.dart';
import 'platform_nav.dart';

/// SVG path for the CoreOS brand hub/network icon from Figma (Icon-1_3514.svg).
const _brandIconSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path id="Icon" d="M5 19.1667C4.30556 19.1667 3.71528 18.9236 3.22917 18.4375C2.74306 17.9514 2.5 17.3611 2.5 16.6667C2.5 15.9722 2.74306 15.3819 3.22917 14.8958C3.71528 14.4097 4.30556 14.1667 5 14.1667C5.19444 14.1667 5.375 14.1875 5.54167 14.2292C5.70833 14.2708 5.86806 14.3264 6.02083 14.3958L7.20833 12.9167C6.81944 12.4861 6.54861 12 6.39583 11.4583C6.24306 10.9167 6.20833 10.375 6.29167 9.83333L4.60417 9.27083C4.36806 9.61806 4.06944 9.89583 3.70833 10.1042C3.34722 10.3125 2.94444 10.4167 2.5 10.4167C1.80556 10.4167 1.21528 10.1736 0.729167 9.6875C0.243056 9.20139 0 8.61111 0 7.91667C0 7.22222 0.243056 6.63194 0.729167 6.14583C1.21528 5.65972 1.80556 5.41667 2.5 5.41667C3.19444 5.41667 3.78472 5.65972 4.27083 6.14583C4.75694 6.63194 5 7.22222 5 7.91667C5 7.94444 5 7.97222 5 8C5 8.02778 5 8.05556 5 8.08333L6.6875 8.66667C6.96528 8.16667 7.33681 7.74306 7.80208 7.39583C8.26736 7.04861 8.79167 6.82639 9.375 6.72917V4.91667C8.83333 4.76389 8.38542 4.46875 8.03125 4.03125C7.67708 3.59375 7.5 3.08333 7.5 2.5C7.5 1.80556 7.74306 1.21528 8.22917 0.729167C8.71528 0.243056 9.30556 0 10 0C10.6944 0 11.2847 0.243056 11.7708 0.729167C12.2569 1.21528 12.5 1.80556 12.5 2.5C12.5 3.08333 12.3194 3.59375 11.9583 4.03125C11.5972 4.46875 11.1528 4.76389 10.625 4.91667V6.72917C11.2083 6.82639 11.7326 7.04861 12.1979 7.39583C12.6632 7.74306 13.0347 8.16667 13.3125 8.66667L15 8.08333C15 8.05556 15 8.02778 15 8C15 7.97222 15 7.94444 15 7.91667C15 7.22222 15.2431 6.63194 15.7292 6.14583C16.2153 5.65972 16.8056 5.41667 17.5 5.41667C18.1944 5.41667 18.7847 5.65972 19.2708 6.14583C19.7569 6.63194 20 7.22222 20 7.91667C20 8.61111 19.7569 9.20139 19.2708 9.6875C18.7847 10.1736 18.1944 10.4167 17.5 10.4167C17.0556 10.4167 16.6493 10.3125 16.2812 10.1042C15.9132 9.89583 15.6181 9.61806 15.3958 9.27083L13.7083 9.83333C13.7917 10.375 13.7569 10.9132 13.6042 11.4479C13.4514 11.9826 13.1806 12.4722 12.7917 12.9167L13.9792 14.375C14.1319 14.3056 14.2917 14.2535 14.4583 14.2188C14.625 14.184 14.8056 14.1667 15 14.1667C15.6944 14.1667 16.2847 14.4097 16.7708 14.8958C17.2569 15.3819 17.5 15.9722 17.5 16.6667C17.5 17.3611 17.2569 17.9514 16.7708 18.4375C16.2847 18.9236 15.6944 19.1667 15 19.1667C14.3056 19.1667 13.7153 18.9236 13.2292 18.4375C12.7431 17.9514 12.5 17.3611 12.5 16.6667C12.5 16.3889 12.5451 16.1215 12.6354 15.8646C12.7257 15.6076 12.8472 15.375 13 15.1667L11.8125 13.6875C11.2431 14.0069 10.6354 14.1667 9.98958 14.1667C9.34375 14.1667 8.73611 14.0069 8.16667 13.6875L7 15.1667C7.15278 15.375 7.27431 15.6076 7.36458 15.8646C7.45486 16.1215 7.5 16.3889 7.5 16.6667C7.5 17.3611 7.25694 17.9514 6.77083 18.4375C6.28472 18.9236 5.69444 19.1667 5 19.1667V19.1667M2.5 8.75C2.73611 8.75 2.93403 8.67014 3.09375 8.51042C3.25347 8.35069 3.33333 8.15278 3.33333 7.91667C3.33333 7.68056 3.25347 7.48264 3.09375 7.32292C2.93403 7.16319 2.73611 7.08333 2.5 7.08333C2.26389 7.08333 2.06597 7.16319 1.90625 7.32292C1.74653 7.48264 1.66667 7.68056 1.66667 7.91667C1.66667 8.15278 1.74653 8.35069 1.90625 8.51042C2.06597 8.67014 2.26389 8.75 2.5 8.75V8.75M5 17.5C5.23611 17.5 5.43403 17.4201 5.59375 17.2604C5.75347 17.1007 5.83333 16.9028 5.83333 16.6667C5.83333 16.4306 5.75347 16.2326 5.59375 16.0729C5.43403 15.9132 5.23611 15.8333 5 15.8333C4.76389 15.8333 4.56597 15.9132 4.40625 16.0729C4.24653 16.2326 4.16667 16.4306 4.16667 16.6667C4.16667 16.9028 4.24653 17.1007 4.40625 17.2604C4.56597 17.4201 4.76389 17.5 5 17.5V17.5M17.5 8.75C17.7361 8.75 17.934 8.67014 18.0938 8.51042C18.2535 8.35069 18.3333 8.15278 18.3333 7.91667C18.3333 7.68056 18.2535 7.48264 18.0938 7.32292C17.934 7.16319 17.7361 7.08333 17.5 7.08333C17.2639 7.08333 17.066 7.16319 16.9062 7.32292C16.7465 7.48264 16.6667 7.68056 16.6667 7.91667C16.6667 8.15278 16.7465 8.35069 16.9062 8.51042C17.066 8.67014 17.2639 8.75 17.5 8.75V8.75"/>
</svg>
''';

/// Shared Platform Admin Sidebar matching the clean, calm, premium direction.
class PlatformSidebar extends ConsumerWidget {
  const PlatformSidebar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
  });

  final String currentRoute;
  final ValueChanged<String>? onNavigate;

  void _navigate(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Sidebar width: target ~260px, allowed range 248-272px.
    final sidebarWidth = (screenWidth * 0.2).clamp(248.0, 272.0);

    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: BorderDirectional(
          end: BorderSide(color: PtTheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Brand Block matching design tokens
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: PtTheme.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.string(
                      _brandIconSvg,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        PtTheme.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TrueReport',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          16,
                          lineHeight: 20,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                          tracking: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        strings.tKey(PlatformAdminKeys.headerTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),

          const Divider(height: 1, color: PtTheme.border),
          const SizedBox(height: 8),

          // 2. Primary navigation (exactly 6 items)
          Expanded(
            child: PlatformNavList(
              currentRoute: currentRoute,
              onNavigate: (route) => _navigate(context, route),
              keyPrefix: 'nav-',
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),

          // 3. Actionable Localization / Status Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: _ActionableSidebarLanguageCard(
              onNavigate: (route) => _navigate(context, route),
            ),
          ),

          // Real system operational status capsule
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 14, 6),
            child: Container(
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PtTheme.border.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: PtTheme.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.tKey(PlatformAdminKeys.sidebarSystemOperational),
                      style: PtTheme.font(
                        10,
                        lineHeight: 14,
                        weight: FontWeight.w600,
                        color: PtTheme.muted,
                        tracking: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: PtTheme.muted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
          const Divider(height: 1, color: PtTheme.border),

          // 4. User account area at the bottom
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 14),
            child: _SidebarUserAccount(
              onSignOut: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  try {
                    context.go('/signin');
                  } catch (_) {}
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Actionable language setup status card.
///
/// Discovers incomplete languages, queries readiness data for the top priority
/// language, computes the exact next action/tab, and links directly to it.
class _ActionableSidebarLanguageCard extends ConsumerWidget {
  const _ActionableSidebarLanguageCard({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final languagesAsync = ref.watch(platformLanguagesProvider);

    return languagesAsync.when(
      data: (languages) {
        if (languages.isEmpty) return const SizedBox.shrink();

        final inSetup = languages.where((l) => l.isInSetup).toList();

        // 1. No languages in setup: quiet success state
        if (inSetup.isEmpty) {
          return Container(
            key: const Key('sidebar-language-status-card'),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PtTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: PtTheme.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.tKey(PlatformAdminKeys.sidebarLanguagesAllLive),
                        style: PtTheme.font(
                          11,
                          lineHeight: 15,
                          weight: FontWeight.w600,
                          color: PtTheme.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    key: const Key('btn-sidebar-view-languages'),
                    onTap: () => onNavigate('/settings/languages'),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        strings.tKey(
                          PlatformAdminKeys.sidebarLanguagesViewLanguages,
                        ),
                        style: PtTheme.font(
                          11,
                          lineHeight: 14,
                          weight: FontWeight.w600,
                          color: PtTheme.deepGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _PrioritySetupSelector(
          candidates: inSetup,
          onNavigate: onNavigate,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PrioritySetupSelector extends ConsumerWidget {
  const _PrioritySetupSelector({
    required this.candidates,
    required this.onNavigate,
  });

  final List<PlatformLanguage> candidates;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    // Map each candidate with its readiness data (if available) to calculate urgency score.
    // Lower score = higher priority.
    // 1. REVIEW with no blockers (score 1)
    // 2. 100% ready but not LIVE (score 2)
    // 3. TRANSLATING or running generation (score 3)
    // 4. DRAFT with UI path but missing content (score 4)
    // 5. DRAFT with no UI path (score 5)
    // Fallback: 6

    final scored = <MapEntry<PlatformLanguage, int>>[];

    for (final lang in candidates) {
      final readiness = ref.watch(readinessProvider(lang.code)).asData?.value;
      var score = 6;
      if (readiness != null) {
        if (readiness.blockers.isNotEmpty) {
          score = 3;
        } else if (readiness.readinessPercent < 100) {
          score = 4;
        }
      }
      scored.add(MapEntry(lang, score));
    }

    // Sort stable by score, preserving original order on ties
    scored.sort((a, b) => a.value.compareTo(b.value));

    final targetLang = scored.first.key;
    final moreCount = candidates.length - 1;

    return _TargetLanguageReadinessCard(
      language: targetLang,
      moreCount: moreCount,
      onNavigate: onNavigate,
    );
  }
}

class _TargetLanguageReadinessCard extends ConsumerWidget {
  const _TargetLanguageReadinessCard({
    required this.language,
    required this.moreCount,
    required this.onNavigate,
  });

  final PlatformLanguage language;
  final int moreCount;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final readinessAsync = ref.watch(readinessProvider(language.code));

    return readinessAsync.when(
      data: (readiness) {
        var targetTab = LanguageWorkspaceTab.overview;
        if (readiness.blockers.isNotEmpty) {
          targetTab = readiness.blockers.first.tab;
        }
        const actionKey = PlatformAdminKeys.sidebarLanguagesActionView;

        final targetRoute =
            '/settings/languages/${language.code}?tab=$targetTab';

        return Container(
          key: const Key('sidebar-language-status-card'),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PtTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Native Name + Code + More Count
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: PtTheme.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${language.nativeName.isNotEmpty ? language.nativeName : language.code.toUpperCase()} (${language.code.toUpperCase()})',
                      style: PtTheme.font(
                        11,
                        lineHeight: 15,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (moreCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: PtTheme.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: PtTheme.border),
                      ),
                      child: Text(
                        strings.tArgsKey(
                          PlatformAdminKeys.sidebarLanguagesMore,
                          {'count': '$moreCount'},
                        ),
                        style: PtTheme.caption,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),

              Text(
                referenceCodeLabel(
                  strings,
                  ref.watch(statusesProvider(translationStatusDomain)).value,
                  readiness.status.isNotEmpty
                      ? readiness.status
                      : language.status,
                ),
                style: PtTheme.font(
                  10,
                  lineHeight: 14,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              Text(
                strings.tArgsKey(PlatformAdminKeys.sidebarLanguagesProgress, {
                  'translated': '${readiness.readinessPercent}',
                  'total': '100',
                  'percent': '${readiness.readinessPercent}',
                }),
                style: PtTheme.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Primary Actionable CTA
              InkWell(
                key: const Key('btn-sidebar-language-action'),
                onTap: () => onNavigate(targetRoute),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          strings.tKey(actionKey),
                          style: PtTheme.font(
                            11,
                            lineHeight: 14,
                            weight: FontWeight.w600,
                            color: PtTheme.deepGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: PtTheme.deepGreen,
                      ),
                    ],
                  ),
                ),
              ),

              // Secondary "View all languages" if multiple incomplete
              if (moreCount > 0) ...[
                const SizedBox(height: 4),
                InkWell(
                  key: const Key('btn-sidebar-view-all-languages'),
                  onTap: () => onNavigate('/settings/languages'),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      strings.tKey(PlatformAdminKeys.sidebarLanguagesViewAll),
                      style: PtTheme.font(
                        10,
                        lineHeight: 13,
                        weight: FontWeight.w500,
                        color: PtTheme.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        key: const Key('sidebar-language-status-card'),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: PtTheme.canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PtTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: PtTheme.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${language.nativeName.isNotEmpty ? language.nativeName : language.code.toUpperCase()} (${language.code.toUpperCase()})',
                    style: PtTheme.font(
                      11,
                      lineHeight: 15,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              language.status,
              style: PtTheme.font(
                10,
                lineHeight: 14,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            const LinearProgressIndicator(
              key: Key('sidebar-language-loading'),
              minHeight: 2,
              backgroundColor: PtTheme.border,
              color: PtTheme.deepGreen,
            ),
          ],
        ),
      ),
      error: (_, _) => Container(
        key: const Key('sidebar-language-status-card'),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: PtTheme.canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PtTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: PtTheme.rose,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${language.nativeName.isNotEmpty ? language.nativeName : language.code.toUpperCase()} (${language.code.toUpperCase()})',
                    style: PtTheme.font(
                      11,
                      lineHeight: 15,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              strings.tKey(CommonKeys.statusUnhealthy),
              style: PtTheme.font(
                10,
                lineHeight: 14,
                weight: FontWeight.w500,
                color: PtTheme.rose,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: const Key('btn-sidebar-retry-readiness'),
              onTap: () => ref.invalidate(readinessProvider(language.code)),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.tKey(CommonKeys.buttonRetry),
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w600,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: PtTheme.deepGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User / account area at the bottom of the sidebar.
class _SidebarUserAccount extends ConsumerWidget {
  const _SidebarUserAccount({required this.onSignOut});

  final VoidCallback onSignOut;

  String _roleLabel(dynamic strings, Session? session) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final auth = ref.watch(authControllerProvider);
    final session = auth.value;
    final displayName = session?.user.displayName.trim() ?? '';
    final role = _roleLabel(strings, session);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            shape: BoxShape.circle,
            border: Border.all(color: PtTheme.border),
          ),
          child: const Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: PtTheme.muted,
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
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                  color: PtTheme.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  style: PtTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          key: const Key('btn-sidebar-sign-out'),
          tooltip: strings.tKey(CommonKeys.buttonSignOut),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.logout_rounded,
            size: 17,
            color: PtTheme.muted,
          ),
          onPressed: onSignOut,
        ),
      ],
    );
  }
}
