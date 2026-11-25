import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'preview_data.dart';

/// Direction A — FOCUS.
///
/// The job is a session, not a list: one car on the ramp, one item filling the
/// screen, one 30-tick spine that always answers "where am I and how much is
/// left", and a bottom dock that answers "what do I do next" with one tap.
///
/// Throwaway preview: sample data comes from `preview_data.dart`, nothing here
/// is wired to a provider, a route or the production screens.
class DirectionA extends StatelessWidget {
  const DirectionA({required this.screen, super.key});

  final PreviewScreen screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: switch (screen) {
        PreviewScreen.queue => const _QueueScreen(),
        PreviewScreen.job => const _JobScreen(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

/// `design_system` ships 12/16px control radii and a 48px sheet radius; the
/// jobs work already uses 14 for controls and 24 for sheets (see
/// `features/jobs/queue/jobs_queue_style.dart`). Mirror that family here so the
/// preview does not introduce a third radius scale — 16px cards come from
/// `context.radii.xl`, pills from `context.radii.pill`.
const double _controlRadius = 14;
const double _sheetRadius = 24;

// ---------------------------------------------------------------------------
// Type
// ---------------------------------------------------------------------------

const List<FontFeature> _tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

TextStyle _type(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w400,
  double height = 1.45,
  Color? color,
  double tracking = 0,
  bool tabular = false,
}) {
  return (context.texts.bodyMedium ?? const TextStyle()).copyWith(
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color ?? context.colors.onSurface,
    fontFeatures: tabular ? _tabularFigures : null,
  );
}

TextStyle _eyebrow(BuildContext context, {Color? color}) => _type(
  context,
  11.5,
  weight: FontWeight.w700,
  height: 15,
  tracking: 0.7,
  color: color ?? context.colors.onSurfaceVariant,
);

// ---------------------------------------------------------------------------
// Sample data helpers
// ---------------------------------------------------------------------------

final List<PreviewItem> _allItems = <PreviewItem>[
  for (final PreviewSection section in previewSections) ...section.items,
];

/// The per-item truth used by every spine and every count, so progress can
/// never disagree with the ticks beside it.
final Map<int, String> _initialResults = <int, String>{
  for (final PreviewItem item in _allItems)
    if (item.result != null) item.number: item.result!,
};

final int _safetyCount = _allItems
    .where((PreviewItem item) => item.safety)
    .length;

PreviewSection _sectionForItem(int number) => previewSections.firstWhere(
  (PreviewSection section) =>
      section.items.any((PreviewItem item) => item.number == number),
);

int _sectionNumberFor(PreviewSection section) =>
    previewSections.indexOf(section) + 1;

String _shortSectionName(String name) => switch (name) {
  'Suspension, Steering & Underbody' => 'Suspension',
  'Braking Systems & Tyres' => 'Brakes & tyres',
  'Electrical, Battery & Diagnostics' => 'Electrical',
  'Body, Glass & Interior' => 'Body & interior',
  'Road Test & Dynamic Performance' => 'Road test',
  'Powertrain & Mechanical' => 'Powertrain',
  _ => name,
};

String _itemsLabel(int done, int total) => '$done of $total items';

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _Hairline extends StatelessWidget {
  const _Hairline({this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: SizedBox(
        width: double.infinity,
        height: 1,
        child: ColoredBox(color: context.colors.outlineVariant),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.plate, this.onTint = false, this.small = false});

  final String plate;

  /// True on the brand-tinted ramp surface.
  final bool onTint;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.brand.ink;
    final Color background = onTint
        ? context.colors.surface
        : context.colors.surfaceContainerLow;
    final Color border = onTint
        ? ink.withValues(alpha: 0.18)
        : context.colors.outlineVariant;
    final Color foreground = onTint ? ink : context.colors.onSurface;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.radii.sm),
        border: Border.all(color: border),
      ),
      child: Text(
        plate,
        textDirection: TextDirection.ltr,
        style: _type(
          context,
          small ? 11 : 12.5,
          weight: FontWeight.w700,
          height: small ? 15 : 17,
          tracking: 0.7,
          tabular: true,
          color: foreground,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: context.colors.surface,
          shape: CircleBorder(
            side: BorderSide(color: context.colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 20, color: context.colors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color onInk = context.colors.onPrimary;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Material(
          color: context.brand.ink,
          borderRadius: BorderRadius.circular(_controlRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(
                          context,
                          15.5,
                          weight: FontWeight.w700,
                          height: 20,
                          tracking: -0.1,
                          color: onInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: onInk),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip();

  @override
  Widget build(BuildContext context) {
    final StatusColorPair pair = context.statusColors.forTone(
      StatusTone.warning,
    );
    return Semantics(
      label:
          'Offline. Work is saved on this phone and syncs when you reconnect.',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: pair.background,
            borderRadius: BorderRadius.circular(context.radii.pill),
            border: Border.all(color: pair.foreground.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.cloud_off_outlined, size: 13, color: pair.foreground),
              const SizedBox(width: 6),
              Text(
                'Offline',
                style: _type(
                  context,
                  11.5,
                  weight: FontWeight.w700,
                  height: 14,
                  color: pair.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The signature: one tick per item, for the whole job.
///
/// Done ticks are brand ink, the current tick is tall, the remaining ticks are
/// a hairline of ink, and safety-critical items carry a dot beneath the tick.
/// Status is never colour alone (height plus dot), and the whole strip is one
/// semantic control instead of thirty noisy nodes.
class _TickSpine extends StatelessWidget {
  const _TickSpine({
    required this.results,
    required this.current,
    this.interactive = false,
    this.onJump,
    this.showAdvisory = true,
  });

  final Map<int, String> results;
  final int current;
  final bool interactive;
  final ValueChanged<int>? onJump;

  /// The queue shows the shape of the job; the job screen also tints advisory
  /// answers so a technician can see where the advisories are.
  final bool showAdvisory;

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;
    final Color upcoming = context.colors.onSurface.withValues(alpha: 0.14);
    final StatusColorPair warning = context.statusColors.forTone(
      StatusTone.warning,
    );
    final StatusColorPair critical = context.statusColors.forTone(
      StatusTone.critical,
    );

    final Widget ticks = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var index = 0; index < _allItems.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == _allItems.length - 1 ? 0 : 3,
              ),
              child: _tick(
                context,
                item: _allItems[index],
                brand: brand,
                upcoming: upcoming,
                warning: warning,
                critical: critical,
              ),
            ),
          ),
      ],
    );

    final String label =
        'Job progress. ${results.length} of ${_allItems.length} items '
        'answered. Item $current is current. $_safetyCount safety-critical '
        'items.${interactive ? ' Tap to jump to an item.' : ''}';

    if (!interactive) {
      return Semantics(
        label: label,
        child: ExcludeSemantics(child: SizedBox(height: 32, child: ticks)),
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails details) {
                final double ratio =
                    details.localPosition.dx / constraints.maxWidth;
                final int index = (ratio * _allItems.length).floor().clamp(
                  0,
                  _allItems.length - 1,
                );
                onJump?.call(_allItems[index].number);
              },
              child: SizedBox(height: 44, child: Center(child: ticks)),
            );
          },
        ),
      ),
    );
  }

  Widget _tick(
    BuildContext context, {
    required PreviewItem item,
    required AppBrandColors brand,
    required Color upcoming,
    required StatusColorPair warning,
    required StatusColorPair critical,
  }) {
    final String? result = results[item.number];
    final bool isCurrent = item.number == current;
    final Duration duration = context.motionDuration(
      const Duration(milliseconds: 220),
    );

    final Color fill;
    final double height;
    if (isCurrent) {
      fill = brand.ink;
      height = 22;
    } else if (result == 'Advisory' && showAdvisory) {
      fill = warning.foreground;
      height = 14;
    } else if (result != null) {
      fill = brand.ink;
      height = 14;
    } else {
      fill = upcoming;
      height = 14;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              height: height,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: const BorderRadius.all(Radius.circular(1.5)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 4,
          child: Center(
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: item.safety ? critical.foreground : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: _eyebrow(context)),
        const SizedBox(width: 12),
        const Expanded(child: _Hairline()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

class _QueueScreen extends StatelessWidget {
  const _QueueScreen();

  @override
  Widget build(BuildContext context) {
    final PreviewJob current = previewJobs.firstWhere(
      (PreviewJob job) => job.current,
    );
    final List<PreviewJob> next = previewJobs
        .where((PreviewJob job) => !job.current && !job.overdue)
        .take(3)
        .toList(growable: false);
    final List<PreviewJob> unfinished = previewJobs
        .where((PreviewJob job) => job.overdue)
        .toList(growable: false);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 700;
          final Widget stack = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _RampHero(job: current, wide: wide),
              SizedBox(height: wide ? 32 : 24),
              const _SectionLabel(label: 'UP NEXT'),
              const SizedBox(height: 8),
              _UpNextSurface(jobs: next, roomy: wide),
              if (unfinished.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _UnfinishedGroup(jobs: unfinished),
              ],
            ],
          );

          if (wide) {
            return Column(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24, 12, 24, 0),
                  child: _QueueHeader(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      24,
                      16,
                      24,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: stack,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _QueueHeader(),
                      const SizedBox(height: 24),
                      stack,
                    ],
                  ),
                ),
              ),
              _ResumeDock(job: current),
            ],
          );
        },
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader();

  @override
  Widget build(BuildContext context) {
    final int inProgress = previewJobs
        .where((PreviewJob job) => job.current)
        .length;
    final int toDo = previewJobs.length - inProgress;
    final String state = toDo == 0
        ? '$inProgress in progress'
        : '$toDo to do · $inProgress in progress';

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Jobs',
                style: _type(
                  context,
                  26,
                  weight: FontWeight.w700,
                  height: 30,
                  tracking: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state,
                style: _type(
                  context,
                  13,
                  height: 18,
                  tabular: true,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _Avatar(),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;
    return Semantics(
      label: 'Signed in as Syed Moiz',
      child: ExcludeSemantics(
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: brand.container,
            shape: BoxShape.circle,
            border: Border.all(color: brand.ink.withValues(alpha: 0.14)),
          ),
          child: Text(
            'SM',
            style: _type(
              context,
              13.5,
              weight: FontWeight.w700,
              height: 16,
              tracking: 0.3,
              color: brand.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _RampHero extends StatelessWidget {
  const _RampHero({required this.job, required this.wide});

  final PreviewJob job;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;
    final Color ink = brand.ink;
    final Color muted = context.colors.onSurfaceVariant;
    final int answered = _initialResults.length;
    final PreviewSection section = _sectionForItem(previewCurrentItem.number);

    final Widget identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('ON THE RAMP', style: _eyebrow(context, color: ink)),
            const Spacer(),
            Text(
              job.when,
              textDirection: TextDirection.ltr,
              style: _type(
                context,
                12.5,
                weight: FontWeight.w700,
                height: 16,
                tabular: true,
                color: ink,
              ),
            ),
          ],
        ),
        SizedBox(height: wide ? 16 : 12),
        Text(
          job.vehicle,
          style: _type(
            context,
            wide ? 34 : 28,
            weight: FontWeight.w700,
            height: wide ? 44 : 34,
            tracking: -0.5,
          ),
        ),
        SizedBox(height: wide ? 12 : 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _Plate(plate: job.plate, onTint: true),
            Text(
              job.customer,
              style: _type(context, 13, height: 18, color: muted),
            ),
          ],
        ),
        SizedBox(height: wide ? 32 : 20),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$answered',
                style: _type(
                  context,
                  64,
                  weight: FontWeight.w800,
                  height: 64,
                  tracking: -1.5,
                  tabular: true,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 6),
                child: Text(
                  'of ${job.total} items',
                  style: _type(
                    context,
                    15,
                    weight: FontWeight.w600,
                    height: 20,
                    color: muted,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            _itemsLabel(answered, job.total),
            style: _type(
              context,
              13,
              weight: FontWeight.w600,
              height: 18,
              tabular: true,
            ),
          ),
        SizedBox(height: wide ? 16 : 12),
        _TickSpine(
          results: _initialResults,
          current: previewCurrentItem.number,
          showAdvisory: false,
        ),
        SizedBox(height: wide ? 20 : 16),
        Text(
          'Section ${_sectionNumberFor(section)} of ${previewSections.length}'
          ' · ${section.name}',
          style: _type(context, 12.5, height: 18, color: muted),
        ),
      ],
    );

    final Widget body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: identity),
              const SizedBox(width: 32),
              SizedBox(
                width: 240,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('RESUME', style: _eyebrow(context, color: muted)),
                    const SizedBox(height: 8),
                    Text(
                      previewCurrentItem.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _type(
                        context,
                        14,
                        weight: FontWeight.w600,
                        height: 20,
                        tracking: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Item ${previewCurrentItem.number} of ${job.total} · '
                      'photo required',
                      maxLines: 2,
                      style: _type(context, 11.5, height: 16, color: muted),
                    ),
                    const SizedBox(height: 16),
                    _PrimaryAction(
                      label: 'Resume inspection',
                      onTap: () {},
                      semanticLabel:
                          'Resume inspection for ${job.vehicle}, item '
                          '${previewCurrentItem.number}, '
                          '${previewCurrentItem.label}',
                    ),
                  ],
                ),
              ),
            ],
          )
        : identity;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(wide ? 32 : 24),
      decoration: BoxDecoration(
        color: brand.container,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: ink.withValues(alpha: 0.16)),
      ),
      child: body,
    );
  }
}

