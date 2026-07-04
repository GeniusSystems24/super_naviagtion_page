// ============================================================
// presentation/controllers/navigation_controller.dart
// ------------------------------------------------------------
// The application layer for ONE NavigationPage — a ChangeNotifier the View
// renders and forwards intents to. Fully self-contained and framework-light
// (no widgets): it owns this container's private stack, serialises transitions
// behind one lock, dedupes rapid opens, resolves every open() to a NavResult,
// runs close-guards, emits lifecycle events, and settles all pending work on
// dispose(). A faithful port of the React controller.
// ============================================================

import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import '../../domain/entities/nav_entry.dart';
import '../../domain/entities/nav_events.dart';
import '../../domain/entities/nav_options.dart';
import '../../domain/entities/nav_presentation.dart';
import '../../domain/entities/nav_result.dart';
import '../../domain/entities/retention_policy.dart';
import '../../domain/usecases/nav_stack.dart';

/// How overlapping navigation requests are handled within one container.
enum NavConcurrency {
  /// A request arriving mid-transition is dropped.
  ignore,

  /// A request arriving mid-transition is queued and run when the lock frees.
  queue,
}

/// A serialisable snapshot of a container's stack, for save / restore across a
/// screen recreation.
@immutable
class NavStackSnapshot {
  const NavStackSnapshot({
    required this.id,
    required this.retention,
    required this.maxRetained,
    required this.defaultMode,
    required this.frames,
  });

  final String id;
  final RetentionPolicy retention;
  final int? maxRetained;
  final String? defaultMode;

  /// One record per stack entry: (viewKey, params, options, isRoot).
  final List<NavFrameSnapshot> frames;
}

/// A single saved frame.
@immutable
class NavFrameSnapshot {
  const NavFrameSnapshot({
    required this.viewKey,
    required this.params,
    required this.options,
    required this.isRoot,
  });
  final String viewKey;
  final Object? params;
  final NavOptions options;
  final bool isRoot;
}

/// The controller behind one [NavigationPage]. Extends [ChangeNotifier] so a
/// thin View can `AnimatedBuilder`/`ListenableBuilder` on it.
class SuperNavigationController extends ChangeNotifier {
  SuperNavigationController({
    String? id,
    this.retention = RetentionPolicy.preserve,
    this.maxRetained,
    this.defaultMode,
    this.concurrency = NavConcurrency.ignore,
    Duration dedupeWindow = const Duration(milliseconds: 450),
  })  : id = id ?? 'page_${_seq++}',
        _dedupeWindow = dedupeWindow;

  static int _seq = 0;

  /// Stable container id — used by [NavigationHub] and as the widget key.
  final String id;

  /// The retention policy for covered views (the memory knob).
  RetentionPolicy retention;

  /// Optional cap on how many covered views stay mounted; deeper ones are
  /// unmounted regardless of policy. Null means unbounded.
  int? maxRetained;

  /// The container's default presentation mode when a call names none.
  NavPresentationMode? defaultMode;

  /// The overlapping-request policy.
  NavConcurrency concurrency;

  final Duration _dedupeWindow;

  final List<NavEntry> _entries = [];
  bool _transitioning = false;
  bool _disposed = false;

  final List<NavEventListener> _eventListeners = [];
  final Map<String, NavCloseGuard> _guards = {};
  final Set<Timer> _timers = {};
  final List<void Function()> _queue = [];

  String? _dedupeKey;
  int _dedupeAt = 0;
  int _entrySeq = 0;

  // ── reads ──
  /// The full stack, root first.
  List<NavEntry> get entries => List.unmodifiable(_entries);

  /// The number of entries (root + overlays).
  int get depth => _entries.length;

  /// Whether a back operation is possible.
  bool get canGoBack => NavStack.canGoBack(_entries);

  /// Whether a transition is currently running (the lock).
  bool get isTransitioning => _transitioning;

  /// Whether the controller has been disposed.
  bool get isDisposed => _disposed;

  /// The top entry, or null.
  NavEntry? get top => NavStack.peek(_entries);

  /// The overlays above the root.
  List<NavEntry> get overlays => NavStack.overlays(_entries);

  // ── events ──
  /// Subscribe to lifecycle events; returns a remover.
  VoidCallback addEventListener(NavEventListener listener) {
    _eventListeners.add(listener);
    return () => _eventListeners.remove(listener);
  }

  void _emit(NavEvent event, NavEventData data) {
    for (final l in List<NavEventListener>.from(_eventListeners)) {
      try {
        l(event, data);
      } catch (e, s) {
        debugPrint('NavEvent listener error: $e\n$s');
      }
    }
  }

