import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'preview_data.dart';

/// Direction B — ROUTE. The job is a route the technician walks.
///
/// Throwaway design preview: it consumes only [previewData] and the shipped
/// `design_system` tokens. No production screen, router or shared widget is
/// touched.
class DirectionB extends StatelessWidget {
  const DirectionB({required this.screen, super.key});

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
// Direction constants
//
// The radii/type below are the values the brief fixes for this direction and
// that `design_system` does not expose as a token yet:
//   button 14, card 16, sheet 24, station title 15.5, eyebrow 11.5, page 24.
// They are named here instead of scattered as literals; see the report.
// ---------------------------------------------------------------------------

const double _pageGutterPhone = 20;
const double _pageGutterTablet = 24;
const double _pageGutterWide = 32;
const double _queueMaxWidth = 640;
const double _jobMaxWidth = 960;
const double _cardRadius = 16;
const double _controlRadius = 14;
const double _sheetRadius = 24;
const double _routeGutter = 32;
const double _routeContentInset = 48;
const double _routeLineWidth = 3;
const double _primaryHeight = 56;
const double _secondaryHeight = 48;
const Duration _accordionDuration = Duration(milliseconds: 200);
const Duration _pressDuration = Duration(milliseconds: 120);

double _pageGutter(double width) {
  if (width >= 1000) {
    return _pageGutterWide;
  }
  return width >= 700 ? _pageGutterTablet : _pageGutterPhone;
}

// ---------------------------------------------------------------------------
// Type helpers
// ---------------------------------------------------------------------------

TextStyle _pageTitleStyle(BuildContext context) =>
    context.texts.headlineLarge!.copyWith(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: context.colors.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

TextStyle _vehicleStyle(BuildContext context, {Color? color}) =>
    context.texts.titleLarge!.copyWith(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.15,
      color: color ?? context.colors.onSurface,
    );

TextStyle _stationTitleStyle(BuildContext context, {Color? color}) =>
    context.texts.titleLarge!.copyWith(
      fontSize: 15.5,
      height: 20 / 15.5,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color ?? context.colors.onSurface,
    );

TextStyle _itemStyle(
  BuildContext context, {
  Color? color,
  FontWeight weight = FontWeight.w600,
}) => context.texts.bodyMedium!.copyWith(
  fontSize: 14,
  height: 20 / 14,
  fontWeight: weight,
  letterSpacing: -0.07,
  color: color ?? context.colors.onSurface,
);

TextStyle _metaStyle(
  BuildContext context, {
  Color? color,
  FontWeight weight = FontWeight.w500,
}) => context.texts.bodySmall!.copyWith(
  fontSize: 12.5,
  height: 18 / 12.5,
  fontWeight: weight,
  letterSpacing: 0,
  color: color ?? context.colors.onSurfaceVariant,
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
);

TextStyle _eyebrowStyle(BuildContext context, {Color? color}) =>
    context.texts.labelSmall!.copyWith(
      fontSize: 11.5,
      height: 14 / 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color ?? context.colors.onSurfaceVariant,
    );

TextStyle _labelStyle(BuildContext context, {Color? color}) =>
    context.texts.labelLarge!.copyWith(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      color: color ?? context.colors.onSurface,
    );

TextStyle _timeStyle(BuildContext context, {Color? color}) =>
    context.texts.bodySmall!.copyWith(
      fontSize: 12.5,
      height: 18 / 12.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: color ?? context.colors.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

// ---------------------------------------------------------------------------
// Preview data helpers
// ---------------------------------------------------------------------------

const int _activeStation = 1; // Station 2 of 6 holds item 10.
const int _totalItems = 30;
// Derived from the fixture so the header, the bar and the item results can
// never disagree (they did: 12 was written over 9 answered items).
final int _answeredItems = previewJobs.first.done;

PreviewItem? get _nextItem {
  for (final section in previewSections) {
    final next = section.next;
    if (next != null) {
      return next;
    }
  }
  return null;
}

bool get _allAnswered => _nextItem == null;

enum _StationState { done, now, next, later }

extension on _StationState {
  String get word => switch (this) {
    _StationState.done => 'Done',
    _StationState.now => 'Now',
    _StationState.next => 'Next',
    _StationState.later => 'Later',
  };
}

_StationState _stateOf(int index) {
  final section = previewSections[index];
  if (section.next == null) {
    return _StationState.done;
  }
  if (index == _activeStation) {
    return _StationState.now;
  }
  if (index == _activeStation + 1) {
    return _StationState.next;
  }
  return _StationState.later;
}

String _jobSummaryLabel() => '$_answeredItems of $_totalItems items';

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

class _QueueScreen extends StatelessWidget {
  const _QueueScreen();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = _pageGutter(width);
    final unfinished = previewJobs.where((job) => job.overdue).length;
    final overdue = previewJobs.firstWhere((job) => job.overdue);
    final scheduled = previewJobs
        .where((job) => !job.current && !job.overdue)
        .toList(growable: false);
    final stopsLeft = previewJobs.where((job) => !job.overdue).length;

    final header = _QueueHeader(
      jobCount: previewJobs.length,
      unfinished: unfinished,
    );
    final pinned = _PinnedJobCard(job: overdue, onTap: () => _openJob(context));
    final upNext = Row(
      children: <Widget>[
        const _Eyebrow('Up next'),
        const Spacer(),
        Text('${scheduled.length} scheduled', style: _metaStyle(context)),
      ],
    );
    final group = _QueueGroup(jobs: scheduled, onTap: (_) => _openJob(context));
    final footer = _QueueFooter(
      stopsLeft: stopsLeft,
      scheduledAfter: scheduled.length,
    );
    final listChildren = <Widget>[
      pinned,
      const SizedBox(height: 24),
      upNext,
      const SizedBox(height: 8),
      group,
      const SizedBox(height: 24),
      footer,
      const SizedBox(height: 20),
    ];

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _queueMaxWidth,
                      ),
                      child: ListView(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          gutter,
                          20,
                          gutter,
                          20,
                        ),
                        children: <Widget>[
                          header,
                          const SizedBox(height: 20),
                          ...listChildren,
                        ],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    gutter,
                    20,
                    gutter,
                    20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _jobMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          header,
                          const SizedBox(height: 20),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: listChildren,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const SizedBox(
                                  width: 288,
                                  child: _DayRouteRail(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _ResumeBar(onPressed: () => _openJob(context)),
        ],
      ),
    );
  }