class _ResumeDock extends StatelessWidget {
  const _ResumeDock({required this.job});

  final PreviewJob job;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${previewCurrentItem.label} · item '
                      '${previewCurrentItem.number} of ${job.total}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _type(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        height: 16,
                        tabular: true,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PrimaryAction(
                label: 'Resume inspection',
                onTap: () {},
                semanticLabel:
                    'Resume inspection for ${job.vehicle}, ${job.plate}, '
                    'item ${previewCurrentItem.number}, '
                    '${previewCurrentItem.label}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpNextSurface extends StatelessWidget {
  const _UpNextSurface({required this.jobs, required this.roomy});

  final List<PreviewJob> jobs;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.xl),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < jobs.length; index++) ...<Widget>[
            if (index > 0) const _Hairline(indent: 16),
            _UpNextRow(job: jobs[index], roomy: roomy),
          ],
        ],
      ),
    );
  }
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.job, this.roomy = false});

  final PreviewJob job;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    final StatusColorPair warning = context.statusColors.forTone(
      StatusTone.warning,
    );
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          14,
          roomy ? 20 : 16,
          10,
          roomy ? 20 : 16,
        ),
        child: Row(
          children: <Widget>[
            if (job.overdue) ...<Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: warning.foreground,
              ),
              const SizedBox(width: 4),
            ],
            SizedBox(
              width: 48,
              child: Text(
                job.when,
                textDirection: TextDirection.ltr,
                style: _type(
                  context,
                  13,
                  weight: FontWeight.w700,
                  height: 18,
                  tabular: true,
                  color: job.overdue
                      ? warning.foreground
                      : context.colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    job.vehicle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _type(
                      context,
                      15,
                      weight: FontWeight.w600,
                      height: 20,
                      tracking: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.plate,
                    textDirection: TextDirection.ltr,
                    style: _type(
                      context,
                      12.5,
                      height: 18,
                      tracking: 0.2,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _itemsLabel(job.done, job.total),
              textDirection: TextDirection.ltr,
              style: _type(
                context,
                12,
                height: 16,
                tabular: true,
                color: muted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}

class _UnfinishedGroup extends StatefulWidget {
  const _UnfinishedGroup({required this.jobs});

  final List<PreviewJob> jobs;

  @override
  State<_UnfinishedGroup> createState() => _UnfinishedGroupState();
}

class _UnfinishedGroupState extends State<_UnfinishedGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    final Duration duration = context.motionDuration(
      const Duration(milliseconds: 220),
    );
    final int done = widget.jobs.fold<int>(
      0,
      (int sum, PreviewJob job) => sum + job.done,
    );
    final int total = widget.jobs.fold<int>(
      0,
      (int sum, PreviewJob job) => sum + job.total,
    );

    return Material(
      color: context.colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.xl),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            button: true,
            expanded: _open,
            label:
                'Unfinished, ${widget.jobs.length} job, $done of $total items',
            child: ExcludeSemantics(
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.history_rounded, size: 18, color: muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Unfinished · ${widget.jobs.length}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _type(
                              context,
                              14,
                              weight: FontWeight.w600,
                              height: 20,
                              tabular: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _itemsLabel(done, total),
                          style: _type(
                            context,
                            12,
                            height: 16,
                            tabular: true,
                            color: muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Column(
                    children: <Widget>[
                      const _Hairline(indent: 16),
                      for (final PreviewJob job in widget.jobs)
                        _UpNextRow(job: job),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Job
// ---------------------------------------------------------------------------

class _JobScreen extends StatefulWidget {
  const _JobScreen();

  @override
  State<_JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<_JobScreen> {
  final Map<int, String> _results = Map<int, String>.of(_initialResults);
  int _current = previewCurrentItem.number;

  PreviewItem get _item =>
      _allItems.firstWhere((PreviewItem item) => item.number == _current);

  PreviewSection get _section => _sectionForItem(_current);

  void _jumpTo(int number) => setState(() => _current = number);

  void _nextUnanswered() {
    final int start = _allItems.indexWhere(
      (PreviewItem item) => item.number == _current,
    );
    for (var offset = 1; offset <= _allItems.length; offset++) {
      final PreviewItem candidate =
          _allItems[(start + offset) % _allItems.length];
      if (!_results.containsKey(candidate.number)) {
        setState(() => _current = candidate.number);
        return;
      }
    }
  }

  void _answer(String result) {
    setState(() => _results[_current] = result);
    _nextUnanswered();
  }

  void _openSection(PreviewSection section) {
    final PreviewItem? next = section.next;
    setState(() {
      _current = next?.number ?? section.items.first.number;
    });
  }

  void _openSections() {
    final Color surface = context.colors.surface;
    final Color scrim = context.colors.scrim;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: scrim,
      constraints: BoxConstraints(maxHeight: maxHeight),
      builder: (BuildContext sheetContext) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(_sheetRadius),
            ),
          ),
          child: _SectionSheet(
            currentNumber: _current,
            onSelect: (PreviewSection section) {
              Navigator.of(sheetContext).pop();
              _openSection(section);
            },
          ),
        );
      },
    );
  }

  void _addPhoto() {
    final Color surface = context.colors.surface;
    final Color scrim = context.colors.scrim;
    final bool required = _item.photo;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: scrim,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      builder: (BuildContext sheetContext) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(_sheetRadius),
            ),
          ),
          child: _PhotoSheet(isRequired: required),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 700;
    final Widget card = _ItemCard(
      key: ValueKey<int>(_current),
      item: _item,
      sectionNumber: _sectionNumberFor(_section),
      sectionName: _section.name,
      totalItems: _allItems.length,
      onAddPhoto: _addPhoto,
      wide: wide,
    );
    final Widget animatedCard = AnimatedSwitcher(
      duration: context.motionDuration(const Duration(milliseconds: 220)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: card,
    );

    final Widget header = _JobHeader(
      results: _results,
      current: _current,
      onJump: _jumpTo,
      onSections: _openSections,
      showSectionControl: !wide,
    );

    final Widget dock = _ResultDock(
      item: _item,
      floating: wide,
      onAnswer: _answer,
      onAddPhoto: _addPhoto,
      onNext: _nextUnanswered,
    );

    if (wide) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: _CenterScroll(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: 12,
                              ),
                              child: animatedCard,
                            ),
                          ),
                          const SizedBox(height: 12),
                          dock,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 280,
                      child: _JobRail(
                        results: _results,
                        current: _current,
                        onJump: _jumpTo,
                        onSection: _openSection,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
            child: header,
          ),
          Expanded(
            child: _CenterScroll(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 12),
              alignment: AlignmentDirectional.topCenter,
              child: animatedCard,
            ),
          ),
          dock,
        ],
      ),
    );
  }
}

