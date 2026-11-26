import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart' show Membership;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../inspection/fieldwork/fieldwork_ui.dart';
import 'fieldwork/profile_board.dart';

/// The technician's pass: who they are on the one dark identity card, whether
/// their work is safe, the two things they can change, and the way out.
///
/// Behaviour is unchanged: the same session, role, workshop, supported
/// languages, sync queue, `/sync` route, language picker and sign-out confirm.
class TechnicianProfilePage extends ConsumerWidget {
  const TechnicianProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final session = ref.watch(authControllerProvider).value;
    final role = t(TechnicianKeys.roleTechnician);
    final rawName = session?.user.displayName;
    final name = (rawName == null || rawName.trim().isEmpty) ? role : rawName;
    final email = (session?.user.email ?? '').trim();
    final memberships = session?.memberships ?? const <Membership>[];
    final workshop = memberships.isEmpty
        ? ''
        : memberships.first.workshopName.trim();

    final languages = ref.watch(
      supportedLocalesProvider(technicianUiMessageClient),
    );
    final languageSelection = ref.watch(
      languageSelectionProvider(technicianUiMessageClient),
    );
    final activeLanguageName =
        languageSelection.manifest
            ?.languageFor(languageSelection.activeLanguage)
            ?.displayName ??
        '';
    final currentLanguage = activeLanguageName.isNotEmpty
        ? activeLanguageName
        : Localizations.localeOf(context).languageCode.toUpperCase();

    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    final online = ref.watch(connectivityProvider).value ?? true;
    final waiting = sync == null ? 0 : sync.pending + sync.failed;
    final conflicts = sync?.conflicts ?? 0;

    final StatusTone syncTone;
    final String syncDetail;
    final String? syncStatus;
    if (sync == null) {
      // Unknown is not "all synced": no count is invented until the queue
      // answers.
      syncTone = StatusTone.neutral;
      syncDetail = t(TechnicianKeys.technicianSyncQueuedChanges);
      syncStatus = null;
    } else if (conflicts > 0) {
      syncTone = StatusTone.danger;
      syncDetail = t(TechnicianKeys.technicianSyncConflictsCount, {
        'count': conflicts,
      });
      syncStatus = t(TechnicianKeys.technicianSyncStateConflict);
    } else if (waiting > 0) {
      syncTone = StatusTone.warning;
      syncDetail = '$waiting · ${t(TechnicianKeys.technicianSyncPending)}';
      syncStatus = t(TechnicianKeys.technicianSessionSyncPending);
    } else {
      syncTone = StatusTone.success;
      syncDetail = t(TechnicianKeys.technicianAllSynced);
      syncStatus = t(TechnicianKeys.successSynced);
    }

    final language = languages.length > 1
        ? ProfileLanguageData(
            title: t(TechnicianKeys.settingsLanguage),
            detail: currentLanguage,
          )
        : null;
    final offlineNote = !online && waiting > 0
        ? t(TechnicianKeys.technicianOfflineQueued)
        : null;

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: ProfileBoard(
          header: ProfileHeaderData(
            title: t(TechnicianKeys.technicianProfileTitle),
            subtitle: t(TechnicianKeys.technicianProfileSubtitle),
            statusLabel: online
                ? null
                : t(TechnicianKeys.technicianSyncOffline),
          ),
          identity: ProfileIdentityData(
            name: name,
            role: role,
            email: email,
            workshop: workshop,
          ),
          sync: ProfileSyncData(
            title: t(TechnicianKeys.technicianSyncTitle),
            detail: syncDetail,
            statusLabel: syncStatus,
            tone: syncTone,
          ),
          language: language,
          offlineNote: offlineNote,
          signOutLabel: t(TechnicianKeys.signOut),
          footerLabel: '${t(TechnicianKeys.appTitle)} · $role',
          onSync: () => context.push('/sync'),
          onLanguage: language == null ? null : () => _openLanguage(context),
          onSignOut: () => _signOut(context, ref),
        ),
      ),
    );
  }

  Future<void> _openLanguage(BuildContext context) async {
    final t = UiStrings.of(context);
    await showAppBottomSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t(TechnicianKeys.settingsLanguage),
            style: fieldworkText(
              context,
              16,
              weight: FontWeight.w800,
              height: 21,
              tracking: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (sheetContext) => BackendLanguageSelector(
              client: technicianUiMessageClient,
              keyPrefix: 'profile-language',
              onChanged: (_) {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final t = UiStrings.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: t(TechnicianKeys.signOut),
      message: t(TechnicianKeys.technicianSignOutBody),
      confirmLabel: t(TechnicianKeys.signOut),
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
