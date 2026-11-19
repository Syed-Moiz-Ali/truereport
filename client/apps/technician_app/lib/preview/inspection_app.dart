// THROWAWAY preview entrypoint. Deleted after direction approval.
// flutter run -d web-server --web-port 8096 -t lib/preview/inspection_app.dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'inspection_directions.dart';
import 'inspection_kit.dart';

void main() {
  final lang = Uri.base.queryParameters['lang'] ?? 'en';
  final direction = Uri.base.queryParameters['d'] ?? 'a';
  runApp(_InspectionPreview(arabic: lang == 'ar', direction: direction));
}

class _InspectionPreview extends StatefulWidget {
  const _InspectionPreview({required this.arabic, required this.direction});

  final bool arabic;
  final String direction;

  @override
  State<_InspectionPreview> createState() => _InspectionPreviewState();
}

class _InspectionPreviewState extends State<_InspectionPreview> {
  late String _direction = widget.direction;
  late bool _arabic = widget.arabic;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(isArabic: _arabic),
      locale: Locale(_arabic ? 'ar' : 'en'),
      builder: (context, child) => Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: ColoredBox(
          color: context.colors.surfaceContainerLow,
          child: Column(
            children: [
              _Chrome(
                direction: _direction,
                arabic: _arabic,
                onDirection: (value) => setState(() => _direction = value),
                onLang: (value) => setState(() => _arabic = value),
              ),
              Expanded(
                child: switch (_direction) {
                  'b' => const SheetPreview(),
                  'c' => const RoutePreview(),
                  _ => const DeckPreview(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.direction,
    required this.arabic,
    required this.onDirection,
    required this.onLang,
  });

  final String direction;
  final bool arabic;
  final ValueChanged<String> onDirection;
  final ValueChanged<bool> onLang;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 50,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return Row(
            children: [
              Text(
                compact ? 'PREVIEW' : 'TRUE REPORT',
                style: iEyebrow(context),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Text(
                  'Inspection · sample data',
                  style: iMeta(context, color: colors.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              for (final entry in const {
                'a': ('A', 'Deck'),
                'b': ('B', 'Sheet'),
                'c': ('C', 'Route'),
              }.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: _Toggle(
                    label: compact
                        ? entry.key.toUpperCase()
                        : '${entry.key.toUpperCase()} · ${entry.value.$2}',
                    active: direction == entry.key,
                    onTap: () => onDirection(entry.key),
                  ),
                ),
              const SizedBox(width: 10),
              _Toggle(label: 'EN', active: !arabic, onTap: () => onLang(false)),
              _Toggle(label: 'AR', active: arabic, onTap: () => onLang(true)),
            ],
          );
        },
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? context.brand.container : Colors.transparent,
          borderRadius: BorderRadius.circular(IRadii.control),
        ),
        child: Text(
          label,
          style: iMeta(
            context,
            color: active ? context.brand.onContainer : colors.onSurfaceVariant,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
