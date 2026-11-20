import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// Scoped error / not-found panel for the member record. Never a full-page
/// generic error: the title and the recovery actions are always named.
class StaffMemberMessage extends StatelessWidget {
  const StaffMemberMessage({
    required this.title,
    required this.body,
    this.onRetry,
    this.onBack,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final t = UiStrings.of(context);
    return SingleChildScrollView(
      padding: ws.pagePadding(MediaQuery.sizeOf(context).width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: spacing.xl),
              const StaffGlyph(size: 52),
              const SizedBox(height: 18),
              Text(title, style: ws.sectionTitle.copyWith(color: ws.ink)),
              const SizedBox(height: 6),
              Text(body, style: ws.body.copyWith(color: ws.muted)),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (onRetry != null)
                    TemplatePillButton(
                      label: t(WorkshopAdminKeys.retryAction),
                      icon: Icons.refresh,
                      variant: TemplatePillVariant.outline,
                      onPressed: onRetry,
                    ),
                  if (onRetry != null && onBack != null)
                    const SizedBox(width: 10),
                  if (onBack != null)
                    TemplatePillButton(
                      label: t(WorkshopAdminKeys.commonBack),
                      variant: TemplatePillVariant.ghost,
                      onPressed: onBack,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton in the shape of the record: identity, state strip, action row and
/// the two columns of cards.
class StaffMemberSkeleton extends StatefulWidget {
  const StaffMemberSkeleton({super.key});

  @override
  State<StaffMemberSkeleton> createState() => _StaffMemberSkeletonState();
}

class _StaffMemberSkeletonState extends State<StaffMemberSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulse.duration = const Duration(milliseconds: 1100);
    if (MediaQuery.disableAnimationsOf(context)) {
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
      child: SingleChildScrollView(
        padding: ws.pagePadding(MediaQuery.sizeOf(context).width),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: ws.border,
                        borderRadius: BorderRadius.circular(ws.cardLargeRadius),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(context, 320, 26),
                          const SizedBox(height: 10),
                          _bar(context, 200, 10),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xl),
                _bar(context, double.infinity, 56),
                SizedBox(height: spacing.lg),
                Row(
                  children: [
                    _bar(context, 160, 42),
                    SizedBox(width: spacing.md),
                    _bar(context, 130, 42),
                  ],
                ),
                SizedBox(height: spacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _bar(context, double.infinity, 220),
                    ),
                    SizedBox(width: spacing.lg),
                    Expanded(
                      flex: 4,
                      child: _bar(context, double.infinity, 260),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.ws.border,
      borderRadius: BorderRadius.circular(context.ws.chipRadius),
    ),
  );
}
