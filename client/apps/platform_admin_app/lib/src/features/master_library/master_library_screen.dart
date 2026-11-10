import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Screen 5 — Shared Master Inspection-Item Library
/// (`05_5._Shared_Master_Inspection-Item_Library`)
///
/// Features:
/// - Desktop sidebar + header integration
/// - Canonical repo header with "Rules Matrix" and "+ New Master Item" CTA
/// - Filter bar with categories: All Categories, Brakes & Calipers, Powertrain, Tires & Axles, Chassis Integrity
/// - Live cluster sync indicator: "SYNCED: 48 Workshop Clusters"
/// - High-fidelity inspection checkpoint cards with code, severity, tags, and edit trigger
/// - Bottom "Master Fleet Sync Policy" broadcast banner with instant push
/// - Fully responsive across 400px mobile to 1280px desktop, zero overflow in RTL
class MasterLibraryScreen extends ConsumerStatefulWidget {
  const MasterLibraryScreen({super.key});

  @override
  ConsumerState<MasterLibraryScreen> createState() =>
      _MasterLibraryScreenState();
}

class _MasterLibraryScreenState extends ConsumerState<MasterLibraryScreen> {
  bool _isSyncing = false;

  static const List<String> _categories = [
    'All Categories',
    'Brakes & Calipers',
    'Powertrain',
    'Tires & Axles',
    'Chassis Integrity',
  ];

  @override
  Widget build(BuildContext context) {
    final activeCategory = ref.watch(masterCategoryFilterProvider);
    final allItems = ref.watch(masterItemsListProvider);
    final searchQuery = ref.watch(masterItemSearchQueryProvider).toLowerCase();

    final filteredItems = allItems.where((item) {
      if (activeCategory != 'All Categories' &&
          item.category != activeCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final matchCode = item.code.toLowerCase().contains(searchQuery);
        final matchTitle = item.title.toLowerCase().contains(searchQuery);
        final matchDesc = item.description.toLowerCase().contains(searchQuery);
        final matchCat = item.category.toLowerCase().contains(searchQuery);
        if (!matchCode && !matchTitle && !matchDesc && !matchCat) return false;
      }
      return true;
    }).toList();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/master-library',
              onNavigate: (route) => context.go(route),
            ),

