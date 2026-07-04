// ============================================================
// domain/entities/retention_policy.dart
// ------------------------------------------------------------
// The memory knob for covered (inactive) views. Depth is unbounded — the stack
// is a plain list with no fixed limit — so what keeps a deep stack cheap is the
// per-container policy governing how covered views are held, plus an optional
// numeric cap. Pure Dart.
// ============================================================

/// How a [NavigationPage] treats views that are covered by a newer one.
enum RetentionPolicy {
  /// Covered views stay mounted and painted beneath the active one — full state
  /// retained. The default.
  preserve,

  /// Covered views stay mounted but are not painted (offstage) — state retained,
  /// paint/layout cost skipped.
  suspend,

  /// Covered views are removed from the tree and rebuilt fresh when revealed —
  /// trades state for memory.
  recreate,

  /// Covered views are released entirely and reappear brand-new — the leanest
  /// policy.
  dispose;

  /// Whether this policy keeps the covered view's element (and therefore its
  /// [State]) alive.
  bool get keepsState => this == preserve || this == suspend;

  /// Whether the covered view should remain mounted in the tree at all.
  bool get keepsMounted => this == preserve || this == suspend;
}
