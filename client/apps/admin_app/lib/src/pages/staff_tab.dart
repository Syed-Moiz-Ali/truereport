import 'package:admin_app/src/admin_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class StaffTab extends ConsumerWidget {
  const StaffTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffProvider);
    return staff.when(
      loading: () => Padding(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        child: const LoadingSkeleton(lines: 4),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () => ref.invalidate(staffProvider),
            retryLabel: l10n.search,
          ),
        ),
      ),
      data: (members) => ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(
            title: l10n.staffReadOnly,
            subtitle: l10n.staffReadOnlyBody,
          ),
          if (members.isEmpty)
            EmptyState(
              title: l10n.noResults,
              body: l10n.staffReadOnlyBody,
              icon: Icons.groups_outlined,
            )
          else
            ...members.map(
              (member) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
                child: Card(
                  child: AppListTile(
                    leading: CircleAvatar(
                      child: Text(
                        member.displayName.isEmpty
                            ? '?'
                            : member.displayName[0],
                      ),
                    ),
                    title: member.displayName,
                    subtitle: '${member.emailMasked} · ${member.role}',
                    trailing: StatusChip(
                      label: member.status,
                      tone: member.status == 'ACTIVE'
                          ? StatusTone.success
                          : StatusTone.neutral,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
