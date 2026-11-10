import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import '../../platform_models.dart';
import '../../platform_theme.dart';

class TreeNodeNavigator extends ConsumerWidget {
  const TreeNodeNavigator({
    super.key,
    required this.workshops,
    required this.selectedWorkshopId,
    required this.onSelectWorkshop,
    this.onRegisterWorkshop,
    this.onOpenDetails,
  });

  final List<HierarchyWorkshop> workshops;
  final String selectedWorkshopId;
  final ValueChanged<String> onSelectWorkshop;
  final VoidCallback? onRegisterWorkshop;
  final ValueChanged<String>? onOpenDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Summary Node Pill
          _buildSummaryPill(),

          const SizedBox(height: 16),

          // 2. Tree Card Module
          _buildTreeCardModule(context),

          const SizedBox(height: 16),

          // 3. Inline Quick-Filter Chip Card
          _buildQuickFilterCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryPill() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PtTheme.deepGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.hub_rounded,
                color: PtTheme.deepGreen,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Grid Facilities',
                  style: PtTheme.font(
                    16,
                    lineHeight: 22,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                    tracking: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${workshops.where((w) => w.status == 'ACTIVE').length} operational nodes',
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
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: PtTheme.emerald,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x6610B981),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCardModule(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header eyebrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'FLEET INFRASTRUCTURE',
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                    tracking: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('btn-register-workshop-nav'),
                tooltip: Localizations.of<AppLocalizations>(context, AppLocalizations)?.registerWorkshop ??
                    'Register Workshop',
                icon: const Icon(
                  Icons.add_business_rounded,
                  size: 16,
                  color: PtTheme.deepGreen,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onRegisterWorkshop,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Level 0: Platform Hub
          Row(
            children: [
              const Icon(
                Icons.layers_outlined,
                size: 18,
                color: PtTheme.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Core Platform',
                  style: PtTheme.font(
                    14,
                    lineHeight: 22,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v4.2',
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w600,
                    color: PtTheme.muted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Branch Level 1 (with spine guide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical Spine Guide
              Container(
                width: 1.5,
                height: 310,
                margin: const EdgeInsets.only(left: 8, right: 14, top: 4),
                color: PtTheme.border,
              ),

              // Workshops Stack
              Expanded(
                child: Column(
                  children: [
                    for (int i = 0; i < workshops.length; i++) ...[
                      _buildWorkshopNode(context, workshops[i]),
                      if (i < workshops.length - 1) const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('btn-tree-register-workshop'),
                        onTap: onRegisterWorkshop,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: PtTheme.deepGreen.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: PtTheme.deepGreen.withValues(alpha: 0.25),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: PtTheme.deepGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Register New Workshop',
                                  style: PtTheme.font(
                                    12,
                                    lineHeight: 16,
                                    weight: FontWeight.w700,
                                    color: PtTheme.deepGreen,
                                  ),
                                ),
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

          const SizedBox(height: 20),

          // Bottom Metric Capsule: Assigned Bay Capacity
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ASSIGNED BAY CAPACITY',
                        style: PtTheme.font(
                          10,
                          lineHeight: 14,
                          weight: FontWeight.w700,
                          color: PtTheme.muted,
                          tracking: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '88%',
                      style: PtTheme.font(
                        13,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: const LinearProgressIndicator(
                    value: 0.88,
                    minHeight: 6,
                    backgroundColor: PtTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PtTheme.deepGreen,
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

  Widget _buildWorkshopNode(BuildContext context, HierarchyWorkshop workshop) {
    final isSelected = workshop.id == selectedWorkshopId;
    final isActive = workshop.status == 'ACTIVE';

    final Color statusColor;
    final Color statusBg;
    if (workshop.status == 'ACTIVE') {
      statusColor = PtTheme.deepGreen;
      statusBg = PtTheme.deepGreen.withValues(alpha: 0.10);
    } else {
      statusColor = PtTheme.muted;
      statusBg = PtTheme.canvas;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectWorkshop(workshop.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? PtTheme.deepGreen.withValues(alpha: 0.04)
                : PtTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? PtTheme.deepGreen : PtTheme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Dot + Name + Status Pill
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? PtTheme.emerald : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workshop.name,
                      style: PtTheme.font(
                        13,
                        lineHeight: 20,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      workshop.status,
                      style: PtTheme.font(
                        9,
                        lineHeight: 12,
                        weight: FontWeight.w700,
                        color: statusColor,
                        tracking: 0.4,
                      ),
                    ),
                  ),
                  if (onOpenDetails != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      key: Key('btn-tree-settings-${workshop.id}'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 15,
                        color: PtTheme.muted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      splashRadius: 12,
                      tooltip: Localizations.of<AppLocalizations>(context, AppLocalizations)?.detailsAndSettings ??
                          'Details & Settings',
                      onPressed: () => onOpenDetails?.call(workshop.id),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Metrics Row
              if (workshop.memberCount > 0)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 13,
                      color: PtTheme.muted,
                    ),
                    Text(
                      '${workshop.memberCount} Active Staff',
                      style: PtTheme.font(
                        11,
                        lineHeight: 16,
                        weight: FontWeight.w400,
                        color: PtTheme.muted,
                      ),
                    ),
                    const Text('•', style: TextStyle(color: PtTheme.muted, fontSize: 11)),
                    const Icon(
                      Icons.garage_outlined,
                      size: 13,
                      color: PtTheme.muted,
                    ),
                    Text(
                      '${workshop.bayCount} Bays',
                      style: PtTheme.font(
                        11,
                        lineHeight: 16,
                        weight: FontWeight.w400,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Offline Maintenance',
                  style: PtTheme.font(
                    11,
                    lineHeight: 16,
                    weight: FontWeight.w400,
                    color: PtTheme.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterCard() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: PtTheme.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filter Shift: Day Rotation',
              style: PtTheme.font(
                12,
                lineHeight: 18,
                weight: FontWeight.w500,
                color: PtTheme.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'CHANGE',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
