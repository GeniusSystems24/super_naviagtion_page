// ============================================================
// domain/entities/nav_entry.dart
// ------------------------------------------------------------
// One entry on a container's navigation stack: a view key, its input params,
// resolved options, and the completer that delivers its result to whoever
// opened it. The root entry is the base view (never popped). Pure Dart.
// ============================================================

import 'dart:async';

import 'nav_options.dart';
import 'nav_result.dart';

/// A single view on a [SuperNavigationController]'s stack.
class NavEntry {
  NavEntry({
    required this.id,
    required this.viewKey,
    required this.options,
    this.params,
    this.isRoot = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().microsecondsSinceEpoch;

  /// Stable unique id (also the widget key).
  final String id;

  /// Which registered view to render.
  final String viewKey;

  /// The data passed to this view when it was opened.
  final Object? params;

  /// The resolved presentation + behaviour options.
  final NavOptions options;

  /// Whether this is the base view (always present, never popped).
  final bool isRoot;

  /// Creation timestamp (microseconds) — preserves push order across sorts.
  final int createdAt;

  /// Completes when this view is closed, delivering its result upward.
  final Completer<NavResult> _completer = Completer<NavResult>();

  bool _settled = false;

  /// The future a caller awaits from `open(...)`.
  Future<NavResult> get result => _completer.future;

  /// Whether this entry's result has already been delivered.
  bool get isSettled => _settled;

  /// Deliver [result] to the awaiting caller exactly once. Extra calls are
  /// ignored, so a view torn down unexpectedly never dangles a future.
  void settle(NavResult result) {
    if (_settled) return;
    _settled = true;
    if (!_completer.isCompleted) _completer.complete(result);
  }
}
