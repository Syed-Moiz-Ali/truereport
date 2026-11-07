import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

/// Workshop Admin shared components (F3-A screens 1–4).
/// Dev-only showcase; labels are gallery scaffolding, not product copy.
class WorkshopShowcase extends StatefulWidget {
  const WorkshopShowcase({super.key});

  @override
  State<WorkshopShowcase> createState() => _WorkshopShowcaseState();
}

class _WorkshopShowcaseState extends State<WorkshopShowcase> {
  String _tier = 'standard';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: [
        const GalleryTile(
          label: 'Header',
          child: WorkshopHeader(
            title: 'Live Job Queue',
            user: WorkshopUserChip(
              initials: 'DV',
              displayName: 'David Vance',
              workshopName: 'Workshop',
            ),
          ),
        ),
        const GalleryTile(
          label: 'Stat card',
          child: SizedBox(
            width: 300,
            child: WorkshopStatCard(
              value: '4',
              caption: 'Ready to finalize',
              icon: Icons.inbox_outlined,
              progress: 0.5,
            ),
          ),
        ),
        GalleryTile(
          label: 'Job card',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: WorkshopJobCard(
              title: 'Porsche 911 Carrera S',
              reference: 'JOB-5A0001',
              status: const StatusChip(
                label: 'In progress',
                tone: StatusTone.info,
              ),
              onTap: () {},
              onOpen: () {},
              openSemanticLabel: 'Open job',
            ),
          ),
        ),
        GalleryTile(
          label: 'Option cards',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WorkshopOptionCard<String>(
                  value: 'standard',
                  groupValue: _tier,
                  onChanged: (v) => setState(() => _tier = v),
                  title: 'Standard check',
                  caption: 'From template v3 · 110 checkpoints',
                ),
                SizedBox(height: context.spacing.sm),
                WorkshopOptionCard<String>(
                  value: 'full',
                  groupValue: _tier,
                  onChanged: (v) => setState(() => _tier = v),
                  title: 'Full inspection',
                  caption: 'From template v5 · 210 checkpoints',
                ),
              ],
            ),
          ),
        ),
        GalleryTile(
          label: 'Dialog',
          child: AppButton(
            label: 'Open dialog',
            onPressed: () => WorkshopDialog.show<void>(
              context,
              title: 'Assign technician',
              subtitle: 'Select an available technician',
              closeSemanticLabel: 'Close dialog',
              content: const Text('Dialog body'),
              actions: [AppButton(label: 'Confirm', onPressed: () {})],
            ),
          ),
        ),
        GalleryTile(
          label: 'Side sheet',
          child: AppButton(
            label: 'Open sheet',
            onPressed: () => WorkshopSideSheet.show<void>(
              context,
              title: 'Schedule new job',
              closeSemanticLabel: 'Close panel',
              body: const Text('Form'),
              footer: AppButton(label: 'Create', onPressed: () {}),
            ),
          ),
        ),
        const GalleryTile(
          label: 'Staff card',
          child: WorkshopStaffCard(
            displayName: 'David Vance',
            statusActive: true,
            roleLabel: 'Technician',
          ),
        ),
        const GalleryTile(
          label: 'Metric',
          child: SizedBox(
            width: 280,
            child: WorkshopMetric(
              value: '8',
              label: 'Active technicians',
              icon: Icons.groups_outlined,
            ),
          ),
        ),
        GalleryTile(
          label: 'Template card',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: WorkshopTemplateCard(
              title: 'Full inspection',
              versionLabel: 'v3 · 110 checkpoints',
              onTap: () {},
            ),
          ),
        ),
        GalleryTile(
          label: 'Sequence card',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: WorkshopSequenceCard(
              indexLabel: '01',
              title: 'Check Brakes',
              onTap: () {},
            ),
          ),
        ),
        GalleryTile(
          label: 'Drop zone + locked pill',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkshopDropZone(label: 'Drop checkpoint here', onTap: () {}),
              SizedBox(height: context.spacing.sm),
              const WorkshopLockedPill(label: 'Required by platform'),
            ],
          ),
        ),
      ],
    );
  }
}