  static void _openJob(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DirectionB(screen: PreviewScreen.job),
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.jobCount, required this.unfinished});

  final int jobCount;
  final int unfinished;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final warning = context.statusColors.forTone(StatusTone.warning);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Today', style: _pageTitleStyle(context)),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    '$jobCount jobs',
                    style: _metaStyle(
                      context,
                      color: colors.onSurfaceVariant,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                    ),
                    child: Text(
                      '·',
                      style: _metaStyle(context, color: colors.outline),
                    ),
                  ),
                  Text(
                    '$unfinished unfinished',
                    style: _metaStyle(
                      context,
                      color: warning.foreground,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 4),
          child: Text(
            'Wed 25 Nov',
            style: _metaStyle(
              context,
              color: colors.onSurface,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PinnedJobCard extends StatelessWidget {
  const _PinnedJobCard({required this.job, required this.onTap});

  final PreviewJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final warning = context.statusColors.forTone(StatusTone.warning);

    return _TapSurface(
      onTap: onTap,
      semanticsLabel:
          'Unfinished, 23 Nov, ${job.vehicle}, ${job.plate}, '
          '${job.done} of ${job.total} items',
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: warning.background,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: warning.foreground.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Dot(color: warning.foreground, size: 6),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unfinished · 23 Nov',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _eyebrowStyle(
                      context,
                      color: warning.foreground,
                    ).copyWith(letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    job.vehicle,
                    maxLines: 2,
                    style: _vehicleStyle(context, color: colors.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                _DirectionalChevron(color: warning.foreground, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _PlatePill(plate: job.plate),
                const Spacer(),
                Text(
                  '${job.done} of ${job.total} items',
                  style: _metaStyle(
                    context,
                    color: warning.foreground,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueGroup extends StatelessWidget {
  const _QueueGroup({required this.jobs, required this.onTap});

  final List<PreviewJob> jobs;
  final ValueChanged<PreviewJob> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < jobs.length; index++) ...<Widget>[
            if (index > 0) _Hairline(color: colors.outlineVariant),
            _QueueRow(job: jobs[index], onTap: () => onTap(jobs[index])),
          ],
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.job, required this.onTap});

  final PreviewJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final info = context.statusColors.forTone(StatusTone.info);

    return _TapSurface(
      onTap: onTap,
      radius: 12,
      semanticsLabel:
          '${job.when}, ${job.vehicle}, ${job.plate}, '
          '${job.done} of ${job.total} items, ${job.status}',
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 48,
              child: Text(job.when, style: _timeStyle(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          job.vehicle,
                          maxLines: 2,
                          style: _vehicleStyle(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StateWord(label: job.status, color: info.foreground),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      _PlatePill(plate: job.plate),
                      const SizedBox(width: 8),
                      Text(
                        '${job.done} of ${job.total} items',
                        style: _metaStyle(context),
                      ),
                      const Spacer(),
                      const SizedBox(width: 4),
                      _DirectionalChevron(
                        color: colors.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueFooter extends StatelessWidget {
  const _QueueFooter({required this.stopsLeft, required this.scheduledAfter});

  final int stopsLeft;
  final int scheduledAfter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 32,
          child: Column(
            children: <Widget>[
              Container(
                width: _routeLineWidth,
                height: 14,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              _Dot(color: context.brand.ink, size: 8),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('$stopsLeft stops left today', style: _labelStyle(context)),
            const SizedBox(height: 2),
            Text(
              '$scheduledAfter scheduled after this',
              style: _metaStyle(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayRouteRail extends StatelessWidget {
  const _DayRouteRail();

  static const double _rowHeight = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final warning = context.statusColors.forTone(StatusTone.warning);
    final info = context.statusColors.forTone(StatusTone.info);
    final stops = <PreviewJob>[
      previewJobs.firstWhere((job) => job.overdue),
      previewJobs.firstWhere((job) => job.current),
      ...previewJobs.where((job) => !job.current && !job.overdue),
    ];
    final inHandIndex = stops.indexWhere((job) => job.current);
    final inHandCenter = _rowHeight / 2 + _rowHeight * inHandIndex;
    const lineStart = _rowHeight / 2;
    final lineEnd = _rowHeight * stops.length - _rowHeight / 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _Eyebrow('Day route'),
              const Spacer(),
              Text('${stops.length} stops', style: _metaStyle(context)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: _rowHeight * stops.length,
            child: Stack(
              children: <Widget>[
                PositionedDirectional(
                  start: _routeGutter / 2 - _routeLineWidth / 2,
                  top: lineStart,
                  width: _routeLineWidth,
                  height: inHandCenter - lineStart,
                  child: _RouteLine(color: brand.ink),
                ),
                PositionedDirectional(
                  start: _routeGutter / 2 - _routeLineWidth / 2,
                  top: inHandCenter,
                  width: _routeLineWidth,
                  height: lineEnd - inHandCenter,
                  child: _RouteLine(color: colors.outlineVariant),
                ),
                for (var index = 0; index < stops.length; index++) ...<Widget>[
                  PositionedDirectional(
                    start: 0,
                    top: _rowHeight * index,
                    width: _routeGutter,
                    height: _rowHeight,
                    child: Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: stops[index].current ? 17 : 19,
                        ),
                        child: _RailNode(index: index, job: stops[index]),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 44,
                    end: 0,
                    top: _rowHeight * index,
                    height: _rowHeight,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                stops[index].when,
                                style: _timeStyle(context),
                              ),
                              const Spacer(),
                              _StateWord(
                                label: stops[index].overdue
                                    ? 'Unfinished'
                                    : stops[index].current
                                    ? 'In hand'
                                    : index == inHandIndex + 1
                                    ? 'Next'
                                    : 'Scheduled',
                                color: stops[index].overdue
                                    ? warning.foreground
                                    : stops[index].current
                                    ? brand.ink
                                    : index == inHandIndex + 1
                                    ? info.foreground
                                    : colors.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stops[index].vehicle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _metaStyle(
                              context,
                              color: colors.onSurfaceVariant,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailNode extends StatelessWidget {
  const _RailNode({required this.index, required this.job});

  final int index;
  final PreviewJob job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final warning = context.statusColors.forTone(StatusTone.warning);

    if (job.current) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: brand.ink, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${index + 1}',
            style: _metaStyle(
              context,
              color: colors.onPrimary,
              weight: FontWeight.w700,
            ).copyWith(fontSize: 11.5, height: 14 / 11.5),
          ),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: job.overdue ? warning.background : colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: job.overdue
              ? warning.foreground.withValues(alpha: 0.3)
              : colors.outlineVariant,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: _metaStyle(
            context,
            color: job.overdue ? warning.foreground : colors.onSurfaceVariant,
            weight: FontWeight.w700,
          ).copyWith(fontSize: 11, height: 14 / 11),
        ),
      ),
    );
  }
}

class _ResumeBar extends StatelessWidget {
  const _ResumeBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gutter = _pageGutter(MediaQuery.sizeOf(context).width);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _queueMaxWidth),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gutter, 12, gutter, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: _routeLineWidth,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.brand.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Continue · Land Cruiser',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _labelStyle(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Item ${previewCurrentItem.number} · '
                          '${previewCurrentItem.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _metaStyle(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PrimaryButton(
                    label: 'Resume',
                    icon: Icons.arrow_forward_rounded,
                    mirrorIcon: true,
                    semanticLabel: 'Resume Land Cruiser job',
                    onPressed: onPressed,
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

// ---------------------------------------------------------------------------
// Job
// ---------------------------------------------------------------------------

class _JobScreen extends StatefulWidget {
  const _JobScreen();

  @override
  State<_JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<_JobScreen> {
  int? _openStation = _activeStation;
  int _selectedStation = _activeStation;

  void _toggleStation(int index) {
    setState(() {
      _openStation = _openStation == index ? null : index;
    });
  }

  void _selectStation(int index) {
    setState(() => _selectedStation = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = _pageGutter(width);

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _jobMaxWidth),
                child: const _JobHeader(),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 700) {
                  return _TabletJobBody(
                    gutter: gutter,
                    selected: _selectedStation,
                    onSelect: _selectStation,
                  );
                }
                return _PhoneJobBody(
                  gutter: gutter,
                  openStation: _openStation,
                  onToggle: _toggleStation,
                );
              },
            ),
          ),
          _JobActionBar(
            gutter: gutter,
            nextItem: _nextItem,
            allAnswered: _allAnswered,
          ),
        ],
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _IconOnlyButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back to today',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8),
                  child: Text(
                    previewVehicle,
                    maxLines: 2,
                    style: context.texts.titleLarge!.copyWith(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.16,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const _PlatePill(plate: previewPlate),
              const SizedBox(width: 8),
              Text(
                _jobSummaryLabel(),
                style: _metaStyle(
                  context,
                  color: colors.onSurface,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const _SyncChip(),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressTrack(
            value: _answeredItems / _totalItems,
            height: 3,
            color: context.brand.ink,
            track: colors.surfaceContainer,
            semanticLabel: 'Job progress',
            semanticValue: _jobSummaryLabel(),
          ),
        ],
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip();

  @override
  Widget build(BuildContext context) {
    final warning = context.statusColors.forTone(StatusTone.warning);

    return Container(
      height: 24,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: warning.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Dot(color: warning.foreground, size: 5),
          const SizedBox(width: 4),
          Text(
            'Sync pending',
            maxLines: 1,
            style: _metaStyle(
              context,
              color: warning.foreground,
              weight: FontWeight.w700,
            ).copyWith(fontSize: 10.5, height: 14 / 10.5, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _PhoneJobBody extends StatelessWidget {
  const _PhoneJobBody({
    required this.gutter,
    required this.openStation,
    required this.onToggle,
  });

  final double gutter;
  final int? openStation;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _queueMaxWidth),
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(gutter, 4, gutter, 24),
          children: <Widget>[
            const _RouteLabel(),
            const SizedBox(height: 12),
            for (var index = 0; index < previewSections.length; index++)
              _RouteStation(
                index: index,
                state: _stateOf(index),
                expanded: openStation == index,
                showChildren: true,
                activeItemNumber: index == _activeStation
                    ? previewCurrentItem.number
                    : null,
                onTap: () => onToggle(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabletJobBody extends StatelessWidget {
  const _TabletJobBody({
    required this.gutter,
    required this.selected,
    required this.onSelect,
  });

  final double gutter;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(gutter, 4, gutter, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _jobMaxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 40,
                child: ListView(
                  padding: EdgeInsetsDirectional.zero,
                  children: <Widget>[
                    const _RouteLabel(),
                    const SizedBox(height: 12),
                    for (var index = 0; index < previewSections.length; index++)
                      _RouteStation(
                        index: index,
                        state: _stateOf(index),
                        expanded: selected == index,
                        showChildren: false,
                        activeItemNumber: null,
                        onTap: () => onSelect(index),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 60,
                child: _StationPane(
                  index: selected,
                  activeItemNumber: selected == _activeStation
                      ? previewCurrentItem.number
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLabel extends StatelessWidget {
  const _RouteLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const _Eyebrow('Route'),
        const SizedBox(width: 8),
        Text('${previewSections.length} stations', style: _metaStyle(context)),
      ],
    );
  }
}

class _RouteStation extends StatelessWidget {
  const _RouteStation({
    required this.index,
    required this.state,
    required this.expanded,
    required this.showChildren,
    required this.activeItemNumber,
    required this.onTap,
  });

  final int index;
  final _StationState state;
  final bool expanded;
  final bool showChildren;
  final int? activeItemNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final section = previewSections[index];
    final tone = _toneFor(context, state);
    final isFirst = index == 0;
    final isLast = index == previewSections.length - 1;
    final walked = state == _StationState.done || state == _StationState.now;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: isLast ? 0 : 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (!isFirst)
            PositionedDirectional(
              start: _routeGutter / 2 - _routeLineWidth / 2,
              top: 0,
              width: _routeLineWidth,
              height: 31,
              child: _RouteLine(
                color: walked ? brand.ink : colors.outlineVariant,
              ),
            ),
          if (!isLast)
            PositionedDirectional(
              start: _routeGutter / 2 - _routeLineWidth / 2,
              top: 44,
              bottom: 0,
              width: _routeLineWidth,
              child: _RouteLine(
                color: state == _StationState.done
                    ? brand.ink
                    : colors.outlineVariant,
              ),
            ),
          PositionedDirectional(
            start: 0,
            width: _routeGutter,
            top: state == _StationState.now ? 14 : 18,
            child: Center(
              child: _StationNode(index: index, state: state),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: _routeContentInset,
            ),
            child: _TapSurface(
              onTap: onTap,
              semanticsLabel:
                  'Station ${index + 1}, ${section.name}, '
                  '${section.done} of ${section.total} items, '
                  '${state.word}',
              semanticsExpanded: showChildren ? expanded : null,
              child: _StationCard(
                index: index,
                section: section,
                state: state,
                expanded: expanded,
                showChildren: showChildren,
                activeItemNumber: activeItemNumber,
                tone: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationNode extends StatelessWidget {
  const _StationNode({required this.index, required this.state});

  final int index;
  final _StationState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final success = context.statusColors.forTone(StatusTone.success);
    final number = Text(
      '${index + 1}',
      style: _metaStyle(
        context,
        color: colors.onSurfaceVariant,
        weight: FontWeight.w700,
      ).copyWith(fontSize: 11.5, height: 14 / 11.5),
    );

    if (state == _StationState.now) {
      return Container(
        width: 34,
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: brand.container,
          shape: BoxShape.circle,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: brand.ink, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${index + 1}',
              style: _metaStyle(
                context,
                color: colors.onPrimary,
                weight: FontWeight.w700,
              ).copyWith(fontSize: 12.5, height: 15 / 12.5),
            ),
          ),
        ),
      );
    }

    if (state == _StationState.done) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: success.background,
          shape: BoxShape.circle,
          border: Border.all(color: success.foreground.withValues(alpha: 0.28)),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: _metaStyle(
              context,
              color: success.foreground,
              weight: FontWeight.w700,
            ).copyWith(fontSize: 11.5, height: 14 / 11.5),
          ),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Center(child: number),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.index,
    required this.section,
    required this.state,
    required this.expanded,
    required this.showChildren,
    required this.activeItemNumber,
    required this.tone,
  });

  final int index;
  final PreviewSection section;
  final _StationState state;
  final bool expanded;
  final bool showChildren;
  final int? activeItemNumber;
  final _CardTone tone;

  @override
  Widget build(BuildContext context) {
    final next = section.next;
    final stateColor = _stateColor(context, state);
    final muted = _metaStyle(context, color: tone.muted);
    final selectedOnTablet = !showChildren && expanded;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: selectedOnTablet ? context.brand.ink : tone.border,
          width: selectedOnTablet ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _StateWord(label: state.word, color: stateColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${section.done} of ${section.total} items',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _stationTitleStyle(context, color: tone.ink),
                    ),
                    const SizedBox(height: 8),
                    // When the station is open its items are right below and the
                    // current one is already marked, so repeating "Next · …"
                    // here would say the same thing twice.
                    if (!expanded && next == null)
                      Text(
                        'All ${section.total} items answered',
                        maxLines: 2,
                        style: muted,
                      )
                    else if (!expanded && next != null)
                      Text.rich(
                        TextSpan(
                          style: muted,
                          children: <InlineSpan>[
                            const TextSpan(text: 'Next · '),
                            TextSpan(
                              text: next.label,
                              style: muted.copyWith(
                                color: tone.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showChildren)
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: context.motionDuration(_accordionDuration),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: tone.muted,
                  ),
                ),
            ],
          ),
          if (showChildren)
            AnimatedSize(
              duration: context.motionDuration(_accordionDuration),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _Hairline(color: tone.hairline),
                          _StationItems(
                            section: section,
                            activeItemNumber: activeItemNumber,
                            tone: tone,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
        ],
      ),
    );
  }
}

class _StationPane extends StatelessWidget {
  const _StationPane({required this.index, required this.activeItemNumber});

  final int index;
  final int? activeItemNumber;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final section = previewSections[index];
    final state = _stateOf(index);
    final tone = _toneFor(context, state);
    final headerTone = state == _StationState.now
        ? tone
        : _toneFor(context, _StationState.next);
    final bodyTone = _toneFor(context, _StationState.next);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: headerTone.background,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _StateWord(
                      label: state.word,
                      color: _stateColor(context, state),
                    ),
                    const Spacer(),
                    Text(
                      'STATION ${index + 1}',
                      style: _eyebrowStyle(context, color: headerTone.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  section.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineMedium!.copyWith(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.27,
                    color: headerTone.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      '${section.done} of ${section.total} items',
                      style: _metaStyle(
                        context,
                        color: headerTone.muted,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (section.next != null)
                      Flexible(
                        child: Text(
                          'Next · ${section.next!.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: _metaStyle(context, color: headerTone.muted),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _ProgressTrack(
                  value: section.done / section.total,
                  height: 3,
                  color: state == _StationState.now
                      ? context.brand.ink
                      : colors.onSurfaceVariant,
                  track: headerTone.hairline,
                ),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
              children: <Widget>[
                _StationItems(
                  section: section,
                  activeItemNumber: activeItemNumber,
                  tone: bodyTone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationItems extends StatelessWidget {
  const _StationItems({
    required this.section,
    required this.activeItemNumber,
    required this.tone,
  });

  final PreviewSection section;
  final int? activeItemNumber;
  final _CardTone tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < section.items.length; index++) ...<Widget>[
          if (index > 0) _Hairline(color: tone.hairline),
          _ItemRow(
            item: section.items[index],
            active: section.items[index].number == activeItemNumber,
            tone: tone,
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.active,
    required this.tone,
  });

  final PreviewItem item;
  final bool active;
  final _CardTone tone;

  @override
  Widget build(BuildContext context) {
    final answered = item.result != null;
    final labelColor = answered ? tone.muted : tone.ink;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 26,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 1),
              child: Text(
                '${item.number}',
                style: _metaStyle(
                  context,
                  color: tone.muted,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _itemStyle(
                    context,
                    color: labelColor,
                    weight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (!answered && (item.safety || item.photo)) ...<Widget>[
                  const SizedBox(height: 4),
                  _ItemFlags(item: item, color: tone.muted),
                ],
              ],
            ),
          ),
          if (answered) ...<Widget>[
            const SizedBox(width: 8),
            _ResultChip(result: item.result!),
          ] else if (active) ...<Widget>[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: _StateWord(
                label: 'Now',
                color: context.brand.ink,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemFlags extends StatelessWidget {
  const _ItemFlags({required this.item, required this.color});

  final PreviewItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        if (item.safety)
          _InlineFlag(
            icon: Icons.shield_outlined,
            label: 'Safety critical',
            color: color,
          ),
        if (item.photo)
          _InlineFlag(
            icon: Icons.photo_camera_outlined,
            label: 'Photo required',
            color: color,
          ),
      ],
    );
  }
}

class _InlineFlag extends StatelessWidget {
  const _InlineFlag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: _metaStyle(
            context,
            color: color,
          ).copyWith(fontSize: 11, height: 14 / 11),
        ),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final tone = switch (result) {
      'Advisory' => StatusTone.warning,
      'Fail' => StatusTone.danger,
      _ => StatusTone.success,
    };
    final pair = context.statusColors.forTone(tone);

    return Container(
      height: 22,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          result,
          maxLines: 1,
          style: _metaStyle(
            context,
            color: pair.foreground,
            weight: FontWeight.w700,
          ).copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.2),
        ),
      ),
    );
  }
}

class _JobActionBar extends StatelessWidget {
  const _JobActionBar({
    required this.gutter,
    required this.nextItem,
    required this.allAnswered,
  });

  final double gutter;
  final PreviewItem? nextItem;
  final bool allAnswered;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = allAnswered ? 'Finish job' : 'Check';
    final eyebrow = allAnswered ? 'READY TO FINISH' : 'NEXT ITEM';
    final value = allAnswered
        ? 'All $_totalItems items answered'
        : '${nextItem?.number ?? ''} · ${nextItem?.label ?? 'Summary'}';
    final semantics = allAnswered
        ? 'Finish job, all $_totalItems items answered'
        : 'Check item ${nextItem?.number}, ${nextItem?.label}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _jobMaxWidth),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gutter, 12, gutter, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          eyebrow,
                          maxLines: 1,
                          style: _eyebrowStyle(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _labelStyle(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SecondaryButton(
                    label: 'Summary',
                    semanticLabel: 'Open job summary',
                    onPressed: () => _showSummary(context),
                  ),
                  const SizedBox(width: 8),
                  _PrimaryButton(
                    label: label,
                    icon: Icons.check_rounded,
                    semanticLabel: semantics,
                    onPressed: () {},
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

class _SummarySheet extends StatelessWidget {
  const _SummarySheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(_sheetRadius),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Summary',
                          style: context.texts.headlineMedium!.copyWith(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.27,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      _IconOnlyButton(
                        icon: Icons.close_rounded,
                        semanticLabel: 'Close summary',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$previewVehicle · ${_jobSummaryLabel()}',
                    style: _metaStyle(context),
                  ),
                  const SizedBox(height: 16),
                  for (
                    var index = 0;
                    index < previewSections.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) _Hairline(color: colors.outlineVariant),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${index + 1}',
                              style: _metaStyle(
                                context,
                                color: colors.onSurfaceVariant,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              previewSections[index].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _itemStyle(
                                context,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${previewSections[index].done} of '
                            '${previewSections[index].total} items',
                            style: _metaStyle(
                              context,
                              color: colors.onSurfaceVariant,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${_totalItems - _answeredItems} items still to answer '
                    'before handover.',
                    style: _metaStyle(context),
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

Future<void> _showSummary(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    builder: (_) => const _SummarySheet(),
  );
}

// ---------------------------------------------------------------------------
// Shared visual primitives
// ---------------------------------------------------------------------------

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _eyebrowStyle(context),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color);
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _PlatePill extends StatelessWidget {
  const _PlatePill({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 22,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          plate,
          maxLines: 1,
          style: _metaStyle(
            context,
            color: colors.onSurfaceVariant,
            weight: FontWeight.w700,
          ).copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.3),
        ),
      ),
    );
  }
}

class _StateWord extends StatelessWidget {
  const _StateWord({
    required this.label,
    required this.color,
    this.fontSize = 11.5,
  });

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Dot(color: color, size: 6),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _metaStyle(
              context,
              color: color,
              weight: FontWeight.w700,
            ).copyWith(fontSize: fontSize, height: 16 / fontSize),
          ),
        ),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({
    required this.value,
    required this.height,
    required this.color,
    required this.track,
    this.semanticLabel,
    this.semanticValue,
  });

  final double value;
  final double height;
  final Color color;
  final Color track;
  final String? semanticLabel;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(999),
        ),
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: value.clamp(0, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron({required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _MirroredIcon(Icons.chevron_right_rounded, size: size, color: color);
  }
}

class _MirroredIcon extends StatelessWidget {
  const _MirroredIcon(this.icon, {this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: Icon(icon, size: size, color: color),
    );
  }
}

Color _stateColor(BuildContext context, _StationState state) {
  final colors = context.colors;
  return switch (state) {
    _StationState.done =>
      context.statusColors.forTone(StatusTone.success).foreground,
    _StationState.now => context.brand.ink,
    _StationState.next =>
      context.statusColors.forTone(StatusTone.info).foreground,
    _StationState.later => colors.onSurfaceVariant,
  };
}

class _CardTone {
  const _CardTone({
    required this.background,
    required this.border,
    required this.ink,
    required this.muted,
    required this.hairline,
  });

  final Color background;
  final Color border;
  final Color ink;
  final Color muted;
  final Color hairline;
}

_CardTone _toneFor(BuildContext context, _StationState state) {
  final colors = context.colors;
  final brand = context.brand;

  return switch (state) {
    _StationState.now => _CardTone(
      background: brand.container,
      border: brand.ink.withValues(alpha: 0.16),
      ink: brand.onContainer,
      muted: brand.onContainer.withValues(alpha: 0.76),
      hairline: brand.onContainer.withValues(alpha: 0.14),
    ),
    _StationState.done => _CardTone(
      background: colors.surface,
      border: colors.outlineVariant,
      ink: colors.onSurface,
      muted: colors.onSurfaceVariant,
      hairline: colors.outlineVariant,
    ),
    _StationState.next => _CardTone(
      background: colors.surface,
      border: colors.outlineVariant,
      ink: colors.onSurface,
      muted: colors.onSurfaceVariant,
      hairline: colors.outlineVariant,
    ),
    _StationState.later => _CardTone(
      background: colors.surface,
      border: colors.outlineVariant.withValues(alpha: 0.65),
      ink: colors.onSurfaceVariant,
      muted: colors.onSurfaceVariant,
      hairline: colors.outlineVariant,
    ),
  };
}

// ---------------------------------------------------------------------------
// Interaction primitives
// ---------------------------------------------------------------------------

class _TapSurface extends StatefulWidget {
  const _TapSurface({
    required this.onTap,
    required this.child,
    this.radius = _cardRadius,
    this.semanticsLabel,
    this.semanticsExpanded,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final String? semanticsLabel;
  final bool? semanticsExpanded;

  @override
  State<_TapSurface> createState() => _TapSurfaceState();
}

class _TapSurfaceState extends State<_TapSurface> {
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      expanded: widget.semanticsExpanded,
      excludeSemantics: widget.semanticsLabel != null,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onFocusChange: (value) {
          if (_focused != value) {
            setState(() => _focused = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: AnimatedScale(
          scale: _pressed ? 0.996 : 1,
          duration: context.motionDuration(_pressDuration),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: context.motionDuration(_pressDuration),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: _focused ? context.shadows.focusRing : null,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconOnlyButton extends StatefulWidget {
  const _IconOnlyButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  State<_IconOnlyButton> createState() => _IconOnlyButtonState();
}

class _IconOnlyButtonState extends State<_IconOnlyButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onFocusChange: (value) {
          if (_focused != value) {
            setState(() => _focused = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: context.motionDuration(_pressDuration),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(_controlRadius),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: _focused ? context.shadows.focusRing : null,
            ),
            child: Center(
              child: _MirroredIcon(
                widget.icon,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.icon,
    this.mirrorIcon = false,
  });

  final String label;
  final VoidCallback onPressed;
  final String semanticLabel;
  final IconData? icon;
  final bool mirrorIcon;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _focused = false;
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final fill = _hovered
        ? Color.lerp(brand.ink, colors.onSurface, 0.18)!
        : brand.ink;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) {
          if (_hovered != value) {
            setState(() => _hovered = value);
          }
        },
        onFocusChange: (value) {
          if (_focused != value) {
            setState(() => _focused = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: context.motionDuration(_pressDuration),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: context.motionDuration(_pressDuration),
            height: _primaryHeight,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(_controlRadius),
              boxShadow: _focused ? context.shadows.focusRing : null,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: widget.onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.icon != null) ...<Widget>[
                    if (widget.mirrorIcon)
                      _MirroredIcon(
                        widget.icon!,
                        size: 17,
                        color: colors.onPrimary,
                      )
                    else
                      Icon(widget.icon, size: 17, color: colors.onPrimary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    maxLines: 1,
                    style: _labelStyle(
                      context,
                      color: colors.onPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
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

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) {
          if (_hovered != value) {
            setState(() => _hovered = value);
          }
        },
        onFocusChange: (value) {
          if (_focused != value) {
            setState(() => _focused = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: context.motionDuration(_pressDuration),
            height: _secondaryHeight,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? colors.surfaceContainer : colors.surface,
              borderRadius: BorderRadius.circular(_controlRadius),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: _focused ? context.shadows.focusRing : null,
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              style: _labelStyle(
                context,
                color: colors.onSurface,
              ).copyWith(fontSize: 12.5, height: 16 / 12.5),
            ),
          ),
        ),
      ),
    );
  }
}