          // 2. Main Scrollable View
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                PlatformHeader(
                  onSearchChanged: (val) {
                    ref
                        .read(masterItemSearchQueryProvider.notifier)
                        .setQuery(val);
                  },
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section 0: Header & Action Bar
                            _buildHeaderSection(context),

                            const SizedBox(height: 24),

                            // Section 1: Category Filter Tabs & Sync Status
                            _buildFilterAndSyncBar(activeCategory),

                            const SizedBox(height: 20),

                            // Section 2: Cards List
                            if (filteredItems.isEmpty)
                              _buildEmptyState()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _buildItemCard(
                                    context,
                                    filteredItems[index],
                                  );
                                },
                              ),

                            const SizedBox(height: 28),

                            // Section 3: Bottom Master Fleet Sync Policy Banner
                            _buildFleetSyncPolicyBanner(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        // Left Title Group
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: PtTheme.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    'ACTIVE CANONICAL REPO',
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                      tracking: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Global Master Library',
                style: PtTheme.font(
                  30,
                  lineHeight: 36,
                  weight: FontWeight.w800,
                  color: PtTheme.ink,
                  tracking: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Centrally governed diagnostic checkpoints deployed across all workshop nodes',
                style: PtTheme.font(
                  15,
                  lineHeight: 22,
                  weight: FontWeight.w400,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
        ),

        // Right Action Buttons
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('btn-rules-matrix'),
              onPressed: () => _showRulesMatrixDialog(context),
              icon: const Icon(
                Icons.account_tree_outlined,
                size: 16,
                color: PtTheme.ink,
              ),
              label: Text(
                'Rules Matrix',
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PtTheme.border, width: 1.5),
                backgroundColor: PtTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('btn-new-master-item'),
              onPressed: () => context.go('/master-library/new'),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: PtTheme.white,
              ),
              label: Text(
                '+ New Master Item',
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
                foregroundColor: PtTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                elevation: 2,
                shadowColor: const Color(0x33006C49),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterAndSyncBar(String activeCategory) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        // Category Pills
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: PtTheme.border.withValues(alpha: 0.8)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((cat) {
                final isSelected = activeCategory == cat;
                return InkWell(
                  key: Key('filter-cat-$cat'),
                  onTap: () {
                    ref
                        .read(masterCategoryFilterProvider.notifier)
                        .setCategory(cat);
                  },
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PtTheme.deepGreen.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      cat,
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? PtTheme.deepGreen : PtTheme.muted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Live Synced Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: PtTheme.border.withValues(alpha: 0.8)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SYNCED:',
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                    tracking: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: PtTheme.emerald,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x6610B981),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '48 Workshop Clusters',
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, MasterInspectionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          final metaColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code & Requirement Level Row
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PtTheme.canvas,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: PtTheme.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Text(
                      item.code,
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                        tracking: 0.4,
                      ),
                    ),
                  ),
                  _buildRequirementBadge(item.requirementLevel),
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                style: PtTheme.font(
                  17,
                  lineHeight: 22,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                  tracking: -0.2,
                ),
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                item.description,
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w400,
                  color: PtTheme.muted,
                ),
              ),

              const SizedBox(height: 12),

              // Metadata Tags & Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PtTheme.deepGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Category: ${item.category}',
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w600,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                  ),

                  // Capability tags
                  for (final tag in item.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PtTheme.canvas,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: PtTheme.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: PtTheme.font(
                          12,
                          lineHeight: 16,
                          weight: FontWeight.w600,
                          color: PtTheme.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );

          final editAction = SizedBox(
            height: 38,
            child: OutlinedButton.icon(
              key: Key('btn-edit-${item.id}'),
              onPressed: () => context.go('/master-library/${item.id}/edit'),
              icon: const Icon(
                Icons.edit_outlined,
                size: 15,
                color: PtTheme.deepGreen,
              ),
              label: Text(
                'Edit',
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: PtTheme.deepGreen.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                metaColumn,
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: editAction,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: metaColumn),
              const SizedBox(width: 20),
              editAction,
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequirementBadge(String level) {
    Color textColor = PtTheme.deepGreen;
    Color bgColor = PtTheme.emerald.withValues(alpha: 0.12);

    if (level == 'High Voltage Cert') {
      textColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
    } else if (level == 'Structural') {
      textColor = const Color(0xFF4F46E5);
      bgColor = const Color(0xFFEEF2FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFleetSyncPolicyBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 14,
        children: [
          // Left: Icon + Info
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PtTheme.deepGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: PtTheme.deepGreen,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Fleet Sync Policy',
                        style: PtTheme.font(
                          15,
                          lineHeight: 20,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Next synchronized release pushes to edge terminals automatically at 02:00 UTC.',
                        style: PtTheme.font(
                          13,
                          lineHeight: 18,
                          weight: FontWeight.w400,
                          color: PtTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Instant Push Button
          OutlinedButton.icon(
            key: const Key('btn-instant-push'),
            onPressed: _isSyncing ? null : () => _performInstantPush(context),
            icon: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PtTheme.deepGreen,
                    ),
                  )
                : const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: PtTheme.deepGreen,
                  ),
            label: Text(
              _isSyncing ? 'Broadcasting...' : 'Instant Push',
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: PtTheme.deepGreen.withValues(alpha: 0.5),
                width: 1.4,
              ),
              backgroundColor: PtTheme.canvas,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: PtTheme.muted,
            ),
            const SizedBox(height: 12),
            Text(
              'No inspection items found',
              style: PtTheme.font(
                16,
                lineHeight: 22,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search criteria or active category filter.',
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w400,
                color: PtTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performInstantPush(BuildContext context) async {
    setState(() => _isSyncing = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || !context.mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: PtTheme.deepGreen,
        content: Text(
          'Fleet sync successfully broadcast to 48 workshop clusters.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRulesMatrixDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Master Rules Governance Matrix',
            style: PtTheme.font(
              18,
              lineHeight: 24,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canonical Inspection Rules and Override Thresholds:',
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w600,
                    color: PtTheme.muted,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRuleRow(
                  '1. Mandatory Signoff',
                  'Critical safety checkpoints require dual technician verification.',
                ),
                const SizedBox(height: 10),
                _buildRuleRow(
                  '2. Photo Validation',
                  'Camera capture required before state transition to QA cleared.',
                ),
                const SizedBox(height: 10),
                _buildRuleRow(
                  '3. Telemetry Stream Link',
                  'CAN bus / OBD-II live telemetry auto-fills numeric parameters.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Close',
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRuleRow(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: PtTheme.deepGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              Text(
                desc,
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
      ],
    );
  }
}
