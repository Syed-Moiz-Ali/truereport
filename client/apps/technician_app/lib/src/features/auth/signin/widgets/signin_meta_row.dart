import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The access + security meta line of "The dock".
///
/// The help label is a catalog string from the owning app ("Contact your
/// workshop admin." on the technician login), not a hardcoded "Get help", so
/// the line reads as one sentence and translates with the rest of the screen.
class SignInMetaRow extends StatelessWidget {
  const SignInMetaRow({
    required this.accessPrompt,
    required this.helpLabel,
    required this.securityLine,
    this.compact = true,
    this.accessKey,
    this.securityKey,
    this.onDark = false,
    super.key,
  });

  final String accessPrompt;
  final String helpLabel;
  final String securityLine;
  final bool compact;
  final Key? accessKey;
  final Key? securityKey;

  /// White text for the dark "Bay Door" sheet.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Fx.text(
      11,
      16,
      FontWeight.w600,
      0.2,
      color: onDark
          ? Colors.white.withValues(alpha: 0.70)
          : scheme.onSurfaceVariant,
    );

    final access = Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(accessPrompt, key: accessKey, maxLines: 2, style: style),
        Text(helpLabel, maxLines: 2, style: style),
      ],
    );
    final security = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FxIcon(
          id: '1_7128',
          width: 10,
          height: 12,
          color: onDark ? Colors.white.withValues(alpha: 0.55) : scheme.outline,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            securityLine,
            key: securityKey,
            maxLines: 2,
            style: style,
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [access, const SizedBox(height: 4), security],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SignInDims.metaMinHeight),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: access,
            ),
          ),
          const SizedBox(width: 24),
          security,
        ],
      ),
    );
  }
}
