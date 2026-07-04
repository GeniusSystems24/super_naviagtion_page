// ============================================================
// domain/entities/nav_options.dart
// ------------------------------------------------------------
// The resolved, immutable options for one presented view — the presentation's
// defaults merged under any per-open overrides. Stored on a NavEntry and read
// by the overlay. Pure Dart.
// ============================================================

import 'package:flutter/foundation.dart';
import 'dart:ui' show Size;

import 'nav_presentation.dart';

/// A close-guard: returns true to allow the dismissal, false to veto it. May be
/// async (e.g. to show a confirmation and await the user's choice).
typedef NavCloseGuard = Future<bool> Function();

/// The fully-resolved options a presented view runs with.
@immutable
class NavOptions {
  const NavOptions({
    required this.presentation,
    this.duration,
    this.dismissOnOutside = true,
    this.dedupeKey,
    this.size,
  });

  /// The presentation strategy (position, transition, gestures, backdrop).
  final NavPresentation presentation;

  /// Overrides the transition duration; null uses the transition default.
  final Duration? duration;

  /// Whether tapping the scrim dismisses the view (only when
  /// `presentation.dismissible` is also true).
  final bool dismissOnOutside;

  /// The de-duplication key. Two `open` calls with the same key inside the
  /// dedupe window collapse to one.
  final String? dedupeKey;

  /// An explicit size override, taking precedence over the presentation size.
  final Size? size;

  /// The effective panel size (override first, else the presentation's).
  Size? get effectiveSize => size ?? presentation.size;

  NavOptions copyWith({
    NavPresentation? presentation,
    Duration? duration,
    bool? dismissOnOutside,
    String? dedupeKey,
    Size? size,
  }) =>
      NavOptions(
        presentation: presentation ?? this.presentation,
        duration: duration ?? this.duration,
        dismissOnOutside: dismissOnOutside ?? this.dismissOnOutside,
        dedupeKey: dedupeKey ?? this.dedupeKey,
        size: size ?? this.size,
      );
}
