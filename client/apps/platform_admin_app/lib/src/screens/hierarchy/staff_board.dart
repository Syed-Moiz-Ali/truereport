import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class StaffBoard extends ConsumerWidget {
  const StaffBoard({
    super.key,
    required this.workshop,
    this.onAddStaff,
    this.onRegisterWorkshop,
    this.onOpenDetails,
  });

  final HierarchyWorkshop workshop;
  final VoidCallback? onAddStaff;
  final VoidCallback? onRegisterWorkshop;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(staffSearchQueryProvider);
    final selectedFilter = ref.watch(staffRoleFilterProvider);

    // Filter staff according to search query and role filter
    final allStaff = workshop.technicians.isNotEmpty
        ? workshop.technicians
        : sampleWorkshopAStaff;

    final filteredStaff = allStaff.where((staff) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final match = staff.displayName.toLowerCase().contains(query) ||
            staff.role.toLowerCase().contains(query) ||
            (staff.bayAssignment?.toLowerCase().contains(query) ?? false) ||
            (staff.certifications?.toLowerCase().contains(query) ?? false);
        if (!match) return false;
      }

      if (selectedFilter == 'Diagnostics') {
        return staff.role.toLowerCase().contains('diag') ||
            (staff.bayAssignment?.toLowerCase().contains('diag') ?? false);
      } else if (selectedFilter == 'Inspectors') {
        return staff.role.toLowerCase().contains('inspect');
      } else if (selectedFilter == 'Supervisors') {
        return staff.role.toLowerCase().contains('supervis') ||
            staff.role.toLowerCase().contains('lead');
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Large Pure White Card with Expansive Soft Shadow
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PtTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header & Call to Action
              _buildHeader(context),

              const SizedBox(height: 24),

              // Staff Search & Tag Filters Row
              _buildFilterRow(context, ref, selectedFilter),

              const SizedBox(height: 20),

              // Staff Profiles Stack
              Column(
                children: [
                  for (final staff in filteredStaff) ...[
                    _StaffProfileCard(staff: staff),
                    const SizedBox(height: 12),
                  ],
                  if (filteredStaff.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No personnel found matching filters.',
                          style: PtTheme.font(
                            14,
                            lineHeight: 20,
                            weight: FontWeight.w400,
                            color: PtTheme.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Card Pagination & Clean Footnote
              _buildPagination(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Secondary Floating Utility Strip: Equipment & Bay Quick Metrics
        _buildUtilityStrip(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${workshop.name} Staff',
                      style: PtTheme.font(
                        22,
                        lineHeight: 28,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                        tracking: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PtTheme.deepGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${workshop.memberCount} Active',
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w700,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bay operations, master diagnostics, and field inspection clearance',
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
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (onOpenDetails != null)
              OutlinedButton.icon(
                key: const Key('btn-workshop-settings'),
                onPressed: onOpenDetails,
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: PtTheme.deepGreen,
                ),
                label: Text(
                  'Settings & Details',
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w700,
                    color: PtTheme.deepGreen,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: PtTheme.deepGreen, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            OutlinedButton.icon(
              key: const Key('btn-register-workshop'),
              onPressed: onRegisterWorkshop,
              icon: const Icon(
                Icons.add_business_rounded,
                size: 18,
                color: PtTheme.deepGreen,
              ),
              label: Text(
                'Register Workshop',
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PtTheme.deepGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('btn-add-staff'),
              onPressed: onAddStaff,
              icon: const Icon(Icons.person_add_alt_1, size: 18, color: PtTheme.white),
              label: Text(
                'Add Staff',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _buildFilterRow(
    BuildContext context,
    WidgetRef ref,
    String selectedFilter,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search Input
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PtTheme.border),
            ),
            child: TextField(
              onChanged: (val) =>
                  ref.read(staffSearchQueryProvider.notifier).setQuery(val),
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w400,
                color: PtTheme.ink,
              ),
              decoration: InputDecoration(
                hintText: 'Search staff by name, license ID, or bay role...',
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
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
        ),

        // Tag Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tag in ['All', 'Diagnostics', 'Inspectors', 'Supervisors']) ...[
                _buildTagChip(
                  tag == 'All' ? 'All (${workshop.memberCount})' : tag,
                  isSelected: selectedFilter == tag,
                  onTap: () =>
                      ref.read(staffRoleFilterProvider.notifier).setFilter(tag),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? PtTheme.ink : PtTheme.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? PtTheme.ink : PtTheme.border,
            ),
          ),
          child: Text(
            label,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? PtTheme.white : PtTheme.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        Text(
          'Showing 4 of ${workshop.memberCount} registered personnel in ${workshop.name}',
          style: PtTheme.font(
            12,
            lineHeight: 18,
            weight: FontWeight.w400,
            color: PtTheme.muted,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {},
            ),
            const SizedBox(width: 4),
            _buildPageButton(
              text: '1',
              isActive: true,
              onTap: () {},
            ),
            const SizedBox(width: 4),
            _buildPageButton(
              text: '2',
              onTap: () {},
            ),
            const SizedBox(width: 4),
            _buildPageButton(
              text: '3',
              onTap: () {},
            ),
            const SizedBox(width: 4),
            _buildPageButton(
              icon: Icons.chevron_right_rounded,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageButton({
    String? text,
    IconData? icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? PtTheme.deepGreen : PtTheme.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? PtTheme.deepGreen : PtTheme.border,
            ),
          ),
          child: Center(
            child: text != null
                ? Text(
                    text,
                    style: PtTheme.font(
                      12,
                      lineHeight: 16,
                      weight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? PtTheme.white : PtTheme.ink,
                    ),
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: PtTheme.muted,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityStrip() {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            eyebrow: 'LIVE UTILIZATION',
            metric: '94.2%',
            badge: '+3.1%',
            badgeColor: PtTheme.emerald,
            footnote: 'Peak technician density',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            eyebrow: 'AVG INSPECTION TIME',
            metric: '18.4m',
            badge: '-2.2m',
            badgeColor: PtTheme.emerald,
            footnote: 'Per 48-point protocol',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            eyebrow: 'PASS RATE VELOCITY',
            metric: '99.1%',
            badge: 'Standard',
            badgeColor: PtTheme.muted,
            footnote: 'Audit compliance score',
          ),
        ),
      ],
    );
  }
}

class _StaffProfileCard extends StatelessWidget {
  const _StaffProfileCard({required this.staff});

  final PlatformAccount staff;

  @override
  Widget build(BuildContext context) {
    // Generate initials
    final initials = staff.displayName
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 450;
        if (isCompact) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PtTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PtTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(initials),
                    const SizedBox(width: 14),
                    Expanded(child: _buildNameAndRole()),
                    _buildActionButtons(),
                  ],
                ),
                if (staff.certifications != null) ...[
                  const SizedBox(height: 12),
                  _buildCertifications(),
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            children: [
              _buildAvatar(initials),
              const SizedBox(width: 16),
              Expanded(child: _buildNameAndRole()),
              if (staff.certifications != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCertifications(),
                ),
              ],
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String initials) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: PtTheme.deepGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
          ),
          child: Center(
            child: Text(
              initials,
              style: PtTheme.font(
                16,
                lineHeight: 22,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: PtTheme.emerald,
              shape: BoxShape.circle,
              border: Border.all(color: PtTheme.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              staff.displayName,
              style: PtTheme.font(
                15,
                lineHeight: 20,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            if (staff.bayAssignment != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PtTheme.border),
                ),
                child: Text(
                  staff.bayAssignment!,
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
        const SizedBox(height: 4),
        Text(
          staff.role,
          style: PtTheme.font(
            13,
            lineHeight: 18,
            weight: FontWeight.w400,
            color: PtTheme.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildCertifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CERTIFICATIONS',
          style: PtTheme.font(
            10,
            lineHeight: 14,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          staff.certifications!,
          style: PtTheme.font(
            13,
            lineHeight: 18,
            weight: FontWeight.w600,
            color: PtTheme.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: PtTheme.muted,
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
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
              Icons.more_vert_rounded,
              size: 16,
              color: PtTheme.muted,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.eyebrow,
    required this.metric,
    required this.badge,
    required this.badgeColor,
    required this.footnote,
  });

  final String eyebrow;
  final String metric;
  final String badge;
  final Color badgeColor;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: PtTheme.font(
              10,
              lineHeight: 14,
              weight: FontWeight.w700,
              color: PtTheme.muted,
              tracking: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                metric,
                style: PtTheme.font(
                  22,
                  lineHeight: 28,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              Text(
                badge,
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            footnote,
            style: PtTheme.font(
              11,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}
