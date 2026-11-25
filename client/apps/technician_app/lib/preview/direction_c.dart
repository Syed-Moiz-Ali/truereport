import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'preview_data.dart';

/// Direction C — DECK. Items are cards the technician clears.
///
/// Two screens prove the idea:
///
/// * `queue` — the current car is the front card of a physical stack; the next
///   two jobs peek above it with their own tonal edge. Days are a segmented
///   control with counts, not a calendar rail. One primary verb sits in the
///   thumb zone.
/// * `job` — one item fills the screen, with the next card visibly settling
///   behind it. The 30-dot strip and the section chip above the card keep the
///   technician oriented without a list. Pass / Advisory / Fail are huge in the
///   thumb zone; the card itself is draggable (right = pass, left = fail) and a
///   Next fallback keeps the preview navigable without the gesture.
///
/// Everything is throwaway preview code: the only strings invented here are
/// layout labels ("Your ramp", "NEXT", "THEN"). Job, section and item content
/// comes from `preview_data.dart`.
///
/// The deck metaphor is static: stacked surfaces with a 8 px inset taper and
/// tonal edges behind the front card. Motion (240 ms settle on advance) only
/// confirms what the still image already says.

/// The direction's control radius. The shared ladder is 12/16/24; the brief
/// asks for 14 on buttons, which has no token yet (reported as a gap).
const double _controlRadius = 14;

const Curve _settleCurve = Curves.easeOutCubic;

/// A flat, addressable item across the whole job.
@immutable
class _FlatItem {
  const _FlatItem({
    required this.globalIndex,
    required this.sectionIndex,
    required this.section,
    required this.item,
  });

  final int globalIndex;
  final int sectionIndex;
  final PreviewSection section;
  final PreviewItem item;
}

class DirectionC extends StatefulWidget {
  const DirectionC({required this.screen, super.key});

  final PreviewScreen screen;

  @override
  State<DirectionC> createState() => _DirectionCState();
}

class _DirectionCState extends State<DirectionC> {
  static final List<_FlatItem> _flat = <_FlatItem>[
    for (var s = 0; s < previewSections.length; s += 1)
      for (var i = 0; i < previewSections[s].items.length; i += 1)
        _FlatItem(
          globalIndex:
              previewSections
                  .take(s)
                  .fold<int>(0, (sum, section) => sum + section.items.length) +
              i,
          sectionIndex: s,
          section: previewSections[s],
          item: previewSections[s].items[i],
        ),
  ];

  /// Preview-only navigation: the queue's primary action opens the job, the
  /// job's back control returns to the queue. Never touches the real router.
  PreviewScreen? _screenOverride;
  int _tab = 0;
  int _itemIndex = 9;
  int _epoch = 0;

  /// Answers given in this preview session, keyed by item number. The shared
  /// sample data stays const; this map is the only mutable state.
  final Map<int, String> _answerFor = <int, String>{};

  @override
  void initState() {
    super.initState();
    final current = _flat.indexWhere(
      (entry) => entry.item.number == previewCurrentItem.number,
    );
    if (current >= 0) {
      _itemIndex = current;
    }
  }

  PreviewScreen get _screen => _screenOverride ?? widget.screen;

  _FlatItem get _current => _flat[_itemIndex];

  String? _resultOf(PreviewItem item) => _answerFor[item.number] ?? item.result;

  int _doneIn(PreviewSection section) =>
      section.items.where((item) => _resultOf(item) != null).length;

  /// The next unanswered card, wrapping so the deck never dies mid-session.
  int? _nextUnansweredFrom(int from) {
    for (var step = 1; step <= _flat.length; step += 1) {
      final index = (from + step) % _flat.length;
      if (_resultOf(_flat[index].item) == null) {
        return index;
      }
    }
    return null;
  }

  void _answer(String result) {
    final item = _current.item;
    setState(() {
      _answerFor[item.number] = result;
      _epoch += 1;
      final next = _nextUnansweredFrom(_itemIndex);
      if (next != null) {
        _itemIndex = next;
      }
    });
  }

  void _advance() {
    final next = _nextUnansweredFrom(_itemIndex);
    if (next == null) {
      return;
    }
    setState(() {
      _itemIndex = next;
      _epoch += 1;
    });
  }

  void _jumpToSection(int sectionIndex) {
    var target = _flat.indexWhere(
      (entry) =>
          entry.sectionIndex == sectionIndex && _resultOf(entry.item) == null,
    );
    if (target < 0) {
      target = _flat.indexWhere((entry) => entry.sectionIndex == sectionIndex);
    }
    if (target < 0) {
      return;
    }
    setState(() {
      _itemIndex = target;
      _epoch += 1;
    });
  }

