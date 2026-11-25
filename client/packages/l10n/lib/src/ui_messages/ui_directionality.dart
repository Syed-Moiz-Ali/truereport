import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_message_controller.dart';
import 'ui_message_manifest.dart';

/// Applies the writing direction of the active UI language.
///
/// The direction is a property of the language registry (a manifest key), not of
/// the device: switching to Arabic or Urdu must mirror the whole app even though
/// the Material locale stays English. Wrap the app content inside
/// `MaterialApp.builder` so this wins over the platform direction.
class UiDirectionality extends ConsumerWidget {
  const UiDirectionality({
    required this.client,
    required this.child,
    super.key,
  });

  final String client;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UiMessageState selection = ref.watch(
      languageSelectionProvider(client),
    );
    final UiMessageLanguage? language = selection.manifest?.languageFor(
      selection.activeLanguage,
    );
    final bool rtl = language?.isRtl ?? false;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}
