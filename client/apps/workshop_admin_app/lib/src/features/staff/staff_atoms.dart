import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';

/// One to two letter monogram in a squircle.
///
/// Arabic-script names get a single letter: two joined Arabic letters read as
/// a word fragment rather than initials.
String staffInitials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  final first = parts.first.characters.first;
  if (!RegExp(r'[A-Za-z]').hasMatch(first)) {
    return first;
  }
  if (parts.length == 1) {
    return first.toUpperCase();
  }
  return (first + parts[1].characters.first).toUpperCase();
}

class StaffMonogram extends StatelessWidget {
  const StaffMonogram({
    required this.name,
    this.size = 38,
    this.filled = false,
    super.key,
  });

  final String name;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final style = size >= 60 ? ws.pageTitle : ws.bodyStrong;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? ws.accent : ws.accentSoft,
          borderRadius: BorderRadius.circular(size * 0.36),
        ),
        child: Text(
          staffInitials(name),
          maxLines: 1,
          style: style.copyWith(
            color: filled ? ws.onAccent : ws.accent,
            letterSpacing: size >= 60 ? 1 : 0.4,
          ),
        ),
      ),
    );
  }
}

/// Served account state from the `workshop` status taxonomy.
String staffStatusLabel(WidgetRef ref, String status) =>
    referenceStatusText(ref.watch(statusesProvider('workshop')).value, status);

/// Served role label from `enumsProvider('role')`.
String staffRoleLabel(WidgetRef ref, String role) =>
    referenceStatusText(ref.watch(enumsProvider('role')).value, role);

Color staffStatusColor(WorkshopTokens ws, WorkshopStatusTone tone) {
  final (fg, _) = workshopPillColors(tone, ws);
  return fg;
}

/// Account state: dot + label, never colour alone.
///
/// [pill] draws the same content in the 24 px pill the jobs and templates
/// modules use for lifecycle state; set it off inside dense rows where a plain
/// dot + label reads faster.
class StaffStatusDot extends ConsumerWidget {
  const StaffStatusDot({required this.status, this.pill = false, super.key});

  final String status;
  final bool pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final records = ref.watch(statusesProvider('workshop')).value;
    final label = referenceStatusText(records, status);
    final tone = referenceStatusTone(records, status);
    final color = staffStatusColor(ws, tone);
    final (_, background) = workshopPillColors(tone, ws);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pill
                ? ws.eyebrow.copyWith(color: color)
                : ws.meta.copyWith(color: ws.muted),
          ),
        ),
      ],
    );
    if (!pill) {
      return Semantics(label: label, child: content);
    }
    return Semantics(
      label: label,
      child: Container(
        height: 24,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ws.touchTarget),
        ),
        child: content,
      ),
    );
  }
}

/// The one bordered surface the roster and its states sit in.
class StaffSurface extends StatelessWidget {
  const StaffSurface({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final inset = padding;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardLargeRadius),
        border: Border.all(color: ws.border),
      ),
      child: inset == null ? child : Padding(padding: inset, child: child),
    );
  }
}

/// Round team mark used in the roster's empty state.
class StaffGlyph extends StatelessWidget {
  const StaffGlyph({this.size = 34, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ws.accentSoft, shape: BoxShape.circle),
        child: Icon(Icons.groups_outlined, size: size * 0.46, color: ws.accent),
      ),
    );
  }
}

/// Hover, focus and press in one place so rows keep the same interaction feel.
class StaffTappable extends StatefulWidget {
  const StaffTappable({
    required this.builder,
    required this.onTap,
    required this.semanticLabel,
    this.selected = false,
    this.selectedSemantics = false,
    super.key,
  });

  final Widget Function(BuildContext context, StaffInteraction state) builder;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool selected;
  final bool selectedSemantics;

  @override
  State<StaffTappable> createState() => _StaffTappableState();
}

class StaffInteraction {
  const StaffInteraction({
    required this.hovered,
    required this.focused,
    required this.pressed,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
}

class _StaffTappableState extends State<StaffTappable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _activate() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      selected: widget.selectedSemantics ? widget.selected : null,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: enabled ? _activate : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.995 : 1,
            child: widget.builder(
              context,
              StaffInteraction(
                hovered: _hovered,
                focused: _focused,
                pressed: _pressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton in the shape of the roster table: header band and six lines.
class StaffRosterSkeleton extends StatefulWidget {
  const StaffRosterSkeleton({super.key});

  @override
  State<StaffRosterSkeleton> createState() => _StaffRosterSkeletonState();
}

class _StaffRosterSkeletonState extends State<StaffRosterSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _pulse.duration = const Duration(milliseconds: 1100);
    if (reduceMotion) {
      _pulse.value = 0.55;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.42,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: StaffSurface(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (wide)
                  Container(
                    color: ws.canvas,
                    padding: const EdgeInsetsDirectional.fromSTEB(18, 9, 18, 9),
                    child: Row(
                      children: [
                        Expanded(child: _lead(context, 54, 9)),
                        _slot(context, 110, 34, 9),
                        _slot(context, 140, 44, 9),
                        _slot(context, 220, 58, 9),
                        const SizedBox(width: 22),
                      ],
                    ),
                  ),
                for (var i = 0; i < 6; i++) ...[
                  if (i > 0 || wide) Container(height: 1, color: ws.border),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      13,
                      18,
                      13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ws.border,
                            borderRadius: BorderRadius.circular(ws.chipRadius),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _bar(context, 190, 12),
                              if (!wide) ...[
                                const SizedBox(height: 6),
                                _bar(context, 130, 9),
                              ],
                            ],
                          ),
                        ),
                        if (wide) ...[
                          _slot(context, 110, 70, 10),
                          _slot(context, 140, 62, 22),
                          _slot(context, 220, 140, 10),
                        ] else ...[
                          const SizedBox(width: 10),
                          _bar(context, 72, 22),
                        ],
                        const SizedBox(width: 22),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.ws.border,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );

  Widget _lead(BuildContext context, double width, double height) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: _bar(context, width, height),
  );

  Widget _slot(
    BuildContext context,
    double slot,
    double width,
    double height,
  ) => SizedBox(
    width: slot,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: _bar(context, width, height),
    ),
  );
}
