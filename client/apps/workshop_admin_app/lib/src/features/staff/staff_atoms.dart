import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/labels.dart';

/// Type and emphasis derived from the workshop tokens for the staff ledger.
///
/// No new colours, radii or families: these are the existing scale values
/// applied at ledger sizes so the screen reads as a workspace, not a page of
/// cards. Kept local to the staff feature on purpose (see the design report).
extension StaffLedgerTokens on WorkshopTokens {
  TextStyle get ledgerTitle =>
      sectionTitle.copyWith(fontSize: 22, letterSpacing: -0.2, color: ink);

  TextStyle get railName =>
      sectionTitle.copyWith(fontSize: 19, letterSpacing: -0.1, color: ink);

  TextStyle get rowName => body.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  TextStyle get countFigure => sectionTitle.copyWith(
    fontSize: 22,
    color: accent,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

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
          style: ws.bodyStrong.copyWith(
            color: filled ? ws.onAccent : ws.accent,
            fontSize: size * 0.34,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// Status is always a dot plus its label â€” never colour alone.
String staffStatusLabel(BuildContext context, String status) =>
    memberStatusLabel(AppLocalizations.of(context), status);

String staffRoleLabel(BuildContext context, String role) =>
    memberRoleLabel(AppLocalizations.of(context), role);

Color staffStatusColor(WorkshopTokens ws, String status) => switch (status) {
  'ACTIVE' => ws.success,
  'PENDING' => ws.warning,
  'DISABLED' => ws.danger,
  _ => ws.muted,
};

class StaffStatusDot extends StatelessWidget {
  const StaffStatusDot({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final label = staffStatusLabel(context, status);
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: staffStatusColor(ws, status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The single hairline surface every list and panel on this screen sits in.
class StaffLedgerSurface extends StatelessWidget {
  const StaffLedgerSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

Widget staffHairline(BuildContext context) =>
    Container(height: 1, width: double.infinity, color: context.ws.border);

/// Hover, focus and press in one place so rows, tabs and the create action
/// keep the same interaction feel.
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

/// Skeleton in the shape of the roster: header, tabs and six rows.
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
    final spacing = context.spacing;
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.42,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: StaffLedgerSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.lg,
                spacing.lg,
                spacing.lg,
                0,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inline = constraints.maxWidth >= 520;
                  return Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _bar(context, width: 168, height: 18),
                            const SizedBox(width: 10),
                            _bar(context, width: 26, height: 18),
                          ],
                        ),
                      ),
                      if (inline) ...[
                        _bar(context, width: 240, height: 40),
                        const SizedBox(width: 12),
                        _bar(context, width: 112, height: 46),
                      ] else
                        _bar(context, width: 100, height: 46),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.lg,
                spacing.md,
                spacing.lg,
                spacing.sm,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    _bar(context, width: 72, height: 12),
                    const SizedBox(width: 22),
                  ],
                ],
              ),
            ),
            staffHairline(context),
            for (var i = 0; i < 6; i++) ...[
              if (i > 0) staffHairline(context),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  22,
                  spacing.md,
                  spacing.md,
                  spacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ws.border,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _bar(context, width: 180, height: 12),
                      ),
                    ),
                    _bar(context, width: 82, height: 10),
                    if (MediaQuery.sizeOf(context).width >= 900) ...[
                      const SizedBox(width: 30),
                      _bar(context, width: 64, height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bar(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.ws.border,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
