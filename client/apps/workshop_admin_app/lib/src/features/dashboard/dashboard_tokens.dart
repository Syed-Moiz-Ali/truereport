import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Dashboard-local shape, motion and type rules.
///
/// **Divergence, flagged on purpose.** The shared [WorkshopTokens] were built
/// with `controlRadius: 10` and `chipRadius: 8`. The house style the dashboard
/// is held to asks for 14 px controls, 999 px status pills and 16 px card
/// surfaces. Those three values live here instead of a mutated theme, so the
/// rest of the app keeps its existing geometry. If the design system adopts the
/// house radii later, delete this class and read them from `context.ws`.
///
/// Colours are **not** redefined: every colour still comes from `context.ws`.
abstract final class DashboardShape {
  static const double card = 16;
  static const double control = 14;
  static const double pill = 999;
  static const double pillHeight = 28;
  static const double controlHeight = 48;
  static const double focusWidth = 2;
}

abstract final class DashboardMotion {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration settle = Duration(milliseconds: 160);
  static const Duration reveal = Duration(milliseconds: 280);
  static const Curve enter = Curves.easeOutCubic;
}

/// The nine served job statuses in lifecycle order.
///
/// Sequence only: labels, tones and colours are served by the reference
/// taxonomy and never hardcoded per status.
// gate-allow: codes
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

int dashboardStatusCount(CleanJobCounts counts, String status) {
  return switch (status) {
    'DRAFT' => counts.draft,
    'SCHEDULED' => counts.scheduled,
    'ASSIGNED' => counts.assigned,
    'IN_PROGRESS' => counts.inProgress,
    'PENDING_REVIEW' => counts.pendingReview,
    'APPROVED' => counts.approved,
    'PUBLISHED' => counts.published,
    'REJECTED' => counts.rejected,
    'CANCELLED' => counts.cancelled,
    _ => 0,
  };
}

/// A status colour from the served tone token, never a local status table.
Color dashboardToneColor(WorkshopStatusTone tone, WorkshopTokens ws) {
  return switch (tone) {
    WorkshopStatusTone.success => ws.success,
    WorkshopStatusTone.warning => ws.warning,
    WorkshopStatusTone.danger => ws.danger,
    WorkshopStatusTone.accent => ws.accent,
    WorkshopStatusTone.neutral => ws.muted,
  };
}

/// Type roles this screen owns. Built from `ws.body` / `ws.pageTitle` so the
/// Latin family and the Arabic/CJK fallbacks survive unchanged.
abstract final class DashboardType {
  /// The floor total. Tabular, near-black, tight; 46 px on desktop, 36 on phone
  /// so it stays a reading figure rather than a poster.
  static TextStyle total(WorkshopTokens ws, {required bool compact}) {
    return ws.pageTitle.copyWith(
      fontSize: compact ? 36 : 46,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: compact ? -1.1 : -1.7,
      color: ws.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// "jobs on the floor" — the total's caption.
  static TextStyle totalCaption(WorkshopTokens ws) {
    return ws.body.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: ws.muted,
    );
  }

  static TextStyle eyebrow(WorkshopTokens ws) {
    return ws.eyebrow.copyWith(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      color: ws.muted,
    );
  }

  static TextStyle decision(WorkshopTokens ws) {
    return ws.body.copyWith(
      fontSize: 14,
      height: 21 / 14,
      fontWeight: FontWeight.w500,
      color: ws.muted,
    );
  }

  /// Status-band label, e.g. "Waiting for you".
  static TextStyle band(WorkshopTokens ws) {
    return ws.body.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: ws.ink,
    );
  }

  /// Card / module title, e.g. "Jobs by status".
  static TextStyle cardTitle(WorkshopTokens ws) {
    return ws.body.copyWith(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      color: ws.ink,
    );
  }

  /// 36 px tabular KPI figure. The page total stays larger at 46.
  static TextStyle tileNumber(WorkshopTokens ws) {
    return ws.pageTitle.copyWith(
      fontSize: 36,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.1,
      color: ws.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Inline link inside a module header ("View all").
  static TextStyle cardLink(WorkshopTokens ws) {
    return ws.meta.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: ws.accent,
    );
  }

  static TextStyle bandMeta(WorkshopTokens ws) {
    return ws.meta.copyWith(color: ws.muted);
  }

  static TextStyle rowTitle(WorkshopTokens ws, {required bool compact}) {
    final size = compact ? 15.5 : 18.0;
    return ws.body.copyWith(
      fontSize: size,
      height: (compact ? 21 : 24) / size,
      fontWeight: FontWeight.w600,
      color: ws.ink,
    );
  }

  static TextStyle meta(WorkshopTokens ws) => ws.meta.copyWith(color: ws.muted);

  static TextStyle rank(WorkshopTokens ws) {
    return ws.meta.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w700,
      color: ws.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle verb(WorkshopTokens ws) {
    return ws.meta.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: ws.accent,
    );
  }

  static TextStyle registerLabel(WorkshopTokens ws) {
    return ws.meta.copyWith(fontSize: 12, color: ws.muted);
  }

  static TextStyle registerCount(WorkshopTokens ws) {
    return ws.meta.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: ws.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle emptyTitle(WorkshopTokens ws) {
    return ws.pageTitle.copyWith(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: ws.ink,
    );
  }
}
