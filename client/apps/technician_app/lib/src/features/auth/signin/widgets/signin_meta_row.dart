import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The access + security meta line of "The dock".
///
/// "Get help" is deliberately plain text: no channel exists for it yet
/// (data gap G1), and a link that does nothing is worse than a caption.
class SignInMetaRow extends StatelessWidget {
  const SignInMetaRow({
    required this.accessPrompt,
    required this.helpLabel,
    required this.securityLine,
    this.compact = true,
    this.accessKey,
    this.securityKey,
    super.key,
  });

  final String accessPrompt;
  final String helpLabel;
  final String securityLine;
  final bool compact;
  final Key? accessKey;
  final Key? securityKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Fx.text(
      11,
      16,
      FontWeight.w600,
      0.2,
      color: scheme.onSurfaceVariant,
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
        FxIcon(id: '1_7128', width: 10, height: 12, color: scheme.outline),
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
