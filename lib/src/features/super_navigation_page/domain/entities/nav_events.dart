// ============================================================
// domain/entities/nav_events.dart
// ------------------------------------------------------------
// The lifecycle events every container emits. A host subscribes via the
// NavigationPage `onEvent` callback (or `controller.addEventListener`) to log,
// analyse or react to navigation. Pure Dart.
// ============================================================

import 'package:flutter/foundation.dart';

import 'nav_result.dart';

/// The kind of a navigation lifecycle event.
enum NavEvent {
  /// A view was pushed; its enter transition began.
  navigationStarted,

  /// The enter transition settled; the container unlocked.
  navigationCompleted,

  /// A pop began (back / close / replace / popToRoot).
  navigatingBack,

  /// A view left the stack; its result was delivered.
  viewClosed,

  /// A request was dropped — duplicate, busy, or no previous view.
  navigationRejected,

  /// A close-guard vetoed a dismissal (unsaved changes).
  closeBlocked,
}

/// The payload accompanying a [NavEvent].
@immutable
class NavEventData {
  const NavEventData({
    required this.page,
    this.id,
    this.viewKey,
    this.reason,
    this.result,
    this.toRoot = false,
  });

  /// The id of the container that emitted the event.
  final String page;

  /// The affected entry id, if any.
  final String? id;

  /// The affected view key, if any.
  final String? viewKey;

  /// Why a request was rejected / blocked, if applicable.
  final String? reason;

  /// The delivered result on [NavEvent.viewClosed], if any.
  final NavResult? result;

  /// True when the event is part of a pop-to-root.
  final bool toRoot;

  @override
  String toString() =>
      'NavEventData(page: $page, view: $viewKey, reason: $reason, result: $result)';
}

/// A lifecycle listener signature.
typedef NavEventListener = void Function(NavEvent event, NavEventData data);
