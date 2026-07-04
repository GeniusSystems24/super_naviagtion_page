// ============================================================
// domain/entities/nav_presentation.dart
// ------------------------------------------------------------
// How a view is shown. A presentation is a declarative descriptor the overlay
// interprets — where the panel sits, its entrance transition, whether it dims /
// blocks / dismisses, and which drag/swipe affordances it carries. This is the
// Open/Closed seam: a new mode is a `NavPresentations.register(...)` call, and
// the controller + overlay render it with no change. Pure Dart.
// ============================================================

import 'package:flutter/foundation.dart';
import 'dart:ui' show Size;

/// Where a presented view sits inside its parent NavigationPage box.
enum NavPosition { center, bottom, top, inlineStart, inlineEnd, fill }

/// The entrance/exit transition a presentation animates with.
enum NavTransitionKind { none, fade, slideUp, slideDown, slideInline, scale }

/// The swipe-to-dismiss gesture a presentation supports (if any).
enum NavSwipe { none, down, inlineStart, inlineEnd }

/// A declarative presentation descriptor. Immutable; the built-ins live in
/// [NavPresentations]. Compose a custom one and pass it to `open(presentation:)`
/// or register it globally.
@immutable
class NavPresentation {
  const NavPresentation({
    required this.name,
    this.position = NavPosition.center,
    this.transition = NavTransitionKind.fade,
    this.scrim = true,
    this.blocking = true,
    this.dismissible = true,
    this.dimOpacity = 0.5,
    this.swipe = NavSwipe.none,
    this.dragExpand = false,
    this.initialHeight = 0.6,
    this.minHeight = 0.35,
    this.maxHeight = 0.94,
    this.size,
  });

  /// Stable identifier — the registry key.
  final String name;

  /// Anchor inside the page box.
  final NavPosition position;

  /// Entrance transition.
  final NavTransitionKind transition;

  /// Whether a dimming scrim is drawn behind the panel.
  final bool scrim;

  /// Whether interaction with content behind the panel is blocked.
  final bool blocking;

  /// Whether the panel can be dismissed (scrim tap / swipe / back).
  final bool dismissible;

  /// Scrim opacity when [scrim] is true.
  final double dimOpacity;

  /// Swipe-dismiss gesture direction.
  final NavSwipe swipe;

  /// Whether a bottom sheet can be dragged between [initialHeight] and
  /// [maxHeight].
  final bool dragExpand;

  /// Bottom-sheet heights as fractions of the page height.
  final double initialHeight;
  final double minHeight;
  final double maxHeight;

  /// Explicit size override (drawer width, dialog width, …).
  final Size? size;

  NavPresentation copyWith({
    String? name,
    NavPosition? position,
    NavTransitionKind? transition,
    bool? scrim,
    bool? blocking,
    bool? dismissible,
    double? dimOpacity,
    NavSwipe? swipe,
    bool? dragExpand,
    double? initialHeight,
    double? minHeight,
    double? maxHeight,
    Size? size,
  }) =>
      NavPresentation(
        name: name ?? this.name,
        position: position ?? this.position,
        transition: transition ?? this.transition,
        scrim: scrim ?? this.scrim,
        blocking: blocking ?? this.blocking,
        dismissible: dismissible ?? this.dismissible,
        dimOpacity: dimOpacity ?? this.dimOpacity,
        swipe: swipe ?? this.swipe,
        dragExpand: dragExpand ?? this.dragExpand,
        initialHeight: initialHeight ?? this.initialHeight,
        minHeight: minHeight ?? this.minHeight,
        maxHeight: maxHeight ?? this.maxHeight,
        size: size ?? this.size,
      );
}

/// The built-in presentation modes — a convenient enum over the registry. A
/// mode resolves to its registered [NavPresentation] via [presentation].
enum NavPresentationMode {
  /// Centered modal for confirmations.
  dialog,

  /// Rises from the bottom; drag handle to expand, swipe down to dismiss.
  bottomSheet,

  /// Slides from the inline-end edge (right in LTR); swipe to close.
  drawer,

  /// Slides from the inline-start edge (left in LTR).
  drawerStart,

  /// Drops from the top edge.
  drawerTop,

  /// Covers the whole page as a new screen; previous view preserved beneath.
  fullScreen;

  /// The registered descriptor for this mode.
  NavPresentation get presentation => NavPresentations.get(name);
}

/// Default transition durations, shared by the controller's lock timing and
/// the overlay's animation so they stay in step.
extension NavTransitionKindX on NavTransitionKind {
  Duration get defaultDuration => switch (this) {
        NavTransitionKind.none => Duration.zero,
        NavTransitionKind.fade => const Duration(milliseconds: 190),
        NavTransitionKind.slideUp => const Duration(milliseconds: 260),
        NavTransitionKind.slideDown => const Duration(milliseconds: 260),
        NavTransitionKind.slideInline => const Duration(milliseconds: 260),
        NavTransitionKind.scale => const Duration(milliseconds: 220),
      };
}

/// The open registry of presentation strategies. Adding a mode is a
/// [register] call — nothing else in the toolkit changes.
abstract final class NavPresentations {
  static final Map<String, NavPresentation> _map = {
    'dialog': const NavPresentation(
      name: 'dialog',
      position: NavPosition.center,
      transition: NavTransitionKind.scale,
      size: Size(440, double.infinity),
    ),
    'bottomSheet': const NavPresentation(
      name: 'bottomSheet',
      position: NavPosition.bottom,
      transition: NavTransitionKind.slideUp,
      swipe: NavSwipe.down,
      dragExpand: true,
      initialHeight: 0.6,
      minHeight: 0.35,
      maxHeight: 0.94,
      dimOpacity: 0.45,
    ),
    'drawer': const NavPresentation(
      name: 'drawer',
      position: NavPosition.inlineEnd,
      transition: NavTransitionKind.slideInline,
      swipe: NavSwipe.inlineEnd,
      size: Size(420, double.infinity),
      dimOpacity: 0.45,
    ),
    'drawerStart': const NavPresentation(
      name: 'drawerStart',
      position: NavPosition.inlineStart,
      transition: NavTransitionKind.slideInline,
      swipe: NavSwipe.inlineStart,
      size: Size(420, double.infinity),
      dimOpacity: 0.45,
    ),
    'drawerTop': const NavPresentation(
      name: 'drawerTop',
      position: NavPosition.top,
      transition: NavTransitionKind.slideDown,
      dimOpacity: 0.45,
    ),
    'fullScreen': const NavPresentation(
      name: 'fullScreen',
      position: NavPosition.fill,
      transition: NavTransitionKind.slideUp,
      scrim: false,
      dismissible: false,
    ),
  };

  static String _globalDefault = 'dialog';

  /// Register (or replace) a presentation. Keyed by [NavPresentation.name].
  static void register(NavPresentation presentation) =>
      _map[presentation.name] = presentation;

  /// Look up a presentation by [name], falling back to `dialog`.
  static NavPresentation get(String name) => _map[name] ?? _map['dialog']!;

  /// Every registered presentation name.
  static List<String> names() => _map.keys.toList(growable: false);

  /// The global default mode name, used when neither the call nor the page
  /// specifies one.
  static String get globalDefault => _globalDefault;

  /// Set the global default presentation, applied across every container that
  /// does not override it.
  static void setGlobalDefault(String name) {
    if (_map.containsKey(name)) _globalDefault = name;
  }
}
