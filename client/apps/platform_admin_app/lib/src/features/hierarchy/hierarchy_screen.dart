import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'add_staff_panel.dart';
import 'staff_board.dart';
import 'tree_node_navigator.dart';

class HierarchyScreen extends ConsumerStatefulWidget {
  const HierarchyScreen({super.key});

  @override
  ConsumerState<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends ConsumerState<HierarchyScreen> {
  String _activeViewMode = 'Directory View';

  @override
  Widget build(BuildContext context) {
    final hierarchyAsync = ref.watch(hierarchyStateProvider);
    final selectedWorkshopId = ref.watch(selectedWorkshopIdProvider);
    final isAddStaffOpen = ref.watch(addStaffPanelOpenProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Desktop Left Sidebar
          const PlatformSidebar(currentRoute: '/workshops'),

          // 2. Main Area (Header + Content)
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                PlatformHeader(
                  onSearchChanged: (val) {
                    ref.read(staffSearchQueryProvider.notifier).setQuery(val);
                  },
                ),

                // Scrollable Content Body with Slide-out Panel Overlay
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: hierarchyAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: PtTheme.deepGreen,
                            ),
                          ),
                          error: (err, stack) => Center(
                            child: Text(
                              '${Localizations.of<AppLocalizations>(context, AppLocalizations)?.actionFailed ?? "Error"}: $err',
                            ),
                          ),
                          data: (hierarchy) {
                            final selectedWorkshop = hierarchy.workshops.firstWhere(
                              (w) => w.id == selectedWorkshopId,
                              orElse: () => hierarchy.workshops.isNotEmpty
                                  ? hierarchy.workshops.first
                                  : const HierarchyWorkshop(
                                      id: 'fallback',
                                      name: 'Workshop A',
                                      branchName: 'EMEA Industrial',
                                      status: 'ACTIVE',
                                      memberCount: 14,
                                      admins: [],
                                      technicians: [],
                                      pendingInvitations: [],
                                    ),
                            );

                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 24,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1200),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Context Bar & View Controls
                                      _buildContextBar(),

                                      const SizedBox(height: 20),

                                      // Asymmetric Split Layout: Left Node Hierarchy | Right Detail Board
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          if (constraints.maxWidth < 800) {
                                            // Stack vertically for compact widths
                                            return Column(
                                              children: [
                                                TreeNodeNavigator(
                                                  workshops: hierarchy.workshops,
                                                  selectedWorkshopId:
                                                      selectedWorkshopId,
                                                  onSelectWorkshop: (id) {
                                                    ref
                                                        .read(
                                                          selectedWorkshopIdProvider
                                                              .notifier,
                                                        )
                                                        .select(id);
                                                  },
                                                  onRegisterWorkshop: () =>
                                                      context.go('/workshops/register'),
                                                  onOpenDetails: (id) =>
                                                      context.go('/workshops/$id'),
                                                ),
                                                const SizedBox(height: 20),
                                                StaffBoard(
                                                  workshop: selectedWorkshop,
                                                  onAddStaff: () {
                                                    ref
                                                        .read(
                                                          addStaffPanelOpenProvider
                                                              .notifier,
                                                        )
                                                        .open();
                                                  },
                                                  onRegisterWorkshop: () =>
                                                      context.go('/workshops/register'),
                                                  onOpenDetails: () =>
                                                      context.go('/workshops/${selectedWorkshop.id}'),
                                                ),
                                              ],
                                            );
                                          }

                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TreeNodeNavigator(
                                                workshops: hierarchy.workshops,
                                                selectedWorkshopId:
                                                    selectedWorkshopId,
                                                onSelectWorkshop: (id) {
                                                  ref
                                                      .read(
                                                        selectedWorkshopIdProvider
                                                            .notifier,
                                                      )
                                                      .select(id);
                                                },
                                                onRegisterWorkshop: () =>
                                                    context.go('/workshops/register'),
                                                onOpenDetails: (id) =>
                                                    context.go('/workshops/$id'),
                                              ),
                                              const SizedBox(width: 24),
                                              Expanded(
                                                child: StaffBoard(
                                                  workshop: selectedWorkshop,
                                                  onAddStaff: () {
                                                    ref
                                                        .read(
                                                          addStaffPanelOpenProvider
                                                              .notifier,
                                                        )
                                                        .open();
                                                  },
                                                  onRegisterWorkshop: () =>
                                                      context.go('/workshops/register'),
                                                  onOpenDetails: () =>
                                                      context.go('/workshops/${selectedWorkshop.id}'),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Screen 2 Slide-out Creation Panel (440px)
                      if (isAddStaffOpen) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            key: const Key('add-staff-backdrop'),
                            onTap: () {
                              ref
                                  .read(addStaffPanelOpenProvider.notifier)
                                  .close();
                            },
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 0,
                          bottom: 0,
                          end: 0,
                          child: AddStaffSlideOutPanel(
                            initialWorkshopId: selectedWorkshopId,
                            onClose: () {
                              ref
                                  .read(addStaffPanelOpenProvider.notifier)
                                  .close();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBar() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        // Breadcrumb
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'HIERARCHY ROOT',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.muted,
                tracking: 0.5,
              ),
            ),
            Text(
              '/',
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w500,
                color: PtTheme.muted,
              ),
            ),
            Text(
              'EMEA INDUSTRIAL',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.muted,
                tracking: 0.5,
              ),
            ),
            Text(
              '/',
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w500,
                color: PtTheme.muted,
              ),
            ),
            Text(
              'Active Workshops',
              style: PtTheme.font(
                15,
                lineHeight: 22,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
          ],
        ),

        // Segmented pill mode switcher
        Container(
          height: 38,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: PtTheme.border,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentButton(
                icon: Icons.folder_open_rounded,
                buttonText: 'Directory View',
                isSelected: _activeViewMode == 'Directory View',
                onTap: () => setState(() => _activeViewMode = 'Directory View'),
              ),
              _buildSegmentButton(
                icon: Icons.show_chart_rounded,
                buttonText: 'Throughput',
                isSelected: _activeViewMode == 'Throughput',
                onTap: () => setState(() => _activeViewMode = 'Throughput'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required IconData icon,
    required String buttonText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? PtTheme.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? PtTheme.ink : PtTheme.muted,
              ),
              const SizedBox(width: 8),
              Text(
                buttonText,
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? PtTheme.ink : PtTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
