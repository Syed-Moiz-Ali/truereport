// THROWAWAY PREVIEW HARNESS — Gate 3 design exploration for the app shell.
//
// Lives under test/ deliberately: it never ships, it is not imported by
// production code, and the repository's source-scan rules apply to `lib/`
// features only. Hardcoded sample copy is fine here; the real shell reads the backend bundle.
//
// Three structurally different shells, each with the same neutral content so the
// eye judges the chrome and the width it leaves behind.
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shared sample content (a neutral page, not a real screen)
// ---------------------------------------------------------------------------

class _SamplePage extends StatelessWidget {
  const _SamplePage({this.padding = 32});

  final double padding;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marina Workshop'.toUpperCase(),
            style: ws.eyebrow.copyWith(color: ws.muted, letterSpacing: 0.9),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '24',
                style: ws.pageTitle.copyWith(
                  fontSize: 64,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('jobs on the floor', style: ws.sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      '4 are waiting for your decision',
                      style: ws.meta.copyWith(
                        color: ws.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final (label, value) in const [
                ('Draft', '1'),
                ('Scheduled', '4'),
                ('In progress', '5'),
                ('Pending review', '4'),
                ('Published', '3'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value, style: ws.sectionTitle),
                        Text(label, style: ws.meta.copyWith(color: ws.muted)),
                        const SizedBox(height: 6),
                        Container(height: 4, color: ws.border),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Container(height: 1, color: ws.border),
          for (final (title, meta) in const [
            ('Nissan Patrol', 'JOB-10482 · Ahmed Al Mansoori · Review'),
            ('Toyota Land Cruiser', 'JOB-10479 · Sara Khalifa · Review'),
            ('Lexus LX 600', 'JOB-10477 · Omar Haddad · Review'),
            ('Ford F-150', 'JOB-10471 · Nadia Rahman · Review'),
            ('Mercedes G 63', 'JOB-10485 · Khalid Nasser · In progress'),
            ('BMW X5', 'JOB-10480 · Lina Farouk · In progress'),
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ws.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ws.bodyStrong),
                        const SizedBox(height: 2),
                        Text(meta, style: ws.meta.copyWith(color: ws.muted)),
                      ],
                    ),
                  ),
                  Text(
                    'Open',
                    style: ws.meta.copyWith(
                      color: ws.accent,
                      fontWeight: FontWeight.w700,
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

// ---------------------------------------------------------------------------
// Shared chrome atoms
// ---------------------------------------------------------------------------

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ws.accent,
            borderRadius: BorderRadius.circular(ws.chipRadius),
          ),
          child: Text(
            'TR',
            style: ws.meta.copyWith(
              color: ws.onAccent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ),
        if (!compact) ...[
          SizedBox(width: spacing.sm),
          Text('TrueReport', style: ws.bodyStrong.copyWith(color: ws.ink)),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: ws.accentSoft, shape: BoxShape.circle),
      child: Text(
        'LH',
        style: ws.meta.copyWith(color: ws.accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: ws.border),
        borderRadius: BorderRadius.circular(ws.chipRadius),
      ),
      child: Text(
        'EN | ع',
        style: ws.meta.copyWith(color: ws.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Icon(Icons.notifications_none, size: 20, color: ws.ink);
  }
}

// ---------------------------------------------------------------------------
// A — "The spine": icon rail + command bar
// ---------------------------------------------------------------------------

const _sections = <(String, IconData)>[
  ('Overview', Icons.dashboard_outlined),
  ('Jobs', Icons.work_outline),
  ('Staff', Icons.groups_outlined),
  ('Templates', Icons.dashboard_customize_outlined),
  ('Board', Icons.assignment_outlined),
  ('Settings', Icons.settings_outlined),
];

class ShellDirectionASpine extends StatelessWidget {
  const ShellDirectionASpine({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      color: ws.canvas,
      child: LayoutBuilder(
        builder: (context, c) =>
            c.maxWidth >= 700 ? _wide(context) : _phone(context),
      ),
    );
  }

  Widget _wide(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon rail: no text nav anywhere; the label sits under the icon.
        Container(
          width: 84,
          decoration: BoxDecoration(
            color: ws.surface,
            border: BorderDirectional(end: BorderSide(color: ws.border)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.lg),
                child: const _Brand(compact: true),
              ),
              for (final (index, section) in _sections.indexed)
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: 3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: index == 0 ? ws.accentSoft : null,
                    borderRadius: BorderRadius.circular(ws.chipRadius),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        section.$2,
                        size: 18,
                        color: index == 0 ? ws.accent : ws.muted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        section.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ws.meta.copyWith(
                          fontSize: 10,
                          color: index == 0 ? ws.accent : ws.muted,
                          fontWeight: index == 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: spacing.lg),
                child: const _Avatar(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 56,
                padding: EdgeInsets.symmetric(horizontal: spacing.xl),
                decoration: BoxDecoration(
                  color: ws.surface,
                  border: BorderDirectional(
                    bottom: BorderSide(color: ws.border),
                  ),
                ),
                child: Row(
                  children: [
                    Text('Marina Workshop', style: ws.bodyStrong),
                    SizedBox(width: spacing.sm),
                    Text('/', style: ws.meta.copyWith(color: ws.border)),
                    SizedBox(width: spacing.sm),
                    Text(
                      'Overview',
                      style: ws.bodyStrong.copyWith(color: ws.accent),
                    ),
                    SizedBox(width: spacing.xxl),
                    Expanded(
                      child: Container(
                        height: 34,
                        padding: EdgeInsets.symmetric(horizontal: spacing.md),
                        decoration: BoxDecoration(
                          color: ws.canvas,
                          border: Border.all(color: ws.border),
                          borderRadius: BorderRadius.circular(ws.controlRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 16, color: ws.muted),
                            SizedBox(width: spacing.sm),
                            Text(
                              'Find a job, plate or customer',
                              style: ws.meta.copyWith(color: ws.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.lg),
                    const _LangToggle(),
                    SizedBox(width: spacing.md),
                    const _Bell(),
                  ],
                ),
              ),
              const Expanded(
                child: SingleChildScrollView(child: _SamplePage(padding: 32)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phone(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      children: [
        Container(
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          decoration: BoxDecoration(
            color: ws.surface,
            border: BorderDirectional(bottom: BorderSide(color: ws.border)),
          ),
          child: Row(
            children: [
              const _Brand(compact: true),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  'Marina Workshop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.bodyStrong,
                ),
              ),
              const _Bell(),
              SizedBox(width: spacing.md),
              const _Avatar(),
            ],
          ),
        ),
        const Expanded(
          child: SingleChildScrollView(child: _SamplePage(padding: 16)),
        ),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: ws.surface,
            border: BorderDirectional(top: BorderSide(color: ws.border)),
          ),
          child: Row(
            children: [
              for (final (index, section) in _sections.indexed)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        section.$2,
                        size: 18,
                        color: index == 0 ? ws.accent : ws.muted,
                      ),
                      Text(
                        section.$1,
                        maxLines: 1,
                        style: ws.meta.copyWith(
                          fontSize: 9.5,
                          color: index == 0 ? ws.accent : ws.muted,
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// B — "The ledger": horizontal tabs, no sidebar
// ---------------------------------------------------------------------------

class ShellDirectionBLedger extends StatelessWidget {
  const ShellDirectionBLedger({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      color: ws.canvas,
      child: LayoutBuilder(
        builder: (context, c) =>
            c.maxWidth >= 900 ? _wide(context) : _phone(context),
      ),
    );
  }

  Widget _wide(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      children: [
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: spacing.xl),
          decoration: BoxDecoration(
            color: ws.surface,
            border: BorderDirectional(bottom: BorderSide(color: ws.border)),
          ),
          child: Row(
            children: [
              const _Brand(),
              SizedBox(width: spacing.lg),
              Container(width: 1, height: 22, color: ws.border),
              SizedBox(width: spacing.lg),
              // The section tabs ARE the navigation: no persistent side chrome.
              for (final (index, section) in _sections.indexed)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: spacing.xs),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: index == 0 ? ws.ink : null,
                      borderRadius: BorderRadius.circular(ws.chipRadius),
                    ),
                    child: Text(
                      section.$1,
                      style: ws.bodyStrong.copyWith(
                        color: index == 0 ? ws.onAccent : ws.muted,
                        fontWeight: index == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Text('Marina Workshop', style: ws.meta.copyWith(color: ws.muted)),
              SizedBox(width: spacing.lg),
              const _LangToggle(),
              SizedBox(width: spacing.md),
              const _Bell(),
              SizedBox(width: spacing.md),
              const _Avatar(),
            ],
          ),
        ),
        const Expanded(
          child: SingleChildScrollView(child: _SamplePage(padding: 40)),
        ),
      ],
    );
  }

  Widget _phone(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      children: [
        Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          decoration: BoxDecoration(
            color: ws.surface,
            border: BorderDirectional(bottom: BorderSide(color: ws.border)),
          ),
          child: Row(
            children: [
              const _Brand(compact: true),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  'Marina Workshop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
              const _LangToggle(),
              SizedBox(width: spacing.sm),
              const _Avatar(),
            ],
          ),
        ),
        // Tabs scroll horizontally; the current one stays visible.
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: ws.surface,
            border: BorderDirectional(bottom: BorderSide(color: ws.border)),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            children: [
              for (final (index, section) in _sections.indexed)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: spacing.md, top: 6),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: index == 0 ? ws.ink : null,
                      borderRadius: BorderRadius.circular(ws.chipRadius),
                    ),
                    child: Text(
                      section.$1,
                      style: ws.meta.copyWith(
                        color: index == 0 ? ws.onAccent : ws.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Expanded(
          child: SingleChildScrollView(child: _SamplePage(padding: 16)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// C — "The dock": content-first, navigation floats at the bottom
// ---------------------------------------------------------------------------

class ShellDirectionCDock extends StatelessWidget {
  const ShellDirectionCDock({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      color: ws.canvas,
      child: LayoutBuilder(
        builder: (context, c) =>
            c.maxWidth >= 900 ? _wide(context) : _phone(context, c.maxWidth),
      ),
    );
  }

  Widget _wide(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Stack(
      children: [
        Column(
          children: [
            Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: spacing.xl),
              decoration: BoxDecoration(
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Row(
                children: [
                  const _Brand(),
                  SizedBox(width: spacing.md),
                  Text(
                    'Marina Workshop',
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                  const Spacer(),
                  const _LangToggle(),
                  SizedBox(width: spacing.lg),
                  const _Bell(),
                  SizedBox(width: spacing.md),
                  const _Avatar(),
                ],
              ),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 96),
                child: _SamplePage(padding: 40),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: ws.surface,
                border: Border.all(color: ws.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, section) in _sections.indexed)
                    Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(
                        horizontal: index == 0 ? spacing.lg : spacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: index == 0 ? ws.accent : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section.$2,
                            size: 18,
                            color: index == 0 ? ws.onAccent : ws.muted,
                          ),
                          // Only the active item shows its name.
                          if (index == 0) ...[
                            SizedBox(width: spacing.sm),
                            Text(
                              section.$1,
                              style: ws.bodyStrong.copyWith(color: ws.onAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _phone(BuildContext context, double width) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Stack(
      children: [
        Column(
          children: [
            Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Row(
                children: [
                  const _Brand(compact: true),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      'Marina Workshop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ),
                  const _LangToggle(),
                  SizedBox(width: spacing.sm),
                  const _Avatar(),
                ],
              ),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 88),
                child: _SamplePage(padding: 16),
              ),
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Container(
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ws.surface,
              border: Border.all(color: ws.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final (index, section) in _sections.indexed)
                  Expanded(
                    flex: index == 0 ? 2 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: index == 0 ? ws.accent : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            section.$2,
                            size: 17,
                            color: index == 0 ? ws.onAccent : ws.muted,
                          ),
                          if (index == 0) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                section.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ws.meta.copyWith(
                                  color: ws.onAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Style tiles
// ---------------------------------------------------------------------------

class ShellDirectionTile extends StatelessWidget {
  const ShellDirectionTile({
    required this.letter,
    required this.name,
    required this.note,
    super.key,
  });

  final String letter;
  final String name;
  final String note;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      color: ws.canvas,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIRECTION $letter · ${name.toUpperCase()}',
                  style: ws.eyebrow.copyWith(
                    color: ws.muted,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Shell', style: ws.pageTitle.copyWith(fontSize: 44)),
                const SizedBox(height: 6),
                Text(note, style: ws.body.copyWith(color: ws.muted)),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ws.accent,
                        borderRadius: BorderRadius.circular(ws.chipRadius),
                      ),
                      child: Text(
                        'Overview',
                        style: ws.meta.copyWith(color: ws.onAccent),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: ws.border),
                        borderRadius: BorderRadius.circular(ws.chipRadius),
                      ),
                      child: Text('Jobs', style: ws.meta),
                    ),
                    SizedBox(width: spacing.sm),
                    Text('…', style: ws.meta.copyWith(color: ws.muted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: Container(
              padding: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                color: ws.surface,
                border: Border.all(color: ws.border),
                borderRadius: BorderRadius.circular(ws.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PALETTE', style: ws.eyebrow.copyWith(color: ws.muted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final c in <Color>[
                        ws.ink,
                        ws.muted,
                        ws.accent,
                        ws.warning,
                        ws.success,
                        ws.danger,
                      ])
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('TYPE', style: ws.eyebrow.copyWith(color: ws.muted)),
                  const SizedBox(height: 6),
                  Text('Section 19 / 26', style: ws.sectionTitle),
                  Text('Body 14 / 21', style: ws.body),
                  Text('Meta 12.5 / 18', style: ws.meta),
                  const Spacer(),
                  Text(
                    'One accent, hairlines, no shadows',
                    style: ws.meta.copyWith(color: ws.muted),
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
