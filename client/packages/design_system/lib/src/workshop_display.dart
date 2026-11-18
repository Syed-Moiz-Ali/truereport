import 'package:flutter/material.dart';

import 'workshop_tokens.dart';

/// Display-scale type for the workshop screens.
///
/// Type construction belongs in the design system: feature code is not allowed
/// to name a font size (`test/source_scan_test.dart`), so any screen that needs
/// a role larger than `WorkshopTokens` provides asks here instead.
///
/// The dashboard's idea (docs/ui_brief.md, direction B) is that the total is the
/// largest object on the page, so it gets a dedicated, width-aware role.
abstract final class WorkshopDisplay {
  /// The dashboard total's size at a given viewport width.
  static double dashboardTotalSize(double width) {
    if (width >= 1200) return 76;
    if (width >= 1024) return 64;
    if (width >= 900) return 56;
    if (width >= 768) return 48;
    return 40;
  }

  /// Optical tracking for [dashboardTotalSize]. Tighter as the figure grows.
  static double dashboardTotalTracking(double width) {
    if (width >= 1200) return -2.4;
    if (width >= 1024) return -2;
    if (width >= 900) return -1.6;
    if (width >= 768) return -1.2;
    return -1;
  }

  /// The total numeral: tabular, near-black, tight.
  static TextStyle dashboardTotal(BuildContext context) {
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    return ws.pageTitle.copyWith(
      fontSize: dashboardTotalSize(width),
      height: 0.95,
      fontWeight: FontWeight.w800,
      letterSpacing: dashboardTotalTracking(width),
      color: ws.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// The empty-workshop headline. Smaller than the total so a zero state never
  /// looks like a number, but larger than a section title so it still leads.
  static TextStyle dashboardEmptyTitle(BuildContext context) {
    final ws = context.ws;
    return ws.pageTitle.copyWith(
      fontSize: 34,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      color: ws.ink,
    );
  }
}
