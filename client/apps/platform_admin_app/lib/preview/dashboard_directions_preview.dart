// THROWAWAY preview harness — three dashboard directions, deleted after choice.
//
// Renders with the real Plus Jakarta Sans / Noto Sans Arabic fonts and the
// product's accent colours. Sample data only; never shipped.
//
// Web route: /dashboard-directions?d=A|B|C&rtl=1
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

void main() {
  final query = Uri.base.queryParameters;
  final direction = switch (query['d']) {
    'B' => DirectionPreview.oneNumber,
    'C' => DirectionPreview.dossier,
    _ => DirectionPreview.signalRoom,
  };
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: TrFonts.latin, useMaterial3: false),
      home: Directionality(
        textDirection: query['rtl'] == '1'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: ColoredBox(
          color: _Pal.canvas,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                directionStyleTile(direction, rtl: query['rtl'] == '1'),
                const SizedBox(height: 48),
                directionSection(direction, rtl: query['rtl'] == '1'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

enum DirectionPreview { signalRoom, oneNumber, dossier }

String directionName(DirectionPreview d) => switch (d) {
  DirectionPreview.signalRoom => 'A · Signal Room',
  DirectionPreview.oneNumber => 'B · One Number',
  DirectionPreview.dossier => 'C · Dossier & Dock',
};

String directionTagline(DirectionPreview d) => switch (d) {
  DirectionPreview.signalRoom => 'A deep operating slab opens with the verdict, then splits into a work queue and a live feed.',
  DirectionPreview.oneNumber => 'One oversized number owns the page; every other figure becomes a quiet register row beneath it.',
  DirectionPreview.dossier => 'A single dossier surface lists every domain against its meter, with a sticky rail and a command dock.',
};

Widget directionStyleTile(DirectionPreview d, {bool rtl = false}) {
  final s = _S(rtl);
  return Directionality(
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    child: Material(
      type: MaterialType.transparency,
      child: _Frame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directionName(d),
                        style: _t(22, h: 28, w: FontWeight.w800, ls: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        directionTagline(d),
                        style: _t(13, h: 20, c: _Pal.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _Chip(label: s.sample, tone: _Tone.neutral),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: _Pal.border),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final typeColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('TYPE SCALE'),
                    const SizedBox(height: 12),
                    Text(
                      '21',
                      style: _t(64, h: 66, w: FontWeight.w800, ls: -2.4),
                    ),
                    Text(
                      'Hero number · 64 / tabular',
                      style: _t(11, h: 16, c: _Pal.muted, ls: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.pageTitle,
                      style: _t(28, h: 34, w: FontWeight.w800, ls: -0.7),
                    ),
                    Text(
                      'Page title · 28',
                      style: _t(11, h: 16, c: _Pal.muted, ls: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.activityTitle,
                      style: _t(16, h: 22, w: FontWeight.w700, ls: -0.2),
                    ),
                    Text(
                      'Section · 16',
                      style: _t(11, h: 16, c: _Pal.muted, ls: 0.2),
                    ),
                    const SizedBox(height: 10),
                    Text(s.bodySample, style: _t(13.5, h: 21, c: _Pal.inkSoft)),
                    Text(
                      'Body · 13.5',
                      style: _t(11, h: 16, c: _Pal.muted, ls: 0.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ASSIGNED · IN PROGRESS · REVIEW',
                      style: _t(
                        11,
                        h: 14,
                        w: FontWeight.w700,
                        ls: 0.9,
                        c: _Pal.muted,
                      ),
                    ),
                    Text(
                      'Eyebrow · 11 / 0.9',
                      style: _t(11, h: 16, c: _Pal.muted, ls: 0.2),
                    ),
                  ],
                );
                final components = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('PALETTE'),
                    const SizedBox(height: 12),
                    const _SwatchRow(),
                    const SizedBox(height: 24),
                    const _Eyebrow('CONTROLS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _PrimaryButton(label: s.primaryCta, onPressed: () {}),
                        const SizedBox(width: 10),
                        _QuietButton(label: s.quietCta, onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Chip(label: s.healthy, tone: _Tone.good),
                        const SizedBox(width: 8),
                        _Chip(label: s.attentionChip, tone: _Tone.warn),
                        const SizedBox(width: 8),
                        _Chip(label: s.issueChip, tone: _Tone.bad),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _LabelAboveField(),
                    const SizedBox(height: 18),
                    const _Eyebrow('METER / RAIL'),
                    const SizedBox(height: 12),
                    const _Rail(
                      segments: [
                        _Segment('Assigned', 8, _Pal.accent),
                        _Segment('In progress', 9, _Pal.accentMid),
                        _Segment('Review', 4, _Pal.warn),
                      ],
                      showLegend: true,
                    ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      typeColumn,
                      const SizedBox(height: 28),
                      components,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: typeColumn),
                    const SizedBox(width: 40),
                    Expanded(flex: 6, child: components),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget directionSection(DirectionPreview d, {bool rtl = false}) {
  final s = _S(rtl);
  return Directionality(
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    child: Material(
      type: MaterialType.transparency,
      child: switch (d) {
        DirectionPreview.signalRoom => _SignalRoomSection(s: s),
        DirectionPreview.oneNumber => _OneNumberSection(s: s),
        DirectionPreview.dossier => _DossierSection(s: s),
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// A — Signal Room
// ---------------------------------------------------------------------------

class _SignalRoomSection extends StatelessWidget {
  const _SignalRoomSection({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      sample: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Slab(s: s),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final queue = _AttentionLedger(s: s);
              final feed = _ActivityFeed(s: s);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: queue),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: feed),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [queue, const SizedBox(height: 16), feed],
              );
            },
          ),
          const SizedBox(height: 16),
          _CommandStrip(s: s),
        ],
      ),
    );
  }
}

class _Slab extends StatelessWidget {
  const _Slab({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Pal.slabTop, _Pal.slabBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _SlabGridPainter())),
            Positioned(
              top: -90,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _Pal.accent.withValues(alpha: 0.30),
                      _Pal.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 22, 24, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final verdict = _SlabVerdict(s: s);
                  final stats = _SlabStats(s: s, compact: compact);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (compact) ...[
                        verdict,
                        const SizedBox(height: 22),
                        stats,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: verdict),
                            const SizedBox(width: 28),
                            Expanded(flex: 5, child: stats),
                          ],
                        ),
                      const SizedBox(height: 22),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      _Rail(
                        segments: [
                          _Segment(s.inProgress, 9, _Pal.railA),
                          _Segment(s.assigned, 8, _Pal.railB),
                          _Segment(s.review, 4, _Pal.warnOnSlab),
                        ],
                        onSlab: true,
                        showLegend: true,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _PrimaryButton(
                            label: s.reviewQueue,
                            onPressed: () {},
                            light: true,
                          ),
                          _GhostOnSlab(
                            label: s.refresh,
                            icon: Icons.refresh_rounded,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
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

class _SlabVerdict extends StatelessWidget {
  const _SlabVerdict({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _PulseDot(color: _Pal.warnOnSlab),
            const SizedBox(width: 8),
            Text(
              s.eyebrowLive,
              style: _t(
                11,
                h: 14,
                w: FontWeight.w700,
                ls: 1.0,
                c: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          s.verdict,
          style: _t(36, h: 40, w: FontWeight.w800, ls: -1.0, c: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          s.verdictBody,
          style: _t(13, h: 20, c: Colors.white.withValues(alpha: 0.66)),
        ),
      ],
    );
  }
}

class _SlabStats extends StatelessWidget {
  const _SlabStats({required this.s, this.compact = false});

  final _S s;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      (s.workshopsStat, '9', s.workshopsOf),
      (s.reportsStat, '38', s.reportsMeta),
      (s.languagesStat, '2', s.languagesMeta),
    ];
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 46,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: compact ? 8 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        items[i].$2,
                        style: _t(
                          compact ? 34 : 38,
                          h: compact ? 36 : 40,
                          w: FontWeight.w800,
                          ls: -1.2,
                          c: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        items[i].$1,
                        maxLines: 1,
                        style: _t(
                          compact ? 9.5 : 11,
                          h: compact ? 13 : 14,
                          w: FontWeight.w700,
                          ls: compact ? 0.5 : 0.8,
                          c: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        style: _t(
                          11,
                          h: 15,
                          c: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttentionLedger extends StatelessWidget {
  const _AttentionLedger({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _AttentionRowData(
        title: s.attChecklist,
        meta: s.attChecklistMeta,
        count: '2',
        tone: _Tone.bad,
        icon: Icons.report_outlined,
      ),
      _AttentionRowData(
        title: s.attReviews,
        meta: s.attReviewsMeta,
        count: '4',
        tone: _Tone.warn,
        icon: Icons.rate_review_outlined,
      ),
      _AttentionRowData(
        title: s.attLanguage,
        meta: s.attLanguageMeta,
        count: '1',
        tone: _Tone.warn,
        icon: Icons.translate_rounded,
      ),
      _AttentionRowData(
        title: s.attReports,
        meta: s.attReportsMeta,
        count: '6',
        tone: _Tone.info,
        icon: Icons.description_outlined,
      ),
    ];
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurfaceHeader(
            title: s.attentionTitle,
            meta: s.attentionMeta,
            trailing: s.viewAll,
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _Pal.hairline),
            _AttentionRowView(data: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _AttentionRowView extends StatefulWidget {
  const _AttentionRowView({required this.data});

  final _AttentionRowData data;

  @override
  State<_AttentionRowView> createState() => _AttentionRowViewState();
}

class _AttentionRowViewState extends State<_AttentionRowView> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final tone = _toneColor(data.tone);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hover ? _Pal.hover : Colors.transparent,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 14, 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, size: 17, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: _t(13.5, h: 19, w: FontWeight.w600),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.meta,
                    style: _t(11.5, h: 16, c: _Pal.muted),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              data.count,
              style: _t(
                20,
                h: 24,
                w: FontWeight.w800,
                ls: -0.5,
                c: _Pal.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: _Pal.muted.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ActivityData(s.act1, s.act1Meta, '10:04', true),
      _ActivityData(s.act2, s.act2Meta, '14:30', false),
      _ActivityData(s.act3, s.act3Meta, '09:12', false),
      _ActivityData(s.act4, s.act4Meta, '16:45', false),
    ];
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurfaceHeader(
            title: s.activityTitle,
            meta: s.activityMeta,
            trailing: s.auditLog,
          ),
          for (var i = 0; i < rows.length; i++)
            _ActivityRow(
              data: rows[i],
              first: i == 0,
              last: i == rows.length - 1,
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.data,
    required this.first,
    required this.last,
  });

  final _ActivityData data;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 1,
                      color: first ? Colors.transparent : _Pal.hairline,
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.today ? _Pal.accent : _Pal.borderStrong,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1,
                      color: last ? Colors.transparent : _Pal.hairline,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: _t(13, h: 18, w: FontWeight.w600),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data.meta} · ${data.time}',
                      style: _t(11.5, h: 16, c: _Pal.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandStrip extends StatelessWidget {
  const _CommandStrip({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (s.qaWorkshop, Icons.add_business_outlined),
      (s.qaItem, Icons.post_add_outlined),
      (s.qaLanguage, Icons.translate_rounded),
      (s.qaHealth, Icons.health_and_safety_outlined),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _Pal.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Pal.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 4 : 2;
          final cellWidth = constraints.maxWidth / columns;
          return Wrap(
            children: [
              for (var i = 0; i < actions.length; i++)
                SizedBox(
                  width: cellWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        top: i >= columns
                            ? const BorderSide(color: _Pal.hairline)
                            : BorderSide.none,
                        start: i % columns != 0
                            ? const BorderSide(color: _Pal.hairline)
                            : BorderSide.none,
                      ),
                    ),
                    child: _CommandCell(
                      label: actions[i].$1,
                      icon: actions[i].$2,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CommandCell extends StatefulWidget {
  const _CommandCell({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  State<_CommandCell> createState() => _CommandCellState();
}

class _CommandCellState extends State<_CommandCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hover ? _Pal.hover : Colors.transparent,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
        child: Row(
          children: [
            Icon(widget.icon, size: 18, color: _Pal.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: _t(12.5, h: 17, w: FontWeight.w600),
                maxLines: 2,
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              size: 13,
              color: _Pal.muted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B — One Number
// ---------------------------------------------------------------------------

class _OneNumberSection extends StatelessWidget {
  const _OneNumberSection({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      sample: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1040;
          final hero = _OneNumberHero(s: s);
          final register = _DomainRegister(s: s);
          final rail = _AttentionStack(s: s);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EditorialMasthead(s: s),
              const SizedBox(height: 22),
              hero,
              const SizedBox(height: 28),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: register),
                    const SizedBox(width: 28),
                    Expanded(flex: 4, child: rail),
                  ],
                )
              else ...[
                register,
                const SizedBox(height: 20),
                rail,
              ],
              const SizedBox(height: 28),
              _QuietActivity(s: s),
            ],
          );
        },
      ),
    );
  }
}

class _EditorialMasthead extends StatelessWidget {
  const _EditorialMasthead({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.mastheadDate,
                style: _t(
                  11,
                  h: 14,
                  w: FontWeight.w700,
                  ls: 1.0,
                  c: _Pal.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.pageTitle,
                style: _t(30, h: 36, w: FontWeight.w800, ls: -0.9),
              ),
            ],
          ),
        ),
        _QuietButton(label: s.refresh, onPressed: () {}),
      ],
    );
  }
}

class _OneNumberHero extends StatelessWidget {
  const _OneNumberHero({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final number = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '21',
                      style: _t(86, h: 84, w: FontWeight.w800, ls: -4.0)
                          .copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 14,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.activeJobs,
                            style: _t(16, h: 20, w: FontWeight.w700),
                          ),
                          Text(
                            s.acrossWorkshops,
                            style: _t(12, h: 16, c: _Pal.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Rail(
                  segments: [
                    _Segment(s.inProgress, 9, _Pal.accent),
                    _Segment(s.assigned, 8, _Pal.accentMid),
                    _Segment(s.review, 4, _Pal.warn),
                  ],
                  showLegend: true,
                  bare: true,
                ),
              ],
            );
            final stats = Row(
              children: [
                _HeroMicroStat(
                  label: s.reviewsStat,
                  value: '4',
                  tone: _Pal.warn,
                ),
                _HeroMicroStat(label: s.reportsStat, value: '38', tone: null),
                _HeroMicroStat(label: s.languagesStat, value: '2', tone: null),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [number, const SizedBox(height: 26), stats],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 7, child: number),
                const SizedBox(width: 32),
                Expanded(flex: 4, child: stats),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeroMicroStat extends StatelessWidget {
  const _HeroMicroStat({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 2, 14, 2),
        decoration: const BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: _Pal.hairline)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: _t(
                24,
                h: 28,
                w: FontWeight.w800,
                ls: -0.6,
                c: tone ?? _Pal.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 2),
            Text(label, style: _t(11, h: 15, c: _Pal.muted), maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _DomainRegister extends StatelessWidget {
  const _DomainRegister({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DomainData(
        s.domWorkshops,
        s.domWorkshopsMeta,
        '9',
        '/ 12',
        0.75,
        _Pal.accent,
      ),
      _DomainData(s.domJobs, s.domJobsMeta, '21', null, 0.62, _Pal.accent),
      _DomainData(
        s.domReports,
        s.domReportsMeta,
        '38',
        null,
        0.74,
        _Pal.accent,
      ),
      _DomainData(
        s.domChecklist,
        s.domChecklistMeta,
        '42',
        null,
        0.86,
        _Pal.warn,
      ),
      _DomainData(
        s.domLanguages,
        s.domLanguagesMeta,
        '2',
        '/ 4',
        0.50,
        _Pal.accent,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _Eyebrow('DOMAIN REGISTER'),
            const Spacer(),
            Text(s.updatedNow, style: _t(11, h: 15, c: _Pal.muted)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _Pal.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Pal.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _Pal.hairline),
                _DomainRow(data: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DomainRow extends StatefulWidget {
  const _DomainRow({required this.data});

  final _DomainData data;

  @override
  State<_DomainRow> createState() => _DomainRowState();
}

class _DomainRowState extends State<_DomainRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hover ? _Pal.hover : Colors.transparent,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    d.label,
                    style: _t(14, h: 20, w: FontWeight.w700, ls: -0.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.meta,
                    style: _t(11.5, h: 16, c: _Pal.muted),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  _Meter(value: d.progress, color: d.color),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              d.value,
              style: _t(
                24,
                h: 28,
                w: FontWeight.w800,
                ls: -0.7,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            if (d.suffix != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  d.suffix!,
                  style: _t(12, h: 16, w: FontWeight.w600, c: _Pal.muted),
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: _Pal.muted.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionStack extends StatelessWidget {
  const _AttentionStack({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Eyebrow('NEEDS ATTENTION'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _Pal.tintWarn,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Pal.warn.withValues(alpha: 0.22)),
          ),
          child: Column(
            children: [
              for (final row in [
                (s.attChecklist, '2', _Tone.bad),
                (s.attReviews, '4', _Tone.warn),
                (s.attLanguage, '1', _Tone.warn),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _toneColor(row.$3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          row.$1,
                          style: _t(12.5, h: 18, w: FontWeight.w600),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        row.$2,
                        style: _t(13, h: 18, w: FontWeight.w800).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Eyebrow('LANGUAGE SETUP'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Pal.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Pal.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.langName,
                      style: _t(13.5, h: 18, w: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '68%',
                    style: _t(13, h: 18, w: FontWeight.w800, c: _Pal.accent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _Meter(value: 0.68, color: _Pal.accent),
              const SizedBox(height: 8),
              Text(s.langProgressMeta, style: _t(11, h: 15, c: _Pal.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuietActivity extends StatelessWidget {
  const _QuietActivity({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _Eyebrow('RECENT ACTIVITY'),
            const Spacer(),
            Text(
              s.viewAll,
              style: _t(12, h: 16, w: FontWeight.w700, c: _Pal.accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: _Pal.hairline),
              bottom: BorderSide(color: _Pal.hairline),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const Divider(height: 1, color: _Pal.hairline),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(2, 11, 2, 11),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final time = [
                        s.timeToday,
                        s.timeYesterday,
                        s.timeEarlier,
                      ][i];
                      final title = [s.act1, s.act2, s.act3][i];
                      final meta = [s.act1Meta, s.act2Meta, s.act3Meta][i];
                      if (constraints.maxWidth < 540) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(time, style: _t(10.5, h: 15, c: _Pal.muted)),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: _t(13, h: 18, w: FontWeight.w600),
                            ),
                            Text(meta, style: _t(11, h: 16, c: _Pal.muted)),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(
                            width: 88,
                            child: Text(
                              time,
                              style: _t(11, h: 16, c: _Pal.muted),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              style: _t(13, h: 18, w: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              meta,
                              style: _t(11.5, h: 16, c: _Pal.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// C — Dossier & Dock
// ---------------------------------------------------------------------------

class _DossierSection extends StatelessWidget {
  const _DossierSection({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      sample: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final dossier = _DossierSurface(s: s);
              final rail = _DossierRail(s: s);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: dossier),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: rail),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [dossier, const SizedBox(height: 18), rail],
              );
            },
          ),
          const SizedBox(height: 18),
          _Dock(s: s),
        ],
      ),
    );
  }
}

class _DossierSurface extends StatelessWidget {
  const _DossierSurface({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DossierRowData(
        s.domWorkshops,
        s.domWorkshopsMeta,
        '9',
        '/ 12',
        0.75,
        Icons.storefront_outlined,
        _Pal.accent,
      ),
      _DossierRowData(
        s.domJobs,
        s.domJobsMeta,
        '21',
        null,
        0.62,
        Icons.assignment_outlined,
        _Pal.accent,
      ),
      _DossierRowData(
        s.domReports,
        s.domReportsMeta,
        '38',
        null,
        0.74,
        Icons.description_outlined,
        _Pal.accent,
      ),
      _DossierRowData(
        s.domChecklist,
        s.domChecklistMeta,
        '42',
        null,
        0.86,
        Icons.checklist_rtl_rounded,
        _Pal.warn,
      ),
      _DossierRowData(
        s.domLanguages,
        s.domLanguagesMeta,
        '2',
        '/ 4',
        0.50,
        Icons.translate_rounded,
        _Pal.accent,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _Pal.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.dossierTitle,
                        style: _t(16, h: 21, w: FontWeight.w800, ls: -0.2),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.dossierMeta,
                        style: _t(11.5, h: 16, c: _Pal.muted),
                      ),
                    ],
                  ),
                ),
                _Chip(label: s.attentionChip, tone: _Tone.warn),
              ],
            ),
          ),
          const Divider(height: 1, color: _Pal.hairline),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _Pal.hairline),
            _DossierRow(data: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _DossierRow extends StatefulWidget {
  const _DossierRow({required this.data});

  final _DossierRowData data;

  @override
  State<_DossierRow> createState() => _DossierRowState();
}

class _DossierRowState extends State<_DossierRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hover ? _Pal.hover : Colors.transparent,
        padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: d.color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(d.icon, size: 17, color: d.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.label, style: _t(13.5, h: 19, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    d.meta,
                    style: _t(11.5, h: 16, c: _Pal.muted),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: _Meter(value: d.progress, color: d.color),
            ),
            const SizedBox(width: 14),
            Text(
              d.value,
              style: _t(
                22,
                h: 26,
                w: FontWeight.w800,
                ls: -0.6,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            if (d.suffix != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 3),
                child: Text(
                  d.suffix!,
                  style: _t(11, h: 15, w: FontWeight.w600, c: _Pal.muted),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: _Pal.muted.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _DossierRail extends StatelessWidget {
  const _DossierRail({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _PulseDot(color: _Pal.warn),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.railTitle,
                            style: _t(
                              12,
                              h: 16,
                              w: FontWeight.w700,
                              ls: 0.4,
                              c: _Pal.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.verdictShort,
                      style: _t(16, h: 21, w: FontWeight.w800, ls: -0.2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _Pal.hairline),
              for (final row in [
                (s.checkChecklist, s.checkFail, true),
                (s.checkTranslations, s.checkWarn, false),
                (s.checkTemplates, s.checkPass, false),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 14, 10),
                  child: Row(
                    children: [
                      Icon(
                        row.$3
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline,
                        size: 15,
                        color: row.$3 ? _Pal.bad : _Pal.good,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row.$1,
                          style: _t(12, h: 17, w: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(row.$2, style: _t(10.5, h: 14, c: _Pal.muted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.activityTitle,
                        style: _t(13, h: 18, w: FontWeight.w700),
                      ),
                    ),
                    Text(
                      s.viewAll,
                      style: _t(11, h: 15, w: FontWeight.w700, c: _Pal.accent),
                    ),
                  ],
                ),
              ),
              for (final row in [
                (s.act1, s.timeToday),
                (s.act2, s.timeYesterday),
                (s.act3, s.timeEarlier),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsetsDirectional.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _Pal.borderStrong,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          row.$1,
                          style: _t(12, h: 17, w: FontWeight.w500),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(row.$2, style: _t(10.5, h: 15, c: _Pal.muted)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.s});

  final _S s;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (s.qaWorkshop, Icons.add_business_outlined),
      (s.qaItem, Icons.post_add_outlined),
      (s.qaLanguage, Icons.translate_rounded),
      (s.qaHealth, Icons.health_and_safety_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _Pal.slabTop,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 860 ? 4 : 2;
          final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                SizedBox(
                  width: width,
                  child: _DockCell(label: action.$1, icon: action.$2),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DockCell extends StatefulWidget {
  const _DockCell({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  State<_DockCell> createState() => _DockCellState();
}

class _DockCellState extends State<_DockCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: _hover
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 17,
              color: Colors.white.withValues(alpha: 0.86),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                widget.label,
                style: _t(
                  12,
                  h: 16,
                  w: FontWeight.w600,
                  c: Colors.white.withValues(alpha: 0.92),
                ),
                maxLines: 2,
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.sample = false});

  final Widget child;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(constraints.maxWidth < 520 ? 16 : 24),
          decoration: BoxDecoration(
            color: _Pal.canvas,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sample) ...[
                const Row(
                  children: [
                    Spacer(),
                    _Chip(label: 'SAMPLE DATA', tone: _Tone.neutral),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              child,
            ],
          ),
        );
      },
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Pal.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Pal.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SurfaceHeader extends StatelessWidget {
  const _SurfaceHeader({
    required this.title,
    required this.meta,
    required this.trailing,
  });

  final String title;
  final String meta;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: _t(15, h: 20, w: FontWeight.w800, ls: -0.2)),
                const SizedBox(height: 2),
                Text(meta, style: _t(11.5, h: 16, c: _Pal.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailing,
                style: _t(11.5, h: 16, w: FontWeight.w700, c: _Pal.accent),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: _Pal.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.segments,
    required this.showLegend,
    this.onSlab = false,
    this.bare = false,
  });

  final List<_Segment> segments;
  final bool showLegend;
  final bool onSlab;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.count > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final track = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: onSlab ? 9 : 10,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: visible[i].count,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: onSlab
                        ? visible[i].color
                        : visible[i].color.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!bare)
          Container(
            decoration: BoxDecoration(
              color: onSlab ? Colors.white.withValues(alpha: 0.10) : _Pal.track,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(2),
            child: track,
          )
        else
          track,
        if (showLegend) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final segment in visible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: segment.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      segment.label,
                      style: _t(
                        11,
                        h: 15,
                        w: FontWeight.w600,
                        c: onSlab
                            ? Colors.white.withValues(alpha: 0.62)
                            : _Pal.muted,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${segment.count}',
                      style:
                          _t(
                            11,
                            h: 15,
                            w: FontWeight.w800,
                            c: onSlab ? Colors.white : _Pal.ink,
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: filled == 0 ? 1 : filled,
              child: ColoredBox(color: filled == 0 ? _Pal.track : color),
            ),
            Expanded(
              flex: filled == 0 ? 999 : 1000 - filled,
              child: const ColoredBox(color: _Pal.track),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: _t(10.5, h: 14, w: FontWeight.w800, ls: 1.1, c: _Pal.muted),
    );
  }
}

enum _Tone { neutral, good, warn, bad, info }

Color _toneColor(_Tone tone) => switch (tone) {
  _Tone.neutral => _Pal.muted,
  _Tone.good => _Pal.good,
  _Tone.warn => _Pal.warn,
  _Tone.bad => _Pal.bad,
  _Tone.info => _Pal.info,
};

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: _t(11, h: 14, w: FontWeight.w700, c: color),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.light = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool light;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.light ? Colors.white : _Pal.accent;
    final fg = widget.light ? _Pal.slabTop : Colors.white;
    final hover = widget.light ? const Color(0xFFEAF3EF) : _Pal.accentHover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 44,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _hover ? hover : base,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: _t(12.5, h: 16, w: FontWeight.w700, c: fg),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 15, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietButton extends StatefulWidget {
  const _QuietButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_QuietButton> createState() => _QuietButtonState();
}

class _QuietButtonState extends State<_QuietButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover ? _Pal.hover : _Pal.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? _Pal.borderStrong : _Pal.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 15,
                color: _hover ? _Pal.ink : _Pal.muted,
              ),
              const SizedBox(width: 7),
              Text(widget.label, style: _t(12.5, h: 16, w: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostOnSlab extends StatelessWidget {
  const _GhostOnSlab({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 7),
            Text(
              label,
              style: _t(
                12.5,
                h: 16,
                w: FontWeight.w600,
                c: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow();

  @override
  Widget build(BuildContext context) {
    const swatches = [
      ('canvas', _Pal.canvas),
      ('surface', _Pal.surface),
      ('hairline', _Pal.border),
      ('ink', _Pal.ink),
      ('muted', _Pal.muted),
      ('accent', _Pal.accent),
      ('slab', _Pal.slabTop),
      ('warn', _Pal.warn),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final swatch in swatches)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 40,
                decoration: BoxDecoration(
                  color: swatch.$2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _Pal.borderStrong),
                ),
              ),
              const SizedBox(height: 4),
              Text(swatch.$1, style: _t(9.5, h: 13, c: _Pal.muted)),
            ],
          ),
      ],
    );
  }
}

class _LabelAboveField extends StatelessWidget {
  const _LabelAboveField();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workshop name', style: _t(12, h: 16, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _Pal.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Pal.accent, width: 1.4),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: Text('Al Noor Auto Care', style: _t(13, h: 18)),
        ),
        const SizedBox(height: 6),
        Text(
          'Legal name shown on published reports.',
          style: _t(11, h: 15, c: _Pal.muted),
        ),
      ],
    );
  }
}

TextStyle _t(
  double size, {
  double? h,
  FontWeight w = FontWeight.w400,
  double ls = 0,
  Color? c,
}) {
  return Fx.text(size, h ?? size * 1.35, w, ls, color: c ?? _Pal.ink);
}

class _Segment {
  const _Segment(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _AttentionRowData {
  const _AttentionRowData({
    required this.title,
    required this.meta,
    required this.count,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String meta;
  final String count;
  final _Tone tone;
  final IconData icon;
}

class _ActivityData {
  const _ActivityData(this.title, this.meta, this.time, this.today);

  final String title;
  final String meta;
  final String time;
  final bool today;
}

class _DomainData {
  const _DomainData(
    this.label,
    this.meta,
    this.value,
    this.suffix,
    this.progress,
    this.color,
  );

  final String label;
  final String meta;
  final String value;
  final String? suffix;
  final double progress;
  final Color color;
}

class _DossierRowData {
  const _DossierRowData(
    this.label,
    this.meta,
    this.value,
    this.suffix,
    this.progress,
    this.icon,
    this.color,
  );

  final String label;
  final String meta;
  final String value;
  final String? suffix;
  final double progress;
  final IconData icon;
  final Color color;
}

class _SlabGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const pitch = 56.0;
    for (var x = 0.0; x <= size.width; x += pitch) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += pitch) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class _Pal {
  static const canvas = Color(0xFFF4F3F8);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1B1F);
  static const inkSoft = Color(0xFF3B3B45);
  static const muted = Color(0xFF5E5D69);
  static const border = Color(0xFFE9E7ED);
  static const borderStrong = Color(0xFFD5D2DE);
  static const hairline = Color(0xFFEEEDF3);
  static const hover = Color(0xFFF7F6FB);
  static const track = Color(0xFFEDEBF3);
  static const accent = Color(0xFF006C49);
  static const accentMid = Color(0xFF3E8E6E);
  static const accentHover = Color(0xFF00553A);
  static const good = Color(0xFF0F7B57);
  static const warn = Color(0xFFB45309);
  static const warnOnSlab = Color(0xFFF0B26A);
  static const bad = Color(0xFFB3261E);
  static const info = Color(0xFF1D4ED8);
  static const tintWarn = Color(0xFFFFF8EC);
  static const slabTop = Color(0xFF06251B);
  static const slabBottom = Color(0xFF0A3628);
  static const railA = Color(0xFF5FD3A9);
  static const railB = Color(0xFF9BE3C6);
}

class _S {
  const _S(this.rtl);

  final bool rtl;

  String _p(String en, String ar) => rtl ? ar : en;

  String get sample => _p('SAMPLE DATA', 'بيانات تجريبية');
  String get pageTitle => _p('Dashboard', 'لوحة التحكم');
  String get eyebrowLive =>
      _p('PLATFORM OPERATIONS · LIVE', 'عمليات المنصة · مباشر');
  String get verdict => _p('4 items need attention', '٤ عناصر تحتاج الانتباه');
  String get verdictBody => _p(
    'Checklist health and one language setup are blocking publish.',
    'صحة قائمة التحقق وإعداد لغة واحدة تمنع النشر.',
  );
  String get verdictShort => _p('2 checks failing', 'فحصان متعثران');
  String get railTitle => _p('GOVERNANCE RAIL', 'مسارات الحوكمة');
  String get reviewQueue => _p('Review queue', 'مراجعة قائمة العمل');
  String get refresh => _p('Refresh', 'تحديث');
  String get primaryCta => _p('Review queue', 'مراجعة القائمة');
  String get quietCta => _p('Refresh', 'تحديث');
  String get healthy => _p('Healthy', 'سليم');
  String get attentionChip => _p('2 issues', 'مشكلتان');
  String get issueChip => _p('1 blocked', 'واحد متعثر');
  String get bodySample => _p(
    'Reports, configurations and translations across every workshop.',
    'التقارير والإعدادات والترجمات في جميع الورش.',
  );

  String get workshopsStat => _p('WORKSHOPS', 'الورش');
  String get workshopsOf => _p('9 of 12 active', '٩ من ١٢ نشطة');
  String get reportsStat => _p('REPORTS', 'التقارير');
  String get reportsMeta => _p('published this quarter', 'منشورة هذا الربع');
  String get languagesStat => _p('LANGUAGES', 'اللغات');
  String get languagesMeta => _p('2 of 4 live', '٢ من ٤ مباشرة');

  String get attentionTitle => _p('Needs attention', 'يتطلب الانتباه');
  String get attentionMeta =>
      _p('Ordered by operational risk', 'مرتبة حسب المخاطر التشغيلية');
  String get viewAll => _p('View all', 'عرض الكل');
  String get attChecklist => _p(
    'Checklist health issues detected',
    'تم رصد مشاكل في صحة قائمة التحقق',
  );
  String get attChecklistMeta =>
      _p('2 configuration checks are failing', 'فحصان للإعدادات متعثران');
  String get attReviews =>
      _p('Reports awaiting approval', 'تقارير بانتظار الموافقة');
  String get attReviewsMeta => _p(
    '4 inspections completed field work',
    '٤ عمليات فحص أنهت العمل الميداني',
  );
  String get attLanguage =>
      _p('Arabic setup incomplete', 'إعداد اللغة العربية غير مكتمل');
  String get attLanguageMeta =>
      _p('Translating · 68% approved', 'قيد الترجمة · ٦٨٪ معتمد');
  String get attReports =>
      _p('Published jobs without a public link', 'أعمال منشورة دون رابط عام');
  String get attReportsMeta => _p(
    '6 reports are unreachable for customers',
    '٦ تقارير غير متاحة للعملاء',
  );

  String get activityTitle => _p('Recent activity', 'النشاط الأخير');
  String get activityMeta => _p('Every change is attributed', 'كل تغيير موثق');
  String get auditLog => _p('Audit log', 'سجل التدقيق');
  String get act1 => _p('Checklist item published', 'نشر بند قائمة تحقق');
  String get act1Meta => _p('BRK-PAD-01 · A. Rahman', 'BRK-PAD-01 · أ. رحمن');
  String get act2 => _p('Workshop registered', 'تسجيل ورشة');
  String get act2Meta =>
      _p('Al Noor Auto Care · S. Haddad', 'ال نور للسيارات · س. حداد');
  String get act3 => _p('Document type retired', 'إيقاف نوع مستند');
  String get act3Meta =>
      _p('WHEEL_ALIGNMENT · N. Farouk', 'WHEEL_ALIGNMENT · ن. فاروق');
  String get act4 => _p('Language published', 'نشر لغة');
  String get act4Meta =>
      _p('English · Platform Admin', 'الإنجليزية · إدارة المنصة');
  String get timeToday => _p('Today, 10:04', 'اليوم، ١٠:٠٤');
  String get timeYesterday => _p('Yesterday, 14:30', 'أمس، ١٤:٣٠');
  String get timeEarlier => _p('Nov 14, 09:12', '١٤ نوفمبر، ٠٩:١٢');

  String get qaWorkshop => _p('Register a workshop', 'تسجيل ورشة');
  String get qaItem => _p('Add checklist item', 'إضافة بند تحقق');
  String get qaLanguage => _p('Enable a language', 'تمكين لغة');
  String get qaHealth => _p('Open checklist health', 'فتح صحة القائمة');

  String get mastheadDate => _p('THURSDAY · 19 NOVEMBER', 'الخميس · ١٩ نوفمبر');
  String get activeJobs => _p('active jobs', 'عمل نشط');
  String get acrossWorkshops =>
      _p('across 9 active workshops', 'عبر ٩ ورش نشطة');
  String get reviewsStat => _p('PENDING REVIEWS', 'بانتظار المراجعة');
  String get inProgress => _p('In progress', 'قيد التنفيذ');
  String get assigned => _p('Assigned', 'مُسند');
  String get review => _p('Review', 'مراجعة');

  String get domWorkshops => _p('Workshops', 'الورش');
  String get domWorkshopsMeta =>
      _p('9 active · 3 onboarding', '٩ نشطة · ٣ قيد التهيئة');
  String get domJobs => _p('Jobs', 'الأعمال');
  String get domJobsMeta => _p(
    '8 assigned · 9 in progress · 4 review',
    '٨ مسندة · ٩ قيد التنفيذ · ٤ مراجعة',
  );
  String get domReports => _p('Reports', 'التقارير');
  String get domReportsMeta =>
      _p('38 published · 14 this month', '٣٨ منشور · ١٤ هذا الشهر');
  String get domChecklist => _p('Checklist', 'قائمة التحقق');
  String get domChecklistMeta =>
      _p('42 items · 3 templates · 2 issues', '٤٢ بندًا · ٣ قوالب · مشكلتان');
  String get domLanguages => _p('Languages', 'اللغات');
  String get domLanguagesMeta => _p(
    '2 live · 1 translating · 1 draft',
    '٢ مباشرة · ١ قيد الترجمة · ١ مسودة',
  );
  String get updatedNow => _p('Updated just now', 'حُدّث الآن');

  String get dossierTitle => _p('System dossier', 'ملف النظام');
  String get dossierMeta =>
      _p('Every domain, one surface', 'كل مجال في سطح واحد');
  String get langName => _p('Arabic (ar)', 'العربية (ar)');
  String get langProgressMeta =>
      _p('218 of 320 strings approved', '٢١٨ من ٣٢٠ نصًا معتمد');

  String get checkChecklist => _p('Checklist integrity', 'سلامة قائمة التحقق');
  String get checkFail => _p('2 failing', 'متعثران');
  String get checkTranslations => _p('Translation coverage', 'تغطية الترجمة');
  String get checkWarn => _p('68%', '٦٨٪');
  String get checkTemplates => _p('Template publication', 'نشر القوالب');
  String get checkPass => _p('OK', 'سليم');
}
