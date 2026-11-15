import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';

import 'package:l10n/l10n.dart';

/// Shared toolbar pattern: search input, filter controls, count summary, actions.
/// Consistent alignment and quiet borders without heavy nested shadows.
class PlatformToolbar extends ConsumerWidget {
  const PlatformToolbar({
    super.key,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.filters = const [],
    this.countLabel,
    this.trailing,
  });

  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> filters;
  final String? countLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final searchField = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: compact ? double.infinity : 320,
          ),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PtTheme.border),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
              decoration: InputDecoration(
                hintText: searchHint ?? strings.tKey(CommonKeys.filterSearch),
                hintStyle: PtTheme.font(
                  13,
                  lineHeight: 18,
                  color: PtTheme.muted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: PtTheme.muted,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: PtTheme.deepGreen,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PtTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (compact)
                    SizedBox(width: double.infinity, child: searchField)
                  else
                    searchField,
                  if (filters.isNotEmpty) ...filters,
                  if (countLabel != null && countLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Text(
                        countLabel!,
                        style: PtTheme.font(
                          12,
                          lineHeight: 16,
                          weight: FontWeight.w500,
                          color: PtTheme.muted,
                        ),
                      ),
                    ),
                  ?trailing,
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
