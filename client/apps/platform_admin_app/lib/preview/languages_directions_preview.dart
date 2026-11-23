// THROWAWAY languages redesign preview — three directions. Sample data only.
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

void main() {
  final q = Uri.base.queryParameters;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: TrFonts.latin, useMaterial3: false),
      home: Directionality(
        textDirection:
            q['rtl'] == '1' ? TextDirection.rtl : TextDirection.ltr,
        child: languagesPreview(q['d'] ?? 'A'),
      ),
    ),
  );
}

/// Public entry for screenshot tests.
Widget languagesPreview(String direction) => _Preview(direction: direction);

abstract final class _P {
  static const ink = Color(0xFF1A1B1F);
  static const muted = Color(0xFF5E5D69);
  static const border = Color(0xFFE9E7ED);
  static const hairline = Color(0xFFEEEAF2);
  static const canvas = Color(0xFFF4F3F8);
  static const surface = Colors.white;
  static const accent = Color(0xFF006C49);
  static const accentSoft = Color(0xFFEAF4EF);
  static const warn = Color(0xFFB7791F);
  static const warnSoft = Color(0xFFFBF3E2);
  static const danger = Color(0xFFE11D48);
}

TextStyle _t(double s, double h, FontWeight w, [Color c = _P.ink]) => TextStyle(
  fontSize: s,
  height: h / s,
  fontWeight: w,
  color: c,
  fontFeatures: const [FontFeature.tabularFigures()],
);

// Sample registry: code, native name, stage 0..3, coverage, missing count.
const _langs = [
  ('en', 'English', 3, 1.00, 0),
  ('es', 'Español', 2, 0.68, 42),
  ('ur', 'اردو', 1, 0.12, 318),
  ('fr', 'Français', 0, 0.00, 0),
];
const _stages = ['Setup', 'Translating', 'Review', 'Live'];

class _Preview extends StatelessWidget {
  const _Preview({required this.direction});
  final String direction;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StyleTile(direction: direction),
                const SizedBox(height: 40),
                switch (direction) {
                  'B' => const _DirectionB(),
                  'C' => const _DirectionC(),
                  _ => const _DirectionA(),
                },
                const SizedBox(height: 24),
                Text(
                  'Sample data — 4 languages across all 4 lifecycle stages · es at 68% · ur at 12%.',
                  style: _t(11, 16, FontWeight.w400, _P.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({required this.direction});
  final String direction;
  @override
  Widget build(BuildContext context) {
    const names = {
      'A': 'A · Pipeline Ledger',
      'B': 'B · Language Cards',
      'C': 'C · Workspace Deck',
    };
    const tags = {
      'A': 'One ledger: stage stepper, coverage meter, one row per language.',
      'B': 'One calm card per language: big coverage number, live state, actions.',
      'C': 'Language rail left; workspace detail (tabs + readiness + publish bar) right.',
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      names[direction] ?? names['A']!,
                      style: _t(22, 28, FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tags[direction] ?? tags['A']!,
                      style: _t(13, 20, FontWeight.w400, _P.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _P.warnSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('SAMPLE',
                    style: _t(10, 13, FontWeight.w800, _P.warn)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _P.border),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _P.accent,
                  borderRadius: BorderRadius.circular(14)),
                child: Text('Add language',
                    style: _t(13, 18, FontWeight.w700, Colors.white)),
              ),
              const SizedBox(width: 10),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _P.accentSoft,
                  borderRadius: BorderRadius.circular(999)),
                child: Text('● 2 live',
                    style: _t(12, 16, FontWeight.w700, _P.accent)),
              ),
              const SizedBox(width: 8),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _P.warnSoft,
                  borderRadius: BorderRadius.circular(999)),
                child: Text('● 1 in review',
                    style: _t(12, 16, FontWeight.w700, _P.warn)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Eyebrow('STAGE STEPPER'),
          const SizedBox(height: 8),
          const _StageStepper(stage: 2),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: _t(11, 14, FontWeight.w700, _P.muted));
}

class _StageStepper extends StatelessWidget {
  const _StageStepper({required this.stage});
  final int stage;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: i <= stage ? _P.accent : _P.border)),
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < stage
                  ? _P.accent
                  : (i == stage ? _P.surface : _P.canvas),
              border: Border.all(
                  color: i <= stage ? _P.accent : _P.border, width: 1.5),
            ),
            child: i < stage
                ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                : (i == stage
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _P.accent))
                    : null),
          ),
        ],
        const SizedBox(width: 10),
        Text(_stages[stage],
            style: _t(12, 16, FontWeight.w700, _P.accent)),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(children: [
          Expanded(
              flex: (value * 100).round(),
              child: Container(color: value >= 1 ? _P.accent : _P.warn)),
          Expanded(
              flex: 100 - (value * 100).round(),
              child: Container(color: _P.border.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------- A · Ledger ---

class _DirectionA extends StatelessWidget {
  const _DirectionA();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('LANGUAGES', style: _t(11, 14, FontWeight.w700, _P.accent)),
        const SizedBox(height: 8),
        Text('Language coverage', style: _t(30, 37, FontWeight.w800)),
        Text('Every language on one ladder, from setup to live.',
            style: _t(13, 20, FontWeight.w400, _P.muted)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _P.border)),
          child: Column(children: [
            for (var i = 0; i < _langs.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: _P.hairline),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_langs[i].$2,
                          style: _t(14.5, 20, FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(_langs[i].$1.toUpperCase(),
                          style: _t(11, 15, FontWeight.w700, _P.muted)),
                      const Spacer(),
                      Text(
                          _langs[i].$4 == 0
                              ? '${(_langs[i].$3 * 100).round()}%'
                              : '${_langs[i].$4} missing',
                          style: _t(13, 18, FontWeight.w800,
                              _langs[i].$3 >= 1 ? _P.accent : _P.warn)),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: _P.muted),
                    ]),
                    const SizedBox(height: 8),
                    _StageStepper(stage: _langs[i].$3.toInt() > 3 ? 3 : _langs[i].$2 == 'English' ? 3 : (_langs[i].$1 == 'es' ? 2 : (_langs[i].$1 == 'ur' ? 1 : 0))),
                    const SizedBox(height: 8),
                    _Meter(value: _langs[i].$3),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ],
    );
  }
}

