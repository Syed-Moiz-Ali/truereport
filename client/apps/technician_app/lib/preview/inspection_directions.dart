// THROWAWAY direction previews. Deleted after approval.
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'inspection_kit.dart';

class InspectionJob {
  const InspectionJob({
    required this.plate,
    required this.vehicle,
    required this.customer,
    required this.done,
    required this.total,
  });

  final String plate;
  final String vehicle;
  final String customer;
  final int done;
  final int total;
}

const job = InspectionJob(
  plate: 'D-48213',
  vehicle: 'Toyota Land Cruiser 2023',
  customer: 'Ahmed Al Mansoori',
  done: 18,
  total: 30,
);

const sections = [
  ('Body', '8', 6, 'body'),
  ('Engine bay', '4', 4, 'engine'),
  ('Brakes', '4', 0, 'brakes'),
  ('Tyres', '4', 0, 'tyres'),
  ('Cabin', '10', 4, 'cabin'),
];

const items = [
  ('Front brake pads', 'Defect · Major', StatusTone.danger),
  ('Brake discs', 'Not checked', StatusTone.neutral),
  ('Brake fluid', 'No issue', StatusTone.success),
  ('Caliper seals', 'No issue', StatusTone.success),
  ('Brake hoses', 'Not checked', StatusTone.neutral),
  ('Pad wear sensor', 'No issue', StatusTone.success),
];

const routeItems = [
  ('Front brake pads', 'Defect · Major', StatusTone.danger),
  ('Brake discs', 'Not checked', StatusTone.neutral),
  ('Brake fluid', 'No issue', StatusTone.success),
];

class DeckPreview extends StatelessWidget {
  const DeckPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewShell(
      direction: iT(context, 'A · Inspection deck', 'أ · بطاقة الفحص'),
      signature: iT(
        context,
        'One item at a time: the card carries the standard, result, severity, evidence and the next step.',
        'عنصر واحد في كل مرة: البطاقة تحمل المعيار والنتيجة والخطورة والأدلة والخطوة التالية.',
      ),
      children: const [StyleTile(), _DeckSection()],
    );
  }
}

class _DeckSection extends StatelessWidget {
  const _DeckSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        const card = _DeckCard();
        if (!wide) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _JobStrip(),
              SizedBox(height: 12),
              _SectionChips(scroll: true),
              SizedBox(height: 12),
              card,
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _JobStrip(),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 180, child: _DeckRail()),
                    SizedBox(width: 24),
                    Expanded(child: card),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JobStrip extends StatelessWidget {
  const _JobStrip();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back_rounded),
          color: colors.onSurface,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.vehicle,
                maxLines: 1,
                style: iText(context, 16, weight: FontWeight.w700, height: 21),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  IPlate(job.plate),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      job.customer,
                      maxLines: 1,
                      style: iMeta(context, color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${job.done} / ${job.total}',
          style: iText(
            context,
            12.5,
            weight: FontWeight.w700,
            height: 16,
            tabular: true,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionChips extends StatelessWidget {
  const _SectionChips({this.scroll = false});

  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final chips = [
      IChip(label: iT(context, 'Body 6/8', 'الهيكل 6/8'), selected: false),
      IChip(label: iT(context, 'Engine 4/4', 'المحرك 4/4'), selected: false),
      IChip(label: iT(context, 'Brakes 0/4', 'الفرامل 0/4'), selected: true),
      IChip(label: iT(context, 'Tyres 0/4', 'الإطارات 0/4'), selected: false),
      IChip(label: iT(context, 'Cabin 4/10', 'المقصورة 4/10'), selected: false),
    ];
    if (!scroll) {
      return Wrap(spacing: 8, runSpacing: 8, children: chips);
    }
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => chips[index],
      ),
    );
  }
}