  Future<void> _openSections() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surfaceLowest,
      barrierColor: context.colors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radii.card),
        ),
      ),
      builder: (sheetContext) => _DismissibleSheet(
        child: _SectionSheet(
          currentSectionIndex: _current.sectionIndex,
          doneInSection: (section) => _doneIn(section),
          onClose: () => Navigator.of(sheetContext).pop(),
          onPick: (index) => Navigator.of(sheetContext).pop(index),
        ),
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    _jumpToSection(picked);
  }

  Future<void> _showAddPhotoNote() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.colors.surfaceLowest,
      barrierColor: context.colors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radii.card),
        ),
      ),
      builder: (sheetContext) => _DismissibleSheet(
        child: _PreviewNoteSheet(
          title: 'Add a photo',
          body:
              'The camera flow is not wired in this preview. On device this '
              'opens capture for item ${_current.item.number}, '
              '${_current.item.label}.',
          onClose: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  int get _todayCount => previewJobs.length;

  int get _upcomingCount => previewJobs
      .where((job) => !job.current && !job.overdue && job.done == 0)
      .length;

  int get _unfinishedCount => previewJobs.where((job) => job.done > 0).length;

  List<PreviewJob> _jobsForTab(int tab) => switch (tab) {
    1 =>
      previewJobs
          .where((job) => !job.current && !job.overdue && job.done == 0)
          .toList(growable: false),
    2 => previewJobs.where((job) => job.done > 0).toList(growable: false),
    _ => previewJobs,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: SafeArea(
        child: _screen == PreviewScreen.queue
            ? _buildQueue(context)
            : _buildJob(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUEUE
  // ---------------------------------------------------------------------------

  Widget _buildQueue(BuildContext context) {
    final jobs = _jobsForTab(_tab);
    final front = jobs.isNotEmpty ? jobs.first : previewJobs.first;
    final behind = jobs.skip(1).take(2).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final gutter = isTablet ? context.spacing.xl : context.spacing.lg;
        // The queue card is a card, not a stretched page: cap the deck so its
        // content stays composed and the whitespace reads as a stage.
        final deckMax = isTablet ? 500.0 : 436.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 600 : 540),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                context.spacing.lg,
                gutter,
                context.spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QueueHeader(
                    jobsToday: _todayCount,
                    inProgress: previewJobs.where((job) => job.current).length,
                  ),
                  SizedBox(height: context.spacing.lg),
                  _DaySegments(
                    selected: _tab,
                    counts: <int>[
                      _todayCount,
                      _upcomingCount,
                      _unfinishedCount,
                    ],
                    onSelected: (index) => setState(() => _tab = index),
                  ),
                  SizedBox(height: context.spacing.lg),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        // Leave room for the "See all" label inside the stage so
                        // the primary stays the bottom-most control.
                        final deckHeight = math
                            .min(math.max(box.maxHeight - 56, 0), deckMax)
                            .toDouble();
                        return Align(
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: deckHeight,
                                child: _QueueDeck(
                                  behind: behind,
                                  frontCard: _QueueJobCard(job: front),
                                ),
                              ),
                              SizedBox(height: context.spacing.sm),
                              // Label-only affordance: nothing is wired to it
                              // in this preview, so it must not pretend to be a
                              // button.
                              SizedBox(
                                height: context.sizing.targetMin,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'See all jobs',
                                      style: context.texts.labelLarge?.copyWith(
                                        fontSize: 13,
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(width: context.spacing.xs),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: context.sizing.iconSm,
                                      color: context.colors.onSurfaceVariant,
                                      textDirection: Directionality.of(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.spacing.md),
                  _PrimaryAction(
                    label: front.current
                        ? 'Continue inspection'
                        : 'Start next job',
                    onPressed: () =>
                        setState(() => _screenOverride = PreviewScreen.job),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // JOB
  // ---------------------------------------------------------------------------

  Widget _buildJob(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final gutter = isTablet ? context.spacing.xl : context.spacing.lg;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                isTablet ? context.spacing.xl : context.spacing.lg,
                gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _JobHeader(
                    reference: previewReference,
                    plate: previewPlate,
                    vehicle: previewVehicle,
                    onBack: () =>
                        setState(() => _screenOverride = PreviewScreen.queue),
                    onSections: _openSections,
                  ),
                  SizedBox(
                    height: isTablet
                        ? context.spacing.gutter
                        : context.spacing.lg,
                  ),
                  isTablet ? _buildTabletJob(context) : _buildPhoneJob(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneJob(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JobMetaRow(
            done: previewJobs.first.done,
            total: previewJobs.first.total,
            section: _current.section,
            doneInSection: _doneIn(_current.section),
            onSections: _openSections,
          ),
          SizedBox(height: context.spacing.sm),
          _ProgressStrip(
            items: _flat,
            currentIndex: _itemIndex,
            resultOf: _resultOf,
            done: previewJobs.first.done,
            total: previewJobs.first.total,
          ),
          SizedBox(height: context.spacing.md),
          Expanded(child: _buildDeck(context)),
          SizedBox(height: context.spacing.md),
          _AnswerDock(
            item: _current.item,
            onPass: () => _answer('Pass'),
            onAdvisory: () => _answer('Advisory'),
            onFail: () => _answer('Fail'),
            onPhoto: _showAddPhotoNote,
            onNext: _advance,
          ),
          SizedBox(height: context.spacing.md),
        ],
      ),
    );
  }

  Widget _buildTabletJob(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _JobMetaRow(
                  done: previewJobs.first.done,
                  total: previewJobs.first.total,
                  section: _current.section,
                  doneInSection: _doneIn(_current.section),
                  onSections: _openSections,
                ),
                SizedBox(height: context.spacing.sm),
                _ProgressStrip(
                  items: _flat,
                  currentIndex: _itemIndex,
                  resultOf: _resultOf,
                  done: previewJobs.first.done,
                  total: previewJobs.first.total,
                ),
                SizedBox(height: context.spacing.md),
                Expanded(child: _buildDeck(context)),
                SizedBox(height: context.spacing.md),
                _AnswerDock(
                  item: _current.item,
                  onPass: () => _answer('Pass'),
                  onAdvisory: () => _answer('Advisory'),
                  onFail: () => _answer('Fail'),
                  onPhoto: _showAddPhotoNote,
                  onNext: _advance,
                ),
                SizedBox(height: context.spacing.md),
              ],
            ),
          ),
          SizedBox(width: context.spacing.xl),
          SizedBox(
            width: 264,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: _AnsweredRail(
                section: _current.section,
                currentItem: _current.item,
                resultOf: _resultOf,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The current item card with the next surface settling behind it.
  Widget _buildDeck(BuildContext context) {
    const peek = 20.0;
    final duration = context.motionDuration(const Duration(milliseconds: 240));
    final item = _current.item;
    final nextIndex = _nextUnansweredFrom(_itemIndex);

    return LayoutBuilder(
      builder: (context, box) {
        final total = math.min(box.maxHeight, 520.0).toDouble();
        final cardHeight = math.max(total - peek, 0).toDouble();
        final card = _ItemCard(
          item: item,
          position: _current.globalIndex + 1,
          total: _flat.length,
          result: _resultOf(item),
          next: nextIndex == null ? null : _flat[nextIndex].item,
          onAddPhoto: _showAddPhotoNote,
        );

        return Center(
          child: SizedBox(
            height: total,
            child: Stack(
              children: [
                // The settling surface: a second card, not an animation.
                Positioned(
                  top: 0,
                  left: context.spacing.sm,
                  right: context.spacing.sm,
                  height: cardHeight,
                  child: const IgnorePointer(child: _NextCardSurface()),
                ),
                Positioned(
                  top: peek,
                  left: 0,
                  right: 0,
                  height: cardHeight,
                  child: _SettleIn(
                    key: ValueKey<String>('settle-${item.number}-$_epoch'),
                    duration: duration,
                    child: Dismissible(
                      key: ValueKey<String>('card-${item.number}-$_epoch'),
                      direction: DismissDirection.horizontal,
                      movementDuration: duration,
                      resizeDuration: context.motionDuration(
                        const Duration(milliseconds: 180),
                      ),
                      dismissThresholds: const <DismissDirection, double>{
                        DismissDirection.startToEnd: 0.32,
                        DismissDirection.endToStart: 0.32,
                      },
                      background: ExcludeSemantics(
                        child: _SwipeReveal(
                          tone: StatusTone.success,
                          label: 'Pass',
                          icon: Icons.check_rounded,
                          alignment: AlignmentDirectional.centerStart,
                          radius: context.radii.xl,
                        ),
                      ),
                      secondaryBackground: ExcludeSemantics(
                        child: _SwipeReveal(
                          tone: StatusTone.danger,
                          label: 'Fail',
                          icon: Icons.close_rounded,
                          alignment: AlignmentDirectional.centerEnd,
                          radius: context.radii.xl,
                        ),
                      ),
                      onDismissed: (direction) => _answer(
                        direction == DismissDirection.startToEnd
                            ? 'Pass'
                            : 'Fail',
                      ),
                      child: card,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// QUEUE PIECES
// -----------------------------------------------------------------------------

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.jobsToday, required this.inProgress});

  final int jobsToday;
  final int inProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: brand.container,
            borderRadius: BorderRadius.circular(context.radii.lg),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.build_rounded, size: 20, color: brand.onContainer),
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRUEREPORT · TECHNICIAN',
                style: _eyebrowStyle(context, colors.onSurfaceVariant),
              ),
              SizedBox(height: context.spacing.xxs),
              Text(
                'Your ramp',
                style: context.texts.headlineLarge?.copyWith(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: context.spacing.xxs),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$jobsToday',
                      style: _metaStyle(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' jobs today · ',
                      style: _metaStyle(context),
                    ),
                    TextSpan(
                      text: '$inProgress',
                      style: _metaStyle(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    TextSpan(text: ' in progress', style: _metaStyle(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaySegments extends StatelessWidget {
  const _DaySegments({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final int selected;
  final List<int> counts;
  final ValueChanged<int> onSelected;

  static const List<String> _labels = <String>[
    'Today',
    'Upcoming',
    'Unfinished',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(context.radii.pill),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i += 1)
            Expanded(
              child: _Segment(
                label: _labels[i],
                count: counts[i],
                selected: selected == i,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final foreground = selected ? brand.onContainer : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count jobs',
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.normal),
        curve: _settleCurve,
        decoration: BoxDecoration(
          color: selected ? colors.surfaceLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(context.radii.pill),
          border: Border.all(
            color: selected ? colors.outlineVariant : Colors.transparent,
          ),
          boxShadow: selected ? context.shadows.buttonSubtle : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: context.texts.labelLarge?.copyWith(
                      fontSize: 12.5,
                      letterSpacing: -0.1,
                      color: selected
                          ? brand.onContainer
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 20,
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: context.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? brand.container
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(context.radii.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: _numeric(
                      context.texts.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueDeck extends StatelessWidget {
  const _QueueDeck({required this.behind, required this.frontCard});

  final List<PreviewJob> behind;
  final Widget frontCard;

  static const double _peek = 32;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cardHeight = math
            .max(box.maxHeight - _peek * behind.length, 0)
            .toDouble();

        return Stack(
          children: [
            for (var i = 0; i < behind.length; i += 1)
              _peeked(
                context: context,
                job: behind[behind.length - 1 - i],
                top: i * _peek,
                inset: context.spacing.sm * (behind.length - i),
                scale: 1 - 0.03 * (behind.length - i),
                cardHeight: cardHeight,
                label: i == behind.length - 1 ? 'NEXT' : 'THEN',
              ),
            Positioned(
              top: _peek * behind.length,
              left: 0,
              right: 0,
              height: cardHeight,
              child: frontCard,
            ),
          ],
        );
      },
    );
  }

  Widget _peeked({
    required BuildContext context,
    required PreviewJob job,
    required double top,
    required double inset,
    required double scale,
    required double cardHeight,
    required String label,
  }) {
    return Positioned(
      top: top,
      left: inset,
      right: inset,
      height: cardHeight,
      child: ExcludeSemantics(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              color: top == 0
                  ? context.colors.surfaceContainerHigh
                  : context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(context.radii.xl),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            // Align the row to the top edge: the rest of this card is covered by
            // the card in front of it, so only the peek strip may carry content.
            alignment: AlignmentDirectional.topStart,
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.gutter,
              context.spacing.xs + 2,
              context.spacing.gutter,
              0,
            ),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  Text(
                    label,
                    style: _eyebrowStyle(
                      context,
                      context.colors.onSurfaceVariant,
                    ).copyWith(letterSpacing: 0.9),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Text(
                      job.vehicle,
                      maxLines: 1,
                      style: _metaStyle(context).copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Text(
                    job.when,
                    style: _numeric(
                      _metaStyle(context)
                          .copyWith(color: context.colors.onSurfaceVariant),
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

class _QueueJobCard extends StatelessWidget {
  const _QueueJobCard({required this.job});

  final PreviewJob job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final tone = job.overdue
        ? StatusTone.danger
        : job.status == 'In progress'
        ? StatusTone.success
        : StatusTone.neutral;
    final nextSection = previewSections
        .where((s) => s.next != null)
        .firstOrNull;
    final nextItem = nextSection?.next;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: context.shadows.floating,
      ),
      padding: EdgeInsets.all(context.spacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(
                label: job.overdue ? 'Overdue' : job.status,
                tone: tone,
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: context.spacing.xs),
              Text(
                job.when,
                style: _numeric(
                  _metaStyle(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.lg),
          Text(
            job.vehicle,
            style: context.texts.headlineMedium?.copyWith(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Row(
            children: [
              _Plate(text: job.plate),
              SizedBox(width: context.spacing.sm),
              Flexible(
                child: Text(
                  job.customer,
                  maxLines: 1,
                  style: _metaStyle(context),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.gutter),
          if (nextItem != null && job.current)
            Container(
              padding: EdgeInsets.all(context.spacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(context.radii.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.playlist_play_rounded,
                    size: context.sizing.iconMd,
                    color: brand.ink,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXT UP',
                          style: _eyebrowStyle(
                            context,
                            colors.onSurfaceVariant,
                          ).copyWith(letterSpacing: 0.8),
                        ),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          '${nextItem.number}. ${nextItem.label}',
                          maxLines: 1,
                          style: context.texts.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: context.sizing.iconMd,
                  color: colors.onSurfaceVariant,
                ),
                SizedBox(width: context.spacing.sm),
                Text(
                  '${previewSections.length} sections · ${job.total} items',
                  style: _metaStyle(context),
                ),
              ],
            ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${job.done} of ${job.total} items',
                style: _numeric(
                  context.texts.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(job.done / job.total * 100).round()}%',
                style: _numeric(
                  _metaStyle(context)
                      .copyWith(fontWeight: FontWeight.w700, color: brand.ink),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.pill),
            child: Container(
              height: 6,
              color: colors.surfaceContainerHighest,
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: (job.done / job.total).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: brand.ink,
                    borderRadius: BorderRadius.circular(context.radii.pill),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            job.reference,
            style: _numeric(
              _metaStyle(context).copyWith(
                fontSize: 11.5,
                letterSpacing: 0.2,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// JOB PIECES
// -----------------------------------------------------------------------------

class _JobHeader extends StatelessWidget {
  const _JobHeader({
    required this.reference,
    required this.plate,
    required this.vehicle,
    required this.onBack,
    required this.onSections,
  });

  final String reference;
  final String plate;
  final String vehicle;
  final VoidCallback onBack;
  final VoidCallback onSections;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Back to jobs',
          onPressed: onBack,
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$reference · $plate',
                maxLines: 1,
                style: _eyebrowStyle(context, context.colors.onSurfaceVariant),
              ),
              SizedBox(height: context.spacing.xxs),
              Text(
                vehicle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.spacing.sm),
        _RoundIconButton(
          icon: Icons.view_agenda_outlined,
          label: 'Job sections',
          onPressed: onSections,
        ),
      ],
    );
  }
}

class _JobMetaRow extends StatelessWidget {
  const _JobMetaRow({
    required this.done,
    required this.total,
    required this.section,
    required this.doneInSection,
    required this.onSections,
  });

  final int done;
  final int total;
  final PreviewSection section;
  final int doneInSection;
  final VoidCallback onSections;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shortName = section.name.split(',').first.trim();

    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$done',
                style: _numeric(
                  context.texts.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              TextSpan(
                text: ' of $total items',
                style: _metaStyle(context)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label:
              'Change section. $shortName, $doneInSection of ${section.total} items answered.',
          child: Material(
            color: colors.surfaceLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radii.pill),
              side: BorderSide(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onSections,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: context.spacing.md,
                  vertical: context.spacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shortName,
                      style: context.texts.labelLarge?.copyWith(
                        fontSize: 12.5,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(width: context.spacing.xs),
                    Text(
                      '· $doneInSection of ${section.total}',
                      style: _numeric(
                        _metaStyle(context).copyWith(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacing.xxs),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.items,
    required this.currentIndex,
    required this.resultOf,
    required this.done,
    required this.total,
  });

  final List<_FlatItem> items;
  final int currentIndex;
  final String? Function(PreviewItem) resultOf;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;

    return Semantics(
      label: '$done of $total items answered',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            const gap = 3.0;
            const sectionGap = 8.0;
            var gaps = 0.0;
            for (var i = 1; i < items.length; i += 1) {
              gaps += items[i].sectionIndex == items[i - 1].sectionIndex
                  ? gap
                  : sectionGap;
            }
            final dotWidth = math.max(
              (box.maxWidth - gaps) / items.length,
              0.0,
            );

            return SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i += 1) ...[
                    if (i > 0)
                      SizedBox(
                        width:
                            items[i].sectionIndex == items[i - 1].sectionIndex
                            ? gap
                            : sectionGap,
                      ),
                    SizedBox(
                      width: dotWidth,
                      height: 12,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: dotWidth,
                          height: i == currentIndex ? 11 : 6,
                          decoration: BoxDecoration(
                            // Green = answered, neutral = where you are now,
                            // pale = still to come. The count above carries the
                            // exact number so this is never colour-only.
                            color: resultOf(items[i].item) != null
                                ? brand.ink
                                : i == currentIndex
                                ? colors.onSurface
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              context.radii.pill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.position,
    required this.total,
    required this.result,
    required this.next,
    required this.onAddPhoto,
  });

  final PreviewItem item;
  final int position;
  final int total;
  final String? result;
  final PreviewItem? next;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resultTone = result == 'Pass'
        ? StatusTone.success
        : result == 'Fail'
        ? StatusTone.danger
        : StatusTone.warning;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: context.shadows.floating,
      ),
      padding: EdgeInsets.all(context.spacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'ITEM $position OF $total',
                style: _numeric(
                  _eyebrowStyle(context, colors.onSurfaceVariant),
                ),
              ),
              const Spacer(),
              if (result != null) _Badge(label: result!, tone: resultTone),
            ],
          ),
          if (item.photo)
            SizedBox(height: context.spacing.xl)
          else
            const Spacer(flex: 2),
          Text(
            item.label,
            style: context.texts.headlineMedium?.copyWith(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            item.instruction,
            style: context.texts.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (item.photo) ...[
            SizedBox(height: context.spacing.gutter),
            Expanded(child: _PhotoEvidence(onTap: onAddPhoto)),
          ] else
            const Spacer(flex: 3),
          SizedBox(height: context.spacing.md),
          if (next != null)
            Row(
              children: [
                Text(
                  'NEXT',
                  style: _eyebrowStyle(context, colors.onSurfaceVariant),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Text(
                    '${next!.number}. ${next!.label}',
                    maxLines: 1,
                    style: _metaStyle(context)
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          SizedBox(height: context.spacing.md),
          Container(height: 1, color: colors.outlineVariant),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              if (item.safety)
                const _Badge(
                  label: 'Safety critical',
                  tone: StatusTone.critical,
                  icon: Icons.dangerous_outlined,
                ),
              if (item.photo)
                const _Badge(
                  label: 'Photo required',
                  tone: StatusTone.info,
                  icon: Icons.photo_camera_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoEvidence extends StatelessWidget {
  const _PhotoEvidence({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Photo evidence. No photo attached. Add a photo.',
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(context.spacing.lg),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 22,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(
                    'PHOTO EVIDENCE',
                    style: _eyebrowStyle(
                      context,
                      colors.onSurfaceVariant,
                    ).copyWith(letterSpacing: 0.8),
                  ),
                  SizedBox(height: context.spacing.xs + 2),
                  Text(
                    'No photo attached',
                    style: context.texts.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
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

class _NextCardSurface extends StatelessWidget {
  const _NextCardSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: context.colors.outlineVariant),
      ),
    );
  }
}

class _SwipeReveal extends StatelessWidget {
  const _SwipeReveal({
    required this.tone,
    required this.label,
    required this.icon,
    required this.alignment,
    required this.radius,
  });

  final StatusTone tone;
  final String label;
  final IconData icon;
  final AlignmentDirectional alignment;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);

    return Container(
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: pair.foreground.withValues(alpha: 0.2)),
      ),
      alignment: alignment,
      padding: EdgeInsetsDirectional.symmetric(horizontal: context.spacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: pair.foreground),
          SizedBox(width: context.spacing.sm),
          Text(
            label,
            style: context.texts.headlineSmall?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerDock extends StatelessWidget {
  const _AnswerDock({
    required this.item,
    required this.onPass,
    required this.onAdvisory,
    required this.onFail,
    required this.onPhoto,
    required this.onNext,
  });

  final PreviewItem item;
  final VoidCallback onPass;
  final VoidCallback onAdvisory;
  final VoidCallback onFail;
  final VoidCallback onPhoto;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(context.radii.card),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: context.shadows.floating,
      ),
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.swipe_rounded,
                size: context.sizing.iconSm,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Text(
                  'Swipe the card, or tap an answer',
                  style: _metaStyle(context).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  label: 'Add photo',
                  icon: Icons.photo_camera_outlined,
                  onPressed: onPhoto,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              SizedBox(
                width: 96,
                child: _SecondaryAction(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onNext,
                  iconTrailing: true,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Row(
            children: [
              Expanded(
                child: _ResultButton(
                  label: 'Pass',
                  icon: Icons.check_rounded,
                  background: brand.ink,
                  foreground: colors.onPrimary,
                  semanticsLabel: 'Pass item ${item.number}, ${item.label}',
                  onPressed: onPass,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: _ResultButton(
                  label: 'Advisory',
                  icon: Icons.info_outline_rounded,
                  background: context.statusColors.warning.background,
                  foreground: context.statusColors.warning.foreground,
                  semanticsLabel:
                      'Advisory on item ${item.number}, ${item.label}',
                  onPressed: onAdvisory,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: _ResultButton(
                  label: 'Fail',
                  icon: Icons.warning_amber_rounded,
                  background: context.statusColors.danger.background,
                  foreground: context.statusColors.danger.foreground,
                  semanticsLabel: 'Fail item ${item.number}, ${item.label}',
                  onPressed: onFail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_controlRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: foreground),
                  SizedBox(width: context.spacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      style: context.texts.labelLarge?.copyWith(
                        fontSize: 14,
                        color: foreground,
                      ),
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

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconTrailing = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: context.sizing.targetMin,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: colors.surfaceLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_controlRadius),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!iconTrailing) ...[
                    Icon(icon, size: 18, color: colors.onSurface),
                    SizedBox(width: context.spacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      style: context.texts.labelLarge?.copyWith(
                        fontSize: 13.5,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (iconTrailing) ...[
                    SizedBox(width: context.spacing.xxs),
                    Icon(
                      icon,
                      size: 16,
                      color: colors.onSurfaceVariant,
                      textDirection: Directionality.of(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnsweredRail extends StatelessWidget {
  const _AnsweredRail({
    required this.section,
    required this.currentItem,
    required this.resultOf,
  });

  final PreviewSection section;
  final PreviewItem currentItem;
  final String? Function(PreviewItem) resultOf;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final answered = section.items
        .where((item) => resultOf(item) != null)
        .toList(growable: false);
    final remaining = section.items
        .where((item) => resultOf(item) == null)
        .toList(growable: false);
    final fraction = section.total == 0 ? 0.0 : answered.length / section.total;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(context.radii.xl),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: EdgeInsets.all(context.spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'THIS SECTION',
            style: _eyebrowStyle(context, colors.onSurfaceVariant),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            section.name,
            style: context.texts.titleLarge?.copyWith(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            '${answered.length} of ${section.total} items answered',
            style: _numeric(_metaStyle(context)),
          ),
          SizedBox(height: context.spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.pill),
            child: Container(
              height: 4,
              color: colors.surfaceContainerHighest,
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: fraction.clamp(0.0, 1.0),
                heightFactor: 1,
                child: ColoredBox(color: brand.ink),
              ),
            ),
          ),
          SizedBox(height: context.spacing.lg),
          if (answered.isNotEmpty) ...[
            _RailGroupLabel(label: 'ANSWERED', count: answered.length),
            for (var i = 0; i < answered.length; i += 1)
              _RailRow(
                item: answered[i],
                result: resultOf(answered[i]),
                showDivider: i != answered.length - 1,
              ),
          ] else
            Text('No answers yet in this section.', style: _metaStyle(context)),
          if (remaining.isNotEmpty) ...[
            SizedBox(height: context.spacing.lg),
            _RailGroupLabel(label: 'TO ANSWER', count: remaining.length),
            for (var i = 0; i < remaining.length; i += 1)
              _RailRow(
                item: remaining[i],
                result: null,
                isCurrent: remaining[i].number == currentItem.number,
                showDivider: i != remaining.length - 1,
              ),
          ],
        ],
      ),
    );
  }
}

class _RailGroupLabel extends StatelessWidget {
  const _RailGroupLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _eyebrowStyle(context, context.colors.onSurfaceVariant),
            ),
          ),
          Text(
            '$count',
            style: _numeric(
              _metaStyle(context).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.item,
    required this.result,
    required this.showDivider,
    this.isCurrent = false,
  });

  final PreviewItem item;
  final String? result;
  final bool showDivider;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = result == 'Pass'
        ? StatusTone.success
        : result == 'Fail'
        ? StatusTone.danger
        : StatusTone.warning;
    final pair = context.statusColors.forTone(tone);
    final done = result != null;

    return Semantics(
      label: done
          ? 'Item ${item.number}, ${item.label}, $result'
          : 'Item ${item.number}, ${item.label}${isCurrent ? ', current item' : ''}',
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.outlineVariant))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? pair.background : colors.surfaceContainerLow,
                shape: BoxShape.circle,
                border: done ? null : Border.all(color: colors.outlineVariant),
              ),
              child: done
                  ? Icon(
                      result == 'Pass'
                          ? Icons.check_rounded
                          : result == 'Fail'
                          ? Icons.close_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: pair.foreground,
                    )
                  : Text(
                      '${item.number}',
                      style: _numeric(
                        _metaStyle(
                          context,
                        ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Text(
                item.label,
                maxLines: 2,
                style: context.texts.bodyMedium?.copyWith(
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: done ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ),
            if (isCurrent) ...[
              SizedBox(width: context.spacing.xs),
              const _StatusPill(label: 'Now', tone: StatusTone.info),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHEETS
// -----------------------------------------------------------------------------

/// Adds Esc-to-close to the custom sheets. The modal route handles the system
/// back gesture; desktop keyboards need this explicitly.
class _DismissibleSheet extends StatelessWidget {
  const _DismissibleSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _SectionSheet extends StatelessWidget {
  const _SectionSheet({
    required this.currentSectionIndex,
    required this.doneInSection,
    required this.onClose,
    required this.onPick,
  });

  final int currentSectionIndex;
  final int Function(PreviewSection section) doneInSection;
  final VoidCallback onClose;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.74,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.spacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(context.radii.pill),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                context.spacing.xl,
                context.spacing.lg,
                context.spacing.sm,
                context.spacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sections',
                          style: context.texts.headlineSmall?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          'Pick where to work next',
                          style: _metaStyle(context),
                        ),
                      ],
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    label: 'Close sections',
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsetsDirectional.fromSTEB(
                  context.spacing.lg,
                  context.spacing.xs,
                  context.spacing.lg,
                  context.spacing.lg,
                ),
                itemCount: previewSections.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: context.spacing.xs),
                itemBuilder: (context, index) {
                  final section = previewSections[index];
                  final sectionDone = doneInSection(section);
                  final isCurrent = index == currentSectionIndex;

                  return Material(
                    color: isCurrent ? brand.container : Colors.transparent,
                    borderRadius: BorderRadius.circular(context.radii.lg),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onPick(index),
                      child: Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: context.spacing.md,
                          vertical: context.spacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${index + 1}',
                                    style: _numeric(
                                      _metaStyle(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? brand.onContainer
                                            : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    section.name,
                                    style: context.texts.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrent
                                          ? brand.onContainer
                                          : colors.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.spacing.sm),
                                Text(
                                  '$sectionDone of ${section.total}',
                                  style: _numeric(
                                    _metaStyle(context).copyWith(
                                      color: isCurrent
                                          ? brand.onContainer
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (isCurrent) ...[
                                  SizedBox(width: context.spacing.sm),
                                  const _StatusPill(
                                    label: 'Here',
                                    tone: StatusTone.info,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: context.spacing.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                context.radii.pill,
                              ),
                              child: Container(
                                height: 3,
                                color: isCurrent
                                    ? brand.container
                                    : colors.surfaceContainerHighest,
                                child: FractionallySizedBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  widthFactor: section.total == 0
                                      ? 0
                                      : (sectionDone / section.total).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                  heightFactor: 1,
                                  child: ColoredBox(color: brand.ink),
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _PreviewNoteSheet extends StatelessWidget {
  const _PreviewNoteSheet({
    required this.title,
    required this.body,
    required this.onClose,
  });

  final String title;
  final String body;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 20,
                  color: context.brand.ink,
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: context.texts.headlineSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            Text(body, style: _bodyStyle(context)),
            SizedBox(height: context.spacing.lg),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: context.brand.ink,
                  foregroundColor: context.colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_controlRadius),
                  ),
                  textStyle: context.texts.labelLarge,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SMALL SHARED PIECES
// -----------------------------------------------------------------------------

class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final foreground = context.colors.onPrimary;

    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: context.motionDuration(context.motion.fast),
          curve: _settleCurve,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              height: 56,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.gutter,
              ),
              decoration: BoxDecoration(
                color: brand.ink,
                borderRadius: BorderRadius.circular(_controlRadius),
                boxShadow: context.shadows.buttonSubtle,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: context.largeButtonTextStyle.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: foreground,
                      textDirection: Directionality.of(context),
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

class _SettleIn extends StatelessWidget {
  const _SettleIn({required this.duration, required this.child, super.key});

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: _settleCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: Transform.scale(
            scale: 0.985 + (0.015 * value),
            alignment: AlignmentDirectional.center,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: SizedBox.square(
          dimension: context.sizing.targetMin,
          child: Material(
            color: colors.surfaceLowest,
            shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Icon(
                icon,
                size: context.sizing.iconMd,
                color: colors.onSurface,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: pair.foreground,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: context.spacing.xs),
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm + 2,
        vertical: context.spacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(context.radii.pill),
        border: Border.all(color: pair.foreground.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == null)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: pair.foreground,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(icon, size: 14, color: pair.foreground),
          SizedBox(width: context.spacing.xs + 2),
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              fontSize: 11.5,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w700,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm + 2,
        vertical: context.spacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.pill),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Text(
        text,
        style: _numeric(
          context.texts.labelLarge?.copyWith(
            fontSize: 12,
            letterSpacing: 0.4,
            color: context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TYPE
// -----------------------------------------------------------------------------

TextStyle _eyebrowStyle(BuildContext context, Color color) {
  return context.texts.labelSmall!.copyWith(
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: color,
  );
}

TextStyle _metaStyle(BuildContext context) {
  return context.texts.bodySmall!.copyWith(
    fontSize: 12.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: context.colors.onSurfaceVariant,
  );
}

TextStyle _bodyStyle(BuildContext context) {
  return context.texts.bodyMedium!.copyWith(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: context.colors.onSurfaceVariant,
  );
}

/// Tabular figures for anything the technician might compare or count.
TextStyle _numeric(TextStyle? style) {
  return (style ?? const TextStyle()).copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}
