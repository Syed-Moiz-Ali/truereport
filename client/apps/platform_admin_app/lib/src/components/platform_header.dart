import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';

class PlatformHeader extends ConsumerWidget {
  const PlatformHeader({super.key, this.onSearchChanged});

  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(platformLocaleProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        return Container(
          constraints: const BoxConstraints(minHeight: 56, maxHeight: 80),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 24,
            vertical: 8,
          ),
          decoration: const BoxDecoration(
            color: PtTheme.white,
            border: Border(bottom: BorderSide(color: PtTheme.border, width: 1)),
          ),
          child: Row(
            children: [
              if (isCompact) ...[
                IconButton(
                  key: const Key('btn-mobile-nav-menu'),
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 22,
                    color: PtTheme.ink,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _openMobileNav(context),
                ),
                const SizedBox(width: 8),
              ],

              // 1. Search Bar
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 38),
                      decoration: BoxDecoration(
                        color: PtTheme.canvas,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: PtTheme.border),
                      ),
                      child: TextField(
                        onChanged: onSearchChanged,
                        style: PtTheme.font(
                          13,
                          lineHeight: 18,
                          weight: FontWeight.w400,
                          color: PtTheme.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: isCompact ? 'Search...' : 'Search platform assets, specs, workshop nodes...',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Notification Bell Action
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PtTheme.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PtTheme.border),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 18,
                    color: PtTheme.muted,
                  ),
                  onPressed: () {},
                ),
              ),

              const SizedBox(width: 8),

              // 3. Language Switcher (EN / AR)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PtTheme.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PtTheme.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    final next =
                        ref.read(platformLocaleProvider).languageCode == 'en'
                        ? 'ar'
                        : 'en';
                    ref.read(platformLocaleProvider.notifier).toggle();
                    ref
                        .read(platformConfigApiProvider)
                        .setMeLanguage(next)
                        .then((_) {}, onError: (_) {});
                  },
                  child: Center(
                    child: Text(
                      currentLocale.languageCode.toUpperCase(),
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w700,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                  ),
                ),
              ),

              if (!isCompact) ...[
                const SizedBox(width: 12),

                // 4. User Profile Chip
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Alex Vance',
                                style: PtTheme.font(
                                  13,
                                  lineHeight: 16,
                                  weight: FontWeight.w600,
                                  color: PtTheme.ink,
                                ),
                              ),
                              Text(
                                'Principal Admin',
                                style: PtTheme.font(
                                  11,
                                  lineHeight: 14,
                                  weight: FontWeight.w400,
                                  color: PtTheme.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: PtTheme.deepGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PtTheme.deepGreen.withValues(
                                  alpha: 0.24,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'AV',
                                style: PtTheme.font(
                                  12,
                                  lineHeight: 16,
                                  weight: FontWeight.w700,
                                  color: PtTheme.deepGreen,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openMobileNav(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final platformTitle = l10n?.platformAdminTitle ?? 'Platform Navigation';
    final workshopsLabel = l10n?.workshops ?? 'Workshops';
    final masterLibraryLabel = l10n?.masterLibrary ?? 'Master Library';
    final dataCataloguesLabel = l10n?.dataCatalogues ?? 'Data Catalogues';
    final equipmentLabel = l10n?.equipment ?? 'Equipment';
    final settingsLabel = l10n?.settings ?? 'Settings';
    final auditLogLabel = l10n?.auditLog ?? 'Audit Log';
    showModalBottomSheet<void>(
      context: context,
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
                _buildMobileNavItem(
                  ctx,
                  key: const Key('mobile-nav-workshops'),
                  icon: Icons.apartment_rounded,
                  label: workshopsLabel,
                  route: '/workshops',
                ),
                _buildMobileNavItem(
                  ctx,
                  key: const Key('mobile-nav-master-library'),
                  icon: Icons.menu_book_rounded,
                  label: masterLibraryLabel,
                  route: '/master-library',
                ),
                _buildMobileNavItem(
                  ctx,
                  key: const Key('mobile-nav-data-catalogues'),
                  icon: Icons.folder_open_rounded,
                  label: dataCataloguesLabel,
                  route: '/data-catalogues',
                ),
                _buildMobileNavItem(
                  ctx,
                  key: const Key('mobile-nav-equipment'),
                  icon: Icons.construction_rounded,
                  label: equipmentLabel,
                  route: '/equipment',
                ),
                _buildMobileNavItem(
                  ctx,
                  key: const Key('mobile-nav-settings'),
                  icon: Icons.settings_outlined,
                  label: settingsLabel,
                  route: '/settings',
                ),
                _buildMobileNavItem(
                  ctx,
                  key: const Key('mobile-nav-audit-log'),
                  icon: Icons.verified_user_outlined,
                  label: auditLogLabel,
                  route: '/audit-log',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileNavItem(
    BuildContext ctx, {
    required Key key,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return ListTile(
      key: key,
      leading: Icon(icon, color: PtTheme.deepGreen, size: 22),
      title: Text(
        label,
        style: PtTheme.font(
          14,
          lineHeight: 20,
          weight: FontWeight.w600,
          color: PtTheme.ink,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: PtTheme.muted,
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        ctx.go(route);
      },
    );
  }
}
