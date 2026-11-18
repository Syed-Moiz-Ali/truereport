import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// App-local scale for the dashboard rebuild.
///
/// The design-system barrel is write-locked by ACL for this account, so the
/// *breakpoint table* lives here; the display type itself is built by
/// `WorkshopDisplay` in the design system, because feature code is not allowed
/// to name a font size (test/source_scan_test.dart).
///
/// Colours, spacing and radii are **not** redefined: every value still comes
/// from `context.ws` / `context.spacing`.
///
/// Direction B "The floor" (docs/ui_brief.md): the total is the largest object
/// on the page.
@immutable
class DashboardScale {
  const DashboardScale({
    required this.totalSize,
    required this.totalTracking,
    required this.atlasHeight,
    required this.gutter,
    required this.sideBySide,
    required this.verbInline,
  });

  /// Size of the total numeral at this breakpoint.
  final double totalSize;

  /// Optical tracking for [totalSize]. Tighter as the figure grows.
  final double totalTracking;

  /// Height of the horizontal partition bar (0 when the spine is used).
  final double atlasHeight;

  /// Page gutter. Matches `WorkshopTokens.pageGutter` at each breakpoint.
  final double gutter;

  /// Whether the three groups sit in two columns (6/4).
  final bool sideBySide;

  /// Whether a row's verb sits inline with its title.
  final bool verbInline;

  /// Horizontal partition at >= 768; vertical spine below.
  bool get horizontalAtlas => atlasHeight > 0;

  static DashboardScale of(BuildContext context) =>
      byWidth(MediaQuery.sizeOf(context).width);

  static DashboardScale byWidth(double width) {
    if (width >= 1000) {
      return const DashboardScale(
        totalSize: 76,
        totalTracking: -2.4,
        atlasHeight: 64,
        gutter: 40,
        sideBySide: true,
        verbInline: true,
      );
    }
    if (width >= 820) {
      return const DashboardScale(
        totalSize: 64,
        totalTracking: -2,
        atlasHeight: 56,
        gutter: 32,
        sideBySide: true,
        verbInline: true,
      );
    }
    if (width >= 640) {
      return const DashboardScale(
        totalSize: 56,
        totalTracking: -1.6,
        atlasHeight: 48,
        gutter: 32,
        sideBySide: false,
        verbInline: true,
      );
    }
    if (width >= 520) {
      return const DashboardScale(
        totalSize: 48,
        totalTracking: -1.2,
        atlasHeight: 0,
        gutter: 20,
        sideBySide: false,
        verbInline: true,
      );
    }
    return const DashboardScale(
      totalSize: 40,
      totalTracking: -1,
      atlasHeight: 0,
      gutter: 16,
      sideBySide: false,
      verbInline: false,
    );
  }

  /// The dashboard's display numeral style.
  TextStyle totalStyle(BuildContext context) =>
      WorkshopDisplay.dashboardTotal(context);
}

/// Colour for a job status inside the partition.
///
/// Deliberately a *sequence*: the neutral pipeline stages fade into the accent,
/// the decision stage is the only warning colour, and the customer-visible
/// stages are green. Terminal failures are red at two strengths so rejected and
/// cancelled never look identical.
Color dashboardStatusTint(String status, WorkshopTokens ws) {
  switch (status) {
    case 'DRAFT':
      return ws.ink.withValues(alpha: 0.18);
    case 'SCHEDULED':
      return ws.ink.withValues(alpha: 0.32);
    case 'ASSIGNED':
      return ws.accent.withValues(alpha: 0.40);
    case 'IN_PROGRESS':
      return ws.accent;
    case 'PENDING_REVIEW':
      return ws.warning;
    case 'APPROVED':
      return ws.success.withValues(alpha: 0.45);
    case 'PUBLISHED':
      return ws.success;
    case 'REJECTED':
      return ws.danger.withValues(alpha: 0.55);
    case 'CANCELLED':
      return ws.danger.withValues(alpha: 0.25);
    default:
      return ws.muted.withValues(alpha: 0.45);
  }
}

/// Fixed display order of the nine verified statuses
/// (docs/data/dashboard_inventory.md §2a).
const List<String> dashboardStatusOrder = <String>[
  'DRAFT',
  'SCHEDULED',
  'ASSIGNED',
  'IN_PROGRESS',
  'PENDING_REVIEW',
  'APPROVED',
  'PUBLISHED',
  'REJECTED',
  'CANCELLED',
];

/// Badge tone for a clean-job status. Mirrors the app's shared status mapping
/// without importing the job-presentation file used by the queue and detail.
WorkshopStatusTone dashboardStatusTone(String status) => switch (status) {
  'ASSIGNED' || 'IN_PROGRESS' => WorkshopStatusTone.accent,
  'PENDING_REVIEW' => WorkshopStatusTone.warning,
  'APPROVED' || 'PUBLISHED' => WorkshopStatusTone.success,
  'REJECTED' || 'CANCELLED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.neutral,
};