class _DeckRail extends StatelessWidget {
  const _DeckRail();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(iT(context, 'SECTIONS', 'الأقسام'), style: iEyebrow(context)),
        const SizedBox(height: 8),
        for (final section in sections)
          Container(
            height: 44,
            margin: const EdgeInsetsDirectional.only(bottom: 2),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: section.$4 == 'brakes'
                  ? context.brand.container
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _sectionIcon(section.$4),
                  size: 16,
                  color: section.$4 == 'brakes'
                      ? context.brand.onContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    iT(context, section.$1, _arSection(section.$1)),
                    maxLines: 1,
                    style: iText(
                      context,
                      13,
                      weight: section.$4 == 'brakes'
                          ? FontWeight.w700
                          : FontWeight.w500,
                      height: 17,
                      color: section.$4 == 'brakes'
                          ? context.brand.onContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${section.$3}/${section.$2}',
                  style: iText(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    height: 15,
                    tabular: true,
                    color: section.$4 == 'brakes'
                        ? context.brand.onContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(iT(context, 'UP NEXT', 'التالي'), style: iEyebrow(context)),
        const SizedBox(height: 8),
        Text(
          iT(context, 'Brake discs', 'أقراص الفرامل'),
          style: iBody(context),
        ),
        Text(
          iT(context, 'Wheel bearings', 'رمان البلي'),
          style: iMeta(context, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(IRadii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iT(context, 'FRONT BRAKE PADS', 'فحمات الفرامل الأمامية'),
                      style: iEyebrow(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      iT(
                        context,
                        'Check pad thickness on both sides.',
                        'افحص سماكة الفحمات على الجانبين.',
                      ),
                      style: iBody(context),
                    ),
                  ],
                ),
              ),
              IChip(
                label: iT(context, 'Safety', 'سلامة'),
                tone: StatusTone.danger,
                icon: Icons.health_and_safety_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  iT(
                    context,
                    'Minimum 3 mm · replace below limit',
                    'الحد الأدنى 3 مم · يُستبدل تحت الحد',
                  ),
                  style: iMeta(context, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const IResultSelector(selected: 'defect'),
          const SizedBox(height: 14),
          Text(iT(context, 'SEVERITY', 'الخطورة'), style: iEyebrow(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IChip(label: iT(context, 'Minor', 'طفيف')),
              IChip(label: iT(context, 'Moderate', 'متوسط')),
              IChip(
                label: iT(context, 'Major', 'جسيم'),
                tone: StatusTone.warning,
                selected: false,
              ),
              IChip(
                label: iT(context, 'Safety critical', 'حرج للسلامة'),
                tone: StatusTone.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(iT(context, 'EVIDENCE', 'الأدلة'), style: iEyebrow(context)),
          const SizedBox(height: 8),
          const IEvidenceGrid(),
          const SizedBox(height: 14),
          Container(
            height: 46,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            alignment: AlignmentDirectional.centerStart,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              iT(context, 'Add a note…', 'أضف ملاحظة…'),
              style: iBody(context, color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          IButton(
            label: iT(context, 'Save & next', 'حفظ والتالي'),
            icon: Icons.arrow_forward_rounded,
            expand: true,
          ),
        ],
      ),
    );
  }
}

IconData _sectionIcon(String code) => switch (code) {
  'body' => Icons.directions_car_outlined,
  'engine' => Icons.settings_outlined,
  'brakes' => Icons.disc_full_outlined,
  'tyres' => Icons.trip_origin_rounded,
  _ => Icons.airline_seat_recline_normal_rounded,
};

String _arSection(String en) => switch (en) {
  'Body' => 'الهيكل',
  'Engine bay' => 'حجرة المحرك',
  'Brakes' => 'الفرامل',
  'Tyres' => 'الإطارات',
  _ => 'المقصورة',
};

// ---------------------------------------------------------------------------
// B — Inspector sheet
// ---------------------------------------------------------------------------
class SheetPreview extends StatelessWidget {
  const SheetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewShell(
      direction: iT(context, 'B · Inspector sheet', 'ب · لوحة الفحص'),
      signature: iT(
        context,
        'The queue stays visible; the assessment rises as a sheet, so context survives every item.',
        'يبقى الطابور ظاهراً؛ يصعد التقييم كلوحة، فيبقى السياق مع كل عنصر.',
      ),
      children: const [StyleTile(), _SheetSection()],
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        if (wide) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Workspace()),
                  SizedBox(width: 20),
                  SizedBox(width: 360, child: _InspectorPanel()),
                ],
              ),
            ),
          );
        }
        final colors = context.colors;
        return SizedBox(
          height: 900,
          child: Stack(
            children: [
              const Positioned.fill(child: _Workspace(dimmed: true)),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: colors.onSurface.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(IRadii.sheet),
                    ),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 18),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GrabBar(),
                      SizedBox(height: 8),
                      _InspectorBody(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({this.dimmed = false});

  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(IRadii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: context.brand.container.withValues(alpha: 0.5),
            padding: const EdgeInsetsDirectional.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.vehicle,
                        style: iText(
                          context,
                          17,
                          weight: FontWeight.w700,
                          height: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IPlate(job.plate),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              job.customer,
                              style: iMeta(
                                context,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IRing(value: job.done, total: job.total, size: 62),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  iT(context, 'SECTIONS', 'الأقسام'),
                  style: iEyebrow(context),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IChip(label: iT(context, 'Body 6/8', 'الهيكل 6/8')),
                    IChip(label: iT(context, 'Engine 4/4', 'المحرك 4/4')),
                    IChip(
                      label: iT(context, 'Brakes 0/4', 'الفرامل 0/4'),
                      selected: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  iT(context, 'ITEMS · BRAKES', 'العناصر · الفرامل'),
                  style: iEyebrow(context),
                ),
                const SizedBox(height: 4),
                for (final item in items)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            iT(context, item.$1, _arItem(item.$1)),
                            style: iBody(context),
                          ),
                        ),
                        IChip(
                          label: iT(context, item.$2, _arStatus(item.$2)),
                          tone: item.$3,
                        ),
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
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(IRadii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: const _InspectorBody(),
    );
  }
}

class _GrabBar extends StatelessWidget {
  const _GrabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: context.colors.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _InspectorBody extends StatelessWidget {
  const _InspectorBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    iT(context, 'FRONT BRAKE PADS', 'فحمات الفرامل الأمامية'),
                    style: iEyebrow(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    iT(context, 'Minimum 3 mm', 'الحد الأدنى 3 مم'),
                    style: iMeta(context, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IChip(
              label: iT(context, 'Safety', 'سلامة'),
              tone: StatusTone.danger,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const IResultSelector(selected: 'defect'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            IChip(label: iT(context, 'Minor', 'طفيف')),
            IChip(label: iT(context, 'Moderate', 'متوسط')),
            IChip(
              label: iT(context, 'Major', 'جسيم'),
              tone: StatusTone.warning,
            ),
            IChip(
              label: iT(context, 'Safety critical', 'حرج للسلامة'),
              tone: StatusTone.danger,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const IEvidenceGrid(),
        const SizedBox(height: 12),
        IButton(
          label: iT(context, 'Save & next', 'حفظ والتالي'),
          icon: Icons.arrow_forward_rounded,
          expand: true,
        ),
      ],
    );
  }
}

String _arItem(String en) => switch (en) {
  'Bonnet & latches' => 'غطاء المحرك والمزاليج',
  'Front bumper & grille' => 'المصد الأمامي والشبك',
  'Headlights & indicators' => 'المصابيح والمؤشرات',
  'Windscreen & wipers' => 'الزجاج الأمامي والمساحات',
  'Mirrors & glass' => 'المرايا والزجاج',
  'Brake discs' => 'أقراص الفرامل',
  'Brake fluid' => 'سائل الفرامل',
  'Caliper seals' => 'أختام الملاقط',
  'Brake hoses' => 'خراطيم الفرامل',
  'Pad wear sensor' => 'حساس تآكل الفحمات',
  _ => 'فحمات الفرامل الأمامية',
};

String _arStatus(String en) => switch (en) {
  'No issue' => 'سليم',
  'Defect · Major' => 'عيب · جسيم',
  'Not checked' => 'لم يُفحص',
  _ => en,
};

// ---------------------------------------------------------------------------
// C — Inspection route
// ---------------------------------------------------------------------------
class RoutePreview extends StatelessWidget {
  const RoutePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewShell(
      direction: iT(context, 'C · Inspection route', 'ج · مسار الفحص'),
      signature: iT(
        context,
        'The whole inspection is a route: stops grouped by section, the current stop open in place.',
        'الفحص كله مسار: محطات مجمعة حسب القسم، والمحطة الحالية مفتوحة في مكانها.',
      ),
      children: const [StyleTile(), _RouteSection()],
    );
  }
}

class _RouteSection extends StatelessWidget {
  const _RouteSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        if (!wide) {
          return const _RouteList(expanded: true);
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _RouteList(expanded: false)),
                SizedBox(width: 20),
                SizedBox(width: 360, child: _RouteDetail()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(IRadii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var s = 0; s < sections.length; s++) ...[
            Container(
              color: sections[s].$4 == 'brakes'
                  ? context.brand.container.withValues(alpha: 0.35)
                  : colors.surface,
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sections[s].$3 == int.parse(sections[s].$2)
                          ? context.statusColors.success.foreground
                          : sections[s].$4 == 'brakes'
                          ? context.brand.ink
                          : colors.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      iT(
                        context,
                        sections[s].$1,
                        _arSection(sections[s].$1),
                      ).toUpperCase(),
                      style: iEyebrow(context),
                    ),
                  ),
                  Text(
                    '${sections[s].$3}/${sections[s].$2}',
                    style: iMeta(context, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (sections[s].$4 == 'brakes')
              for (var i = 0; i < 3; i++) ...[
                _RouteStop(
                  label: iT(
                    context,
                    routeItems[i].$1,
                    _arItem(routeItems[i].$1),
                  ),
                  status: iT(
                    context,
                    routeItems[i].$2,
                    _arStatus(routeItems[i].$2),
                  ),
                  tone: routeItems[i].$3,
                  open: i == 0 && expanded,
                ),
                if (i == 0 && expanded)
                  const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
                    child: _RouteInlineItem(),
                  ),
              ]
            else
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(22, 6, 14, 10),
                child: Text(
                  iT(context, 'Tap to open the section', 'افتح القسم للاطلاع'),
                  style: iMeta(context, color: colors.onSurfaceVariant),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.status,
    required this.tone,
    required this.open,
  });

  final String label;
  final String status;
  final StatusTone tone;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
      child: Row(
        children: [
          Icon(
            open
                ? Icons.keyboard_arrow_down_rounded
                : Icons.chevron_right_rounded,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: iText(
                context,
                13.5,
                weight: open ? FontWeight.w700 : FontWeight.w500,
                height: 18,
              ),
            ),
          ),
          IChip(label: status, tone: tone),
        ],
      ),
    );
  }
}

class _RouteInlineItem extends StatelessWidget {
  const _RouteInlineItem();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          iT(context, 'Minimum 3 mm', 'الحد الأدنى 3 مم'),
          style: iMeta(context, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        const IResultSelector(selected: 'defect'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            IChip(label: iT(context, 'Minor', 'طفيف')),
            IChip(label: iT(context, 'Moderate', 'متوسط')),
            IChip(
              label: iT(context, 'Major', 'جسيم'),
              tone: StatusTone.warning,
            ),
            IChip(
              label: iT(context, 'Safety critical', 'حرج للسلامة'),
              tone: StatusTone.danger,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const IEvidenceGrid(),
        const SizedBox(height: 10),
        IButton(label: iT(context, 'Save item', 'حفظ العنصر'), expand: true),
      ],
    );
  }
}

class _RouteDetail extends StatelessWidget {
  const _RouteDetail();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(IRadii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: context.brand.container,
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  iT(context, 'CURRENT STOP', 'المحطة الحالية'),
                  style: iEyebrow(context, color: context.brand.onContainer),
                ),
                const SizedBox(height: 6),
                Text(
                  iT(context, 'Front brake pads', 'فحمات الفرامل الأمامية'),
                  style: iText(
                    context,
                    18,
                    weight: FontWeight.w700,
                    height: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  iT(context, 'Minimum 3 mm', 'الحد الأدنى 3 مم'),
                  style: iMeta(context, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const IResultSelector(selected: 'defect'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IChip(label: iT(context, 'Minor', 'طفيف')),
                    IChip(label: iT(context, 'Moderate', 'متوسط')),
                    IChip(
                      label: iT(context, 'Major', 'جسيم'),
                      tone: StatusTone.warning,
                    ),
                    IChip(
                      label: iT(context, 'Safety critical', 'حرج للسلامة'),
                      tone: StatusTone.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const IEvidenceGrid(),
                const SizedBox(height: 14),
                IButton(
                  label: iT(context, 'Save & next', 'حفظ والتالي'),
                  icon: Icons.arrow_forward_rounded,
                  expand: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
