// ============================================================
// domain/usecases/nav_stack.dart
// ------------------------------------------------------------
// Pure algebra over a list of NavEntry — the stack rules, with no timers,
// events or disposal. Kept separate from the controller so the invariants can
// be reasoned about and unit-tested in isolation. Every operation returns a NEW
// list (immutable-style); nothing here mutates its input. Pure Dart.
// ============================================================

import '../entities/nav_entry.dart';

/// Stack operations as pure functions. Never mutates its arguments.
abstract final class NavStack {
  /// Push [entry] on top.
  static List<NavEntry> push(List<NavEntry> entries, NavEntry entry) =>
      [...entries, entry];

  /// Remove the top entry (no-op on an empty list).
  static List<NavEntry> pop(List<NavEntry> entries) =>
      entries.isEmpty ? entries : entries.sublist(0, entries.length - 1);

  /// Replace the top entry with [entry].
  static List<NavEntry> replaceTop(List<NavEntry> entries, NavEntry entry) =>
      entries.isEmpty ? [entry] : [...entries.sublist(0, entries.length - 1), entry];

  /// Drop every overlay, keeping only the root.
  static List<NavEntry> clearOverlays(List<NavEntry> entries) =>
      entries.where((e) => e.isRoot).toList();

  /// The overlays (everything above the root), in order.
  static List<NavEntry> overlays(List<NavEntry> entries) =>
      entries.where((e) => !e.isRoot).toList();

  /// The top entry, or null.
  static NavEntry? peek(List<NavEntry> entries) =>
      entries.isEmpty ? null : entries.last;

  /// The root entry, or null.
  static NavEntry? root(List<NavEntry> entries) {
    for (final e in entries) {
      if (e.isRoot) return e;
    }
    return null;
  }

  /// Whether a back operation is possible (at least one overlay).
  static bool canGoBack(List<NavEntry> entries) => overlays(entries).isNotEmpty;

  /// The number of entries (root + overlays).
  static int depth(List<NavEntry> entries) => entries.length;
}
