// ============================================================
// domain/entities/nav_result.dart
// ------------------------------------------------------------
// The closed set of outcomes a navigation operation can resolve to. Every
// `open(...)` future completes with exactly one of these, so a caller always
// distinguishes success from cancellation from failure without exceptions
// crossing the boundary. Pure Dart — no Flutter.
// ============================================================

import 'package:flutter/foundation.dart';

/// The result of a completed navigation operation: success, cancellation or
/// error. Match it with [when] / [map], or the `is` checks.
///
/// ```dart
/// final r = await nav.open('details', order);
/// r.when(
///   success: (data) => print('kept $data'),
///   cancelled: (reason) => print('cancelled: $reason'),
///   error: (e, _) => print('failed: $e'),
/// );
/// ```
@immutable
sealed class NavResult {
  const NavResult();

  /// A successful result carrying [data] returned by the closed view.
  static NavResult success([Object? data]) => NavSuccess(data);

  /// A cancellation carrying an optional [reason] (e.g. `'dismissed'`).
  static NavResult cancelled([String? reason]) => NavCancelled(reason);

  /// A failure carrying the originating [error] (and optional [stackTrace]).
  static NavResult error(Object error, [StackTrace? stackTrace]) =>
      NavError(error, stackTrace);

  bool get isSuccess => this is NavSuccess;
  bool get isCancelled => this is NavCancelled;
  bool get isError => this is NavError;

  /// The success payload, cast to [T], or null for other outcomes.
  T? dataOrNull<T>() => switch (this) {
        NavSuccess(:final data) => data is T ? data : null,
        _ => null,
      };

  /// Exhaustively fold the three outcomes into a value of type [R].
  R when<R>({
    required R Function(Object? data) success,
    required R Function(String? reason) cancelled,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) =>
      switch (this) {
        NavSuccess(:final data) => success(data),
        NavCancelled(:final reason) => cancelled(reason),
        NavError(error: final e, stackTrace: final st) => error(e, st),
      };
}

/// A successful navigation result carrying the returned [data].
final class NavSuccess extends NavResult {
  const NavSuccess([this.data]);
  final Object? data;

  @override
  bool operator ==(Object other) => other is NavSuccess && other.data == data;
  @override
  int get hashCode => Object.hash(runtimeType, data);
  @override
  String toString() => 'NavSuccess($data)';
}

/// A cancelled navigation result with an optional [reason].
final class NavCancelled extends NavResult {
  const NavCancelled([this.reason]);
  final String? reason;

  @override
  bool operator ==(Object other) => other is NavCancelled && other.reason == reason;
  @override
  int get hashCode => Object.hash(runtimeType, reason);
  @override
  String toString() => 'NavCancelled($reason)';
}

/// A failed navigation result carrying the [error] and optional [stackTrace].
final class NavError extends NavResult {
  const NavError(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) => other is NavError && other.error == error;
  @override
  int get hashCode => Object.hash(runtimeType, error);
  @override
  String toString() => 'NavError($error)';
}
