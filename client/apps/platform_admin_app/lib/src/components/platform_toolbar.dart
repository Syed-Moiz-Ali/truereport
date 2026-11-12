import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../platform_theme.dart';

/// Shared toolbar pattern: search field, filter controls, count summary.
/// Compact widths wrap with search full-width. No fixed-width controls.
class PlatformToolbar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final searchField = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: compact ? double.infinity : 380,
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: PtTheme.font(14, lineHeight: 20, color: PtTheme.ink),
            decoration: InputDecoration(
              hintText: searchHint ?? l10n?.search ?? 'Search',
              hintStyle: PtTheme.font(14, lineHeight: 20, color: PtTheme.muted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: PtTheme.muted,
              ),
              filled: true,
              fillColor: PtTheme.canvas,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: PtTheme.deepGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (compact)
                    SizedBox(width: double.infinity, child: searchField)
                  else
                    searchField,
                  ...filters,
                  // ignore: use_null_aware_elements
                  if (trailing != null) trailing!,
                ],
              ),
              if (countLabel != null && countLabel!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  countLabel!,
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w600,
                    color: PtTheme.muted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
