import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_providers.dart';
import 'settings_cover.dart';
import 'settings_hero.dart';
import 'settings_ledger.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Platform Settings — Profile, Identity Hero (Direction A).
///
/// Dark cover band (account, language, sign out), one giant health count,
/// one continuous settings ledger. The shell strip stays hidden: the cover
/// owns the top edge. Class name and path are unchanged so routing and DI
/// stay untouched.
class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState
    extends ConsumerState<PlatformSettingsScreen> {
  bool _seeding = false;
  String? _toastMessage;
  bool _toastError = false;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _toastMessage = null);
    });
  }

  Future<bool> _confirmSeed(UiMessageStrings strings) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: strings.tKey(CommonKeys.buttonClose),
      barrierColor: Colors.black54,
      transitionDuration: DeckMotion.enter,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _SeedConfirmDialog(
            strings: strings,
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
    );
    return result ?? false;
  }

  Future<void> _seedChecklist() async {
    final strings = ref.read(uiStringsProvider);
    if (!await _confirmSeed(strings)) return;
    setState(() => _seeding = true);
    try {
      final result = await ref.read(platformConfigActionsProvider).seed();
      if (!mounted) return;
      _showToast(
        strings.tArgsKey(PlatformAdminKeys.toastSeedSuccess, <String, Object?>{
          'created': result.created,
          'skipped': result.skipped,
        }),
      );
    } on Object {
      if (!mounted) return;
      _showToast(
        strings.tKey(PlatformAdminKeys.toastSeedFailed),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);

    return PlatformShell(
      currentRoute: '/settings',
      showSearch: false,
      showStrip: false,
      child: PlatformPage(
        maxWidth: 1040,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsCover(),
                const SizedBox(height: 20),
                const SettingsHero(),
                const SizedBox(height: 24),
                SettingsLedger(
                  seedTrailing: DeckButton(
                    label: strings.tKey(
                      PlatformAdminKeys.buttonSeedLoadDefault,
                    ),
                    icon: Icons.cloud_download_outlined,
                    primary: false,
                    loading: _seeding,
                    onPressed: _seeding ? null : _seedChecklist,
                  ),
                ),
              ],
            ),
            if (_toastMessage != null)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: DeckToast(
                    message: _toastMessage!,
                    isError: _toastError,
                    dismissLabel: strings.tKey(CommonKeys.buttonClose),
                    onDismiss: () => setState(() => _toastMessage = null),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeedConfirmDialog extends StatelessWidget {
  const _SeedConfirmDialog({
    required this.strings,
    required this.onCancel,
    required this.onConfirm,
  });

  final UiMessageStrings strings;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Center(
      child: Semantics(
        container: true,
        namesRoute: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(DeckRadius.dialog),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tKey(PlatformAdminKeys.buttonSeedLoadDefault),
                  style: DeckType.style(19, 25, FontWeight.w700, palette.ink),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.tKey(PlatformAdminKeys.dialogSeedConfirm),
                  style: DeckType.style(13, 20, FontWeight.w400, palette.muted),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DeckButton(
                      label: strings.tKey(CommonKeys.buttonCancel),
                      primary: false,
                      onPressed: onCancel,
                    ),
                    const SizedBox(width: 10),
                    DeckButton(
                      label: strings.tKey(CommonKeys.buttonSave),
                      onPressed: onConfirm,
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
}
