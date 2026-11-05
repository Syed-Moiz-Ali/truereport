import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

class NavigationShowcase extends StatefulWidget {
  const NavigationShowcase({super.key});

  @override
  State<NavigationShowcase> createState() => _NavigationShowcaseState();
}

class _NavigationShowcaseState extends State<NavigationShowcase> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavDock(
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      items: const [
        AppBottomNavItem(
          label: 'Jobs',
          icon: Icons.work_outline,
          selectedIcon: Icons.work,
        ),
        AppBottomNavItem(
          label: 'Inspect',
          icon: Icons.checklist_outlined,
          selectedIcon: Icons.checklist,
        ),
        AppBottomNavItem(
          label: 'Sync',
          icon: Icons.cloud_outlined,
          selectedIcon: Icons.cloud,
        ),
        AppBottomNavItem(
          label: 'Profile',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
        ),
      ],
    );
  }
}

class AdminChromeShowcase extends StatelessWidget {
  const AdminChromeShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GalleryTile(
          label: 'Top bar',
          child: AdminTopBar(title: 'TrueReport Admin'),
        ),
        SizedBox(height: context.spacing.md),
        GalleryTile(
          label: 'Sidebar',
          child: SizedBox(
            height: context.spacing.massive * 5,
            child: AdminSidebar(
              brand: Text('TrueReport', style: context.texts.titleLarge),
              items: [
                AdminNavItem(
                  label: 'Overview',
                  icon: Icons.space_dashboard_outlined,
                  selected: true,
                  onTap: () {},
                ),
                AdminNavItem(
                  label: 'Jobs',
                  icon: Icons.work_outline,
                  selected: false,
                  onTap: () {},
                ),
                AdminNavItem(
                  label: 'Audit',
                  icon: Icons.history,
                  selected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.spacing.md),
        GalleryTile(
          label: 'AdminShell',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              height: context.spacing.massive * 6,
              child: AdminShell(
                title: 'TrueReport Admin',
                brand: Text('TrueReport', style: context.texts.titleLarge),
                items: [
                  AdminNavItem(
                    label: 'Overview',
                    icon: Icons.space_dashboard_outlined,
                    selected: true,
                    onTap: () {},
                  ),
                  AdminNavItem(
                    label: 'Jobs',
                    icon: Icons.work_outline,
                    selected: false,
                    onTap: () {},
                  ),
                  AdminNavItem(
                    label: 'Audit',
                    icon: Icons.history,
                    selected: false,
                    onTap: () {},
                  ),
                ],
                child: Text(
                  'Admin content area',
                  style: context.texts.bodyMedium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StatesShowcase extends StatelessWidget {
  const StatesShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        GalleryTile(
          label: 'Empty',
          width: 320,
          child: EmptyState(
            title: 'No jobs yet',
            body: 'Assign a job to start an inspection.',
            action: AppButton(
              label: 'Refresh',
              onPressed: () {},
              variant: AppButtonVariant.tonal,
            ),
          ),
        ),
        GalleryTile(
          label: 'Error',
          width: 320,
          child: ErrorState(
            title: 'Could not load jobs',
            body: 'Check your connection and try again.',
            retryLabel: 'Retry',
            onRetry: () {},
          ),
        ),
        const GalleryTile(
          label: 'Offline',
          width: 320,
          child: OfflineBanner(
            message: 'Offline. Changes are saved on this device.',
          ),
        ),
        const GalleryTile(
          label: 'Skeleton',
          width: 320,
          child: LoadingSkeleton(lines: 4),
        ),
      ],
    );
  }
}

class OverlaysShowcase extends StatelessWidget {
  const OverlaysShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        GalleryTile(
          label: 'Confirmation dialog',
          child: AppButton(
            label: 'Open dialog',
            onPressed: () => showAppConfirmDialog(
              context,
              title: 'Finalize inspection?',
              message: 'Finalized findings cannot be edited by anyone.',
              confirmLabel: 'Finalize',
              destructive: true,
            ),
          ),
        ),
        GalleryTile(
          label: 'Bottom sheet',
          child: AppButton(
            label: 'Open sheet',
            onPressed: () =>
                showAppBottomSheet(context, child: const _SheetSample()),
          ),
        ),
      ],
    );
  }
}

class _SheetSample extends StatelessWidget {
  const _SheetSample();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Share report link', style: context.texts.titleLarge),
        SizedBox(height: context.spacing.sm),
        Text(
          'Copies cannot be recalled after sharing.',
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.lg),
        AppButton(
          label: l10n.create,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class DataTableShowcase extends StatelessWidget {
  const DataTableShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <_GalleryJob>[
      const _GalleryJob(
        id: 'TR-1042',
        vehicle: 'Toyota Hilux',
        status: 'In progress',
        tone: StatusTone.info,
      ),
      const _GalleryJob(
        id: 'TR-1043',
        vehicle: 'Nissan Patrol',
        status: 'Finalized',
        tone: StatusTone.success,
      ),
      const _GalleryJob(
        id: 'TR-1044',
        vehicle: 'Ford Ranger',
        status: 'Offline',
        tone: StatusTone.warning,
      ),
    ];
    return AppDataTable<_GalleryJob>(
      columns: [
        AppDataColumn<_GalleryJob>(
          label: 'Job',
          cellBuilder: (context, row, index) => Text(row.id),
        ),
        AppDataColumn<_GalleryJob>(
          label: 'Vehicle',
          cellBuilder: (context, row, index) => Text(row.vehicle),
        ),
        AppDataColumn<_GalleryJob>(
          label: 'Status',
          cellBuilder: (context, row, index) =>
              StatusChip(label: row.status, tone: row.tone),
        ),
      ],
      rows: rows,
    );
  }
}

class _GalleryJob {
  const _GalleryJob({
    required this.id,
    required this.vehicle,
    required this.status,
    required this.tone,
  });

  final String id;
  final String vehicle;
  final String status;
  final StatusTone tone;
}

class TreeViewShowcase extends StatelessWidget {
  const TreeViewShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTreeView<String>(
      initiallyExpanded: const {'platform', 'workshop-a'},
      onSelected: (_) {},
      roots: [
        const AppTreeNode<String>(
          data: 'platform',
          label: 'Platform',
          icon: Icons.public,
          children: [
            AppTreeNode<String>(
              data: 'workshop-a',
              label: 'Workshop A',
              icon: Icons.storefront_outlined,
              children: [
                AppTreeNode<String>(
                  data: 'tech-1',
                  label: 'Technician 1',
                  icon: Icons.person_outline,
                ),
                AppTreeNode<String>(
                  data: 'tech-2',
                  label: 'Technician 2',
                  icon: Icons.person_outline,
                ),
              ],
            ),
            AppTreeNode<String>(
              data: 'workshop-b',
              label: 'Workshop B',
              icon: Icons.storefront_outlined,
            ),
          ],
        ),
      ],
    );
  }
}