/// Places the item card at the top of the free space and scrolls instead of
/// clipping when the text scale or a long instruction needs the room.
class _CenterScroll extends StatelessWidget {
  const _CenterScroll({
    required this.child,
    this.padding = EdgeInsetsDirectional.zero,
    this.alignment = AlignmentDirectional.center,
  });

  final Widget child;
  final EdgeInsetsDirectional padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight =
            constraints.maxHeight - padding.top - padding.bottom;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight < 0 ? 0 : minHeight,
            ),
            child: Align(alignment: alignment, child: child),
          ),
        );
      },
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({
    required this.results,
    required this.current,
    required this.onJump,
    required this.onSections,
    required this.showSectionControl,
  });

  final Map<int, String> results;
  final int current;
  final ValueChanged<int> onJump;
  final VoidCallback onSections;
  final bool showSectionControl;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    final PreviewSection section = _sectionForItem(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _RoundButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back to jobs',
              onTap: () {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    previewVehicle,
                    maxLines: 2,
                    style: _type(
                      context,
                      17,
                      weight: FontWeight.w700,
                      height: 22,
                      tracking: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      const _Plate(plate: previewPlate, small: true),
                      Text(
                        previewReference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: _type(
                          context,
                          11.5,
                          height: 16,
                          tabular: true,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _SyncChip(),
          ],
        ),
        const SizedBox(height: 12),
        _TickSpine(
          results: results,
          current: current,
          interactive: true,
          onJump: onJump,
        ),
        if (showSectionControl) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _SectionControl(
                  label:
                      '${_shortSectionName(section.name)} · '
                      '${_sectionNumberFor(section)} of '
                      '${previewSections.length}',
                  semanticLabel:
                      'Section ${_sectionNumberFor(section)} of '
                      '${previewSections.length}, ${section.name}. '
                      'Change section',
                  onTap: onSections,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _itemsLabel(results.length, _allItems.length),
                style: _type(
                  context,
                  12.5,
                  height: 16,
                  tabular: true,
                  color: muted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionControl extends StatelessWidget {
  const _SectionControl({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: context.colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radii.pill),
            side: BorderSide(color: context.colors.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(
                          context,
                          12.5,
                          weight: FontWeight.w600,
                          height: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.sectionNumber,
    required this.sectionName,
    required this.totalItems,
    required this.onAddPhoto,
    required this.wide,
    super.key,
  });

  final PreviewItem item;
  final int sectionNumber;
  final String sectionName;
  final int totalItems;
  final VoidCallback onAddPhoto;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    final StatusColorPair critical = context.statusColors.forTone(
      StatusTone.critical,
    );
    final StatusColorPair info = context.statusColors.forTone(StatusTone.info);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(
        wide ? 28 : 24,
        wide ? 24 : 20,
        wide ? 28 : 24,
        wide ? 24 : 20,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ITEM ${item.number} OF $totalItems',
            style: _eyebrow(context).copyWith(fontFeatures: _tabularFigures),
          ),
          SizedBox(height: wide ? 12 : 8),
          Text(
            item.label,
            style: _type(
              context,
              wide ? 27 : 24,
              weight: FontWeight.w700,
              height: wide ? 34 : 30,
              tracking: -0.4,
            ),
          ),
          if (item.safety || item.photo) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (item.safety)
                  _Badge(
                    label: 'Safety critical',
                    icon: AppSeverity.safetyCritical.icon,
                    pair: critical,
                  ),
                if (item.photo)
                  _Badge(
                    label: 'Photo required',
                    icon: Icons.photo_camera_outlined,
                    pair: info,
                  ),
              ],
            ),
          ],
          SizedBox(height: wide ? 24 : 20),
          const _Hairline(),
          SizedBox(height: wide ? 24 : 16),
          Text(
            item.instruction,
            style: _type(
              context,
              wide ? 15.5 : 14.5,
              height: wide ? 24 : 22,
              color: muted,
            ),
          ),
          if (item.photo) ...<Widget>[
            SizedBox(height: wide ? 24 : 16),
            _PhotoStrip(onTap: onAddPhoto, tall: wide),
          ],
          SizedBox(height: wide ? 24 : 20),
          const _Hairline(),
          const SizedBox(height: 16),
          Text(
            'Section $sectionNumber of ${previewSections.length} · '
            '$sectionName',
            maxLines: 2,
            style: _type(context, 12.5, height: 18, color: muted),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.pair});

  final String label;
  final IconData icon;
  final StatusColorPair pair;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(context.radii.pill),
        border: Border.all(color: pair.foreground.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: pair.foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: _type(
              context,
              11.5,
              weight: FontWeight.w700,
              height: 14,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.onTap, this.tall = false});

  final VoidCallback onTap;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;
    return Semantics(
      button: true,
      label: 'Photo required. None added yet. Add photo.',
      child: ExcludeSemantics(
        child: Material(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(context.radii.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: tall ? 72 : 56,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: brand.container,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 17,
                        color: brand.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No photo yet · 0 of 1',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(
                          context,
                          13,
                          weight: FontWeight.w600,
                          height: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add',
                      style: _type(
                        context,
                        12.5,
                        weight: FontWeight.w700,
                        height: 16,
                        color: brand.ink,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: brand.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultDock extends StatelessWidget {
  const _ResultDock({
    required this.item,
    required this.floating,
    required this.onAnswer,
    required this.onAddPhoto,
    required this.onNext,
  });

  final PreviewItem item;

  /// Tablet: a rounded pad inside the card column. Phone: a full-bleed bar.
  final bool floating;
  final ValueChanged<String> onAnswer;
  final VoidCallback onAddPhoto;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final Widget results = Row(
      children: <Widget>[
        Expanded(
          child: _ResultButton(
            label: 'Pass',
            icon: Icons.check_circle_outline,
            pair: context.statusColors.forTone(StatusTone.success),
            semanticLabel: 'Pass item ${item.number}, ${item.label}',
            onTap: () => onAnswer('Pass'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResultButton(
            label: 'Advisory',
            icon: Icons.info_outline_rounded,
            pair: context.statusColors.forTone(StatusTone.warning),
            semanticLabel: 'Advisory on item ${item.number}, ${item.label}',
            onTap: () => onAnswer('Advisory'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResultButton(
            label: 'Fail',
            icon: Icons.warning_amber_rounded,
            pair: context.statusColors.forTone(StatusTone.danger),
            semanticLabel: 'Fail item ${item.number}, ${item.label}',
            onTap: () => onAnswer('Fail'),
          ),
        ),
      ],
    );

    final Widget secondary = Row(
      children: <Widget>[
        Expanded(
          child: _SecondaryButton(
            label: 'Add photo',
            icon: Icons.photo_camera_outlined,
            onTap: onAddPhoto,
            semanticLabel: 'Add photo to item ${item.number}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SecondaryButton(
            label: 'Next item',
            icon: Icons.arrow_forward_rounded,
            trailing: true,
            onTap: onNext,
            semanticLabel: 'Skip to the next item',
          ),
        ),
      ],
    );

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[results, const SizedBox(height: 8), secondary],
    );

    if (floating) {
      return Container(
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(context.radii.xl),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
          child: content,
        ),
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.icon,
    required this.pair,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final StatusColorPair pair;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: pair.background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_controlRadius),
            side: BorderSide(color: pair.foreground.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 20, color: pair.foreground),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _type(
                      context,
                      13.5,
                      weight: FontWeight.w700,
                      height: 16,
                      color: pair.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.trailing = false,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  /// `Next item` carries a directional icon that mirrors in RTL.
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: context.colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_controlRadius),
            side: BorderSide(color: context.colors.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    if (!trailing) ...<Widget>[
                      Icon(icon, size: 18, color: muted),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(
                          context,
                          13,
                          weight: FontWeight.w600,
                          height: 16,
                        ),
                      ),
                    ),
                    if (trailing) ...<Widget>[
                      const SizedBox(width: 6),
                      Icon(icon, size: 18, color: muted),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobRail extends StatelessWidget {
  const _JobRail({
    required this.results,
    required this.current,
    required this.onJump,
    required this.onSection,
  });

  final Map<int, String> results;
  final int current;
  final ValueChanged<int> onJump;
  final ValueChanged<PreviewSection> onSection;

  @override
  Widget build(BuildContext context) {
    final PreviewSection currentSection = _sectionForItem(current);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('THIS JOB', style: _eyebrow(context)),
                  const SizedBox(height: 12),
                  Text(
                    _itemsLabel(results.length, _allItems.length),
                    style: _type(
                      context,
                      15,
                      weight: FontWeight.w700,
                      height: 20,
                      tabular: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TickSpine(
                    results: results,
                    current: current,
                    interactive: true,
                    onJump: onJump,
                  ),
                  const SizedBox(height: 20),
                  const _Hairline(),
                  const SizedBox(height: 16),
                  Text('SECTIONS', style: _eyebrow(context)),
                  const SizedBox(height: 6),
                  for (final PreviewSection section in previewSections)
                    _RailSectionRow(
                      section: section,
                      isCurrent: section == currentSection,
                      onTap: () => onSection(section),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Hairline(),
          const SizedBox(height: 16),
          Text('CUSTOMER', style: _eyebrow(context)),
          const SizedBox(height: 4),
          Text(
            previewCustomer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _type(
              context,
              13.5,
              weight: FontWeight.w600,
              height: 18,
              tracking: -0.1,
            ),
          ),
          const SizedBox(height: 12),
          Text('REFERENCE', style: _eyebrow(context)),
          const SizedBox(height: 4),
          Text(
            previewReference,
            textDirection: TextDirection.ltr,
            style: _type(
              context,
              12,
              weight: FontWeight.w600,
              height: 16,
              tabular: true,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailSectionRow extends StatelessWidget {
  const _RailSectionRow({
    required this.section,
    required this.isCurrent,
    required this.onTap,
  });

  final PreviewSection section;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    final int number = _sectionNumberFor(section);
    final PreviewItem? next = section.next;
    return Semantics(
      button: true,
      selected: isCurrent,
      label:
          'Section $number, ${section.name}, ${section.done} of '
          '${section.total} answered',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radii.lg),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 3,
                  height: 40,
                  margin: const EdgeInsetsDirectional.only(top: 2),
                  decoration: BoxDecoration(
                    color: isCurrent ? context.brand.ink : Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        section.name,
                        maxLines: 2,
                        style: _type(
                          context,
                          13,
                          weight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          height: 18,
                          tracking: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        next == null
                            ? 'Complete · ${section.done} of ${section.total}'
                            : '${section.done} of ${section.total} · next: '
                                  '${next.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(
                          context,
                          11.5,
                          height: 16,
                          tabular: true,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (isCurrent)
                  const _NowPill()
                else
                  Icon(Icons.chevron_right_rounded, size: 18, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPill extends StatelessWidget {
  const _NowPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.brand.ink,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Text(
        'Now',
        style: _type(
          context,
          10.5,
          weight: FontWeight.w700,
          height: 13,
          tracking: 0.2,
          color: context.colors.onPrimary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(context.radii.pill),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.closeLabel,
  });

  final String title;
  final String subtitle;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: _type(
                    context,
                    20,
                    weight: FontWeight.w700,
                    height: 26,
                    tracking: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _type(
                    context,
                    12.5,
                    height: 18,
                    tabular: true,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundButton(
            icon: Icons.close_rounded,
            label: closeLabel,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SectionSheet extends StatelessWidget {
  const _SectionSheet({required this.currentNumber, required this.onSelect});

  final int currentNumber;
  final ValueChanged<PreviewSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    final PreviewSection currentSection = _sectionForItem(currentNumber);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 12),
          const _SheetHandle(),
          _SheetHeader(
            title: 'Sections',
            subtitle:
                '${previewSections.length} sections · '
                '${_allItems.length} items',
            closeLabel: 'Close sections',
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 12),
              child: Column(
                children: <Widget>[
                  for (final PreviewSection section in previewSections)
                    _SectionSheetRow(
                      section: section,
                      isCurrent: section == currentSection,
                      onTap: () => onSelect(section),
                      muted: muted,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSheetRow extends StatelessWidget {
  const _SectionSheetRow({
    required this.section,
    required this.isCurrent,
    required this.onTap,
    required this.muted,
  });

  final PreviewSection section;
  final bool isCurrent;
  final VoidCallback onTap;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final int number = _sectionNumberFor(section);
    final PreviewItem? next = section.next;
    final String sub = next == null
        ? 'Complete · ${section.done} of ${section.total}'
        : '${section.done} of ${section.total} answered · next: ${next.label}';

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
      child: Material(
        color: isCurrent ? context.brand.container : Colors.transparent,
        borderRadius: BorderRadius.circular(context.radii.lg),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          selected: isCurrent,
          label: 'Section $number, ${section.name}. $sub',
          child: ExcludeSemantics(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 26,
                      child: Text(
                        '$number',
                        style: _type(
                          context,
                          13,
                          weight: FontWeight.w700,
                          height: 18,
                          tabular: true,
                          color: isCurrent ? context.brand.onContainer : muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            section.name,
                            maxLines: 2,
                            style: _type(
                              context,
                              14,
                              weight: FontWeight.w600,
                              height: 20,
                              tracking: -0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            maxLines: 2,
                            style: _type(
                              context,
                              11.5,
                              height: 16,
                              tabular: true,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      const _NowPill()
                    else
                      Icon(Icons.chevron_right_rounded, size: 18, color: muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoSheet extends StatelessWidget {
  const _PhotoSheet({required this.isRequired});

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 12),
          const _SheetHandle(),
          _SheetHeader(
            title: 'Add a photo',
            subtitle: isRequired
                ? 'Required for this item · 0 of 1 added'
                : 'Optional for this item',
            closeLabel: 'Close photo options',
          ),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12, 4, 12, 16),
            child: Column(
              children: <Widget>[
                _PhotoOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take a photo',
                ),
                SizedBox(height: 6),
                _PhotoOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from gallery',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(context.radii.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Icon(icon, size: 20, color: muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: _type(
                          context,
                          14,
                          weight: FontWeight.w600,
                          height: 20,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