// ------------------------------------------------------- B · Cards ---

class _DirectionB extends StatelessWidget {
  const _DirectionB();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('LANGUAGES', style: _t(11, 14, FontWeight.w700, _P.accent)),
        const SizedBox(height: 8),
        Text('Language coverage', style: _t(30, 37, FontWeight.w800)),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 2 : 1;
          final w = (c.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final lang in _langs)
                SizedBox(
                  width: w,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _P.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(lang.$2, style: _t(16, 22, FontWeight.w800)),
                          const SizedBox(width: 8),
                          Text(lang.$1.toUpperCase(),
                              style: _t(11, 15, FontWeight.w700, _P.muted)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lang.$3 >= 1
                                  ? _P.accentSoft
                                  : _P.warnSoft,
                              borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              lang.$3 >= 1 ? 'Live' : _stages[lang.$3.toInt().clamp(0, 3) > 3 ? 3 : (lang.$1 == 'es' ? 2 : (lang.$1 == 'ur' ? 1 : 0))],
                              style: _t(11, 15, FontWeight.w700,
                                  lang.$3 >= 1 ? _P.accent : _P.warn)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          '${(_langs[0].$3 * 100).round()}% translated'.replaceFirst(
                              '${(_langs[0].$3 * 100).round()}',
                              '${(lang.$3 * 100).round()}'),
                          style: _t(40, 42, FontWeight.w800)),
                        const SizedBox(height: 6),
                        _Meter(value: lang.$3),
                        const SizedBox(height: 6),
                        Text(
                            lang.$4 == 0
                                ? 'Nothing missing'
                                : '${lang.$4} strings missing',
                            style: _t(12, 17, FontWeight.w400, _P.muted)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Text('Open workspace →',
                              style:
                                  _t(12.5, 17, FontWeight.w700, _P.accent)),
                          const Spacer(),
                          Text('Queue',
                              style:
                                  _t(12.5, 17, FontWeight.w600, _P.muted)),
                        ]),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ------------------------------------------------------- C · Deck ---

class _DirectionC extends StatelessWidget {
  const _DirectionC();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 860;
      final rail = Container(
        width: wide ? 240 : null,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child:
                  Text('LANGUAGES', style: _t(10.5, 14, FontWeight.w800, _P.muted)),
            ),
            for (final lang in _langs)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: lang.$1 == 'es'
                      ? _P.accentSoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.$2,
                            style: _t(13, 18,
                                lang.$1 == 'es'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                lang.$1 == 'es'
                                    ? _P.accent
                                    : _P.ink)),
                        Text('${(lang.$3 * 100).round()}%',
                            style: _t(11, 15, FontWeight.w400, _P.muted)),
                      ],
                    ),
                  ),
                  if (lang.$1 == 'es')
                    Text('68%',
                        style: _t(12, 16, FontWeight.w800, _P.accent)),
                ]),
              ),
          ],
        ),
      );
      final detail = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Español workspace',
                    style: _t(20, 26, FontWeight.w800)),
                Text('68% translated · 42 missing · Review stage',
                    style: _t(12.5, 18, FontWeight.w400, _P.muted)),
              ],
            )),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _P.accent,
                borderRadius: BorderRadius.circular(14)),
              child: Text('Publish',
                  style: _t(13, 18, FontWeight.w700, Colors.white)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _P.border)),
            child: Column(children: [
              for (final tab in [
                ('Overview', '12 / 12 ready', true),
                ('Categories', '34 / 34 ready', true),
                ('Items', '120 / 220 ready', false),
                ('Option sets', '8 / 8 ready', true),
                ('Templates', '3 / 11 ready', false),
              ]) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(
                        child: Text(tab.$1,
                            style: _t(13.5, 19, FontWeight.w600))),
                    Text(tab.$2,
                        style: _t(12, 16, FontWeight.w400, _P.muted)),
                    const SizedBox(width: 6),
                    Icon(
                        tab.$3
                            ? Icons.check_circle_rounded
                            : Icons.timelapse_rounded,
                        size: 16,
                        color: tab.$3 ? _P.accent : _P.warn),
                  ]),
                ),
                const Divider(height: 1, color: _P.hairline),
              ],
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                      child: Text('2 sections need review before publish',
                          style: _t(12.5, 17, FontWeight.w600))),
                  Text('Review all →',
                      style: _t(12.5, 17, FontWeight.w800, _P.accent)),
                ]),
              ),
            ]),
          ),
        ],
      );
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rail,
            const SizedBox(width: 16),
            Expanded(child: detail),
          ]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final lang in _langs) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: lang.$1 == 'es' ? _P.ink : _P.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: lang.$1 == 'es' ? _P.ink : _P.border)),
                  child: Text('${lang.$2} ${(lang.$3 * 100).round()}%',
                      style: _t(12.5, 17, FontWeight.w600,
                          lang.$1 == 'es' ? Colors.white : _P.ink)),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          detail,
        ]);
    });
  }
}