  void _later(Duration d, VoidCallback fn) {
    late final Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      if (!_disposed) fn();
    });
    _timers.add(t);
  }

  String _nextId([String prefix = 'v']) =>
      '${prefix}_${id}_${_entrySeq++}_${DateTime.now().microsecondsSinceEpoch}';

  Duration _durationOf(NavEntry e) =>
      e.options.duration ?? e.options.presentation.transition.defaultDuration;

  // ── root ──
  /// Set (or replace) the base view. Settles any open overlays first.
  void setRoot(String viewKey, {Object? params}) {
    for (final e in NavStack.overlays(_entries)) {
      e.settle(NavResult.cancelled('rootChanged'));
    }
    _entries
      ..clear()
      ..add(NavEntry(
        id: _nextId('root'),
        viewKey: viewKey,
        params: params,
        options: NavOptions(presentation: NavPresentations.get('dialog')),
        isRoot: true,
      ));
    _safeNotify();
  }

  // ── open ──
  /// Push [viewKey] above the current view and resolve when it later closes.
  ///
  /// The presentation is resolved as: [presentation] override → [mode] →
  /// the container's [defaultMode] → the global default.
  Future<NavResult> open(
    String viewKey, {
    Object? params,
    NavPresentationMode? mode,
    NavPresentation? presentation,
    Duration? duration,
    bool dismissOnOutside = true,
    Size? size,
    String? key,
    Duration? dedupeWindow,
  }) {
    if (_disposed) return Future.value(NavResult.cancelled('disposed'));

    final dedupeKey = key ?? viewKey;
    final now = DateTime.now().millisecondsSinceEpoch;

    // duplicate / rapid-fire guard
    if (_dedupeKey == dedupeKey &&
        now - _dedupeAt < (dedupeWindow ?? _dedupeWindow).inMilliseconds) {
      _emit(NavEvent.navigationRejected,
          NavEventData(page: id, viewKey: viewKey, reason: 'duplicate'));
      return Future.value(NavResult.cancelled('duplicate'));
    }

    // concurrency: one transition per container
    if (_transitioning) {
      if (concurrency == NavConcurrency.queue) {
        final completer = Completer<NavResult>();
        _queue.add(() => open(
              viewKey,
              params: params,
              mode: mode,
              presentation: presentation,
              duration: duration,
              dismissOnOutside: dismissOnOutside,
              size: size,
              key: key,
              dedupeWindow: dedupeWindow,
            ).then(completer.complete));
        return completer.future;
      }
      _emit(NavEvent.navigationRejected,
          NavEventData(page: id, viewKey: viewKey, reason: 'transitioning'));
      return Future.value(NavResult.cancelled('busy'));
    }

    _dedupeKey = dedupeKey;
    _dedupeAt = now;

    final resolved = presentation ??
        mode?.presentation ??
        defaultMode?.presentation ??
        NavPresentations.get(NavPresentations.globalDefault);
    final options = NavOptions(
      presentation: resolved,
      duration: duration,
      dismissOnOutside: dismissOnOutside,
      dedupeKey: dedupeKey,
      size: size,
    );
    final entry = NavEntry(
      id: _nextId(),
      viewKey: viewKey,
      params: params,
      options: options,
    );

    _entries.add(entry);
    _transitioning = true;
    _emit(NavEvent.navigationStarted,
        NavEventData(page: id, id: entry.id, viewKey: viewKey));
    _safeNotify();
    _later(_durationOf(entry), () {
      _transitioning = false;
      _emit(NavEvent.navigationCompleted,
          NavEventData(page: id, id: entry.id, viewKey: viewKey));
      _safeNotify();
      _drain();
    });
    return entry.result;
  }

  void _drain() {
    if (_queue.isNotEmpty && !_transitioning && !_disposed) {
      _queue.removeAt(0)();
    }
  }

  // ── back / close ──
  /// Pop the top view, delivering [result] to its opener. Alias of [back].
  /// Pass [force] to bypass any close-guard.
  Future<bool> close([NavResult? result, bool force = false]) =>
      _pop(result ?? NavResult.cancelled('closed'), 'close', force: force);

  /// Pop the top view (back navigation), delivering [result] to its opener.
  /// Pass [force] to bypass any close-guard.
  Future<bool> back([NavResult? result, bool force = false]) =>
      _pop(result ?? NavResult.cancelled('back'), 'back', force: force);

  Future<bool> _pop(NavResult result, String kind, {bool force = false}) async {
    if (_disposed) return false;
    final entry = top;
    if (entry == null || entry.isRoot) {
      _emit(NavEvent.navigationRejected,
          NavEventData(page: id, reason: 'noPrevious'));
      return false;
    }
    if (_transitioning) {
      _emit(NavEvent.navigationRejected,
          NavEventData(page: id, reason: 'transitioning'));
      return false;
    }

    final guard = _guards[entry.id];
    if (guard != null && !force) {
      bool allow = true;
      try {
        allow = await guard();
      } catch (_) {
        allow = true;
      }
      if (!allow) {
        _emit(NavEvent.closeBlocked,
            NavEventData(page: id, id: entry.id, viewKey: entry.viewKey));
        return false;
      }
    }

    _transitioning = true;
    _guards.remove(entry.id);
    entry.settle(result);
    _entries.removeLast();
    _emit(NavEvent.navigatingBack,
        NavEventData(page: id, id: entry.id, viewKey: entry.viewKey));
    _safeNotify();
    _later(_durationOf(entry), () {
      _transitioning = false;
      _emit(NavEvent.viewClosed,
          NavEventData(page: id, id: entry.id, viewKey: entry.viewKey, result: result));
      _safeNotify();
      _drain();
    });
    return true;
  }

  // ── replace ──
  /// Swap the current view for [viewKey], leaving no back entry behind.
  Future<NavResult> replace(
    String viewKey, {
    Object? params,
    NavPresentationMode? mode,
    NavPresentation? presentation,
    Size? size,
  }) {
    if (_disposed) return Future.value(NavResult.cancelled('disposed'));
    final t = top;
    if (t == null || t.isRoot) {
      setRoot(viewKey, params: params);
      return Future.value(NavResult.success());
    }
    if (_transitioning) {
      _emit(NavEvent.navigationRejected,
          NavEventData(page: id, reason: 'transitioning'));
      return Future.value(NavResult.cancelled('busy'));
    }
    final resolved = presentation ??
        mode?.presentation ??
        t.options.presentation.copyWith(transition: NavTransitionKind.fade);
    t.settle(NavResult.cancelled('replaced'));
    _guards.remove(t.id);
    final entry = NavEntry(
      id: _nextId(),
      viewKey: viewKey,
      params: params,
      options: t.options.copyWith(presentation: resolved, size: size),
    );
    _entries
      ..removeLast()
      ..add(entry);
    _emit(NavEvent.navigationStarted,
        NavEventData(page: id, id: entry.id, viewKey: viewKey));
    _emit(NavEvent.navigationCompleted,
        NavEventData(page: id, id: entry.id, viewKey: viewKey));
    _safeNotify();
    return entry.result;
  }

  // ── pop to root / close all ──
  /// Dismiss every popup back to the root view.
  Future<bool> popToRoot() {
    if (_disposed || _transitioning) return Future.value(false);
    final overlaysNow = NavStack.overlays(_entries);
    if (overlaysNow.isEmpty) return Future.value(false);
    final t = top!;
    for (final e in overlaysNow) {
      e.settle(NavResult.cancelled('popToRoot'));
      _guards.remove(e.id);
    }
    _transitioning = true;
    // keep root + the top (animating out); drop the middle overlays now
    final root = NavStack.root(_entries);
    _entries
      ..clear()
      ..addAll([if (root != null) root, t]);
    _emit(NavEvent.navigatingBack,
        NavEventData(page: id, id: t.id, viewKey: t.viewKey, toRoot: true));
    _safeNotify();
    final completer = Completer<bool>();
    _later(_durationOf(t), () {
      _entries.removeWhere((e) => !e.isRoot);
      _transitioning = false;
      for (final e in overlaysNow) {
        _emit(
            NavEvent.viewClosed,
            NavEventData(
                page: id,
                id: e.id,
                viewKey: e.viewKey,
                result: NavResult.cancelled('popToRoot')));
      }
      _safeNotify();
      _drain();
      completer.complete(true);
    });
    return completer.future;
  }

  /// Alias for [popToRoot] — close all popups inside this container.
  Future<bool> closeAll() => popToRoot();

  // ── close-guards (unsaved changes) ──
  /// Register a [guard] that can veto the dismissal of the entry [entryId].
  void setGuard(String entryId, NavCloseGuard? guard) {
    if (guard == null) {
      _guards.remove(entryId);
    } else {
      _guards[entryId] = guard;
    }
  }

  /// Remove any guard on [entryId].
  void clearGuard(String entryId) => _guards.remove(entryId);

  // ── save / restore ──
  /// A serialisable snapshot of the current stack.
  NavStackSnapshot serialize() => NavStackSnapshot(
        id: id,
        retention: retention,
        maxRetained: maxRetained,
        defaultMode: defaultMode?.name,
        frames: [
          for (final e in _entries)
            NavFrameSnapshot(
                viewKey: e.viewKey,
                params: e.params,
                options: e.options,
                isRoot: e.isRoot),
        ],
      );

  /// Rebuild the stack from a [snapshot] (e.g. after a screen recreation).
  /// Restored overlays are pre-settled — anything awaiting a pre-restore open()
  /// was already resolved.
  void restore(NavStackSnapshot snapshot) {
    _entries
      ..clear()
      ..addAll([
        for (final f in snapshot.frames)
          NavEntry(
            id: _nextId(f.isRoot ? 'root' : 'v'),
            viewKey: f.viewKey,
            params: f.params,
            options: f.options,
            isRoot: f.isRoot,
          )..settle(NavResult.cancelled('restored')),
      ]);
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    final closed = NavStack.overlays(_entries);
    for (final e in closed) {
      e.settle(NavResult.cancelled('disposed'));
    }
    _entries.clear();
    _queue.clear();
    _guards.clear();
    for (final e in closed) {
      _emit(
          NavEvent.viewClosed,
          NavEventData(
              page: id,
              id: e.id,
              viewKey: e.viewKey,
              result: NavResult.cancelled('disposed')));
    }
    _eventListeners.clear();
    super.dispose();
  }
}
