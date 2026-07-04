// ============================================================
// presentation/controllers/navigation_hub.dart
// ------------------------------------------------------------
// The single source of truth for WHICH container is active. Multiple
// NavigationPages coexist; exactly one is active. The global back action
// (a system-back button, the Android hardware back, or a keyboard shortcut) is
// routed here and delivered only to the active controller — every other
// container is untouched. A ChangeNotifier so the active ring can rebuild.
// ============================================================


import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'navigation_controller.dart';

/// A process-wide registry of live [SuperNavigationController]s that tracks the
/// active one and routes the global back action to it. Use the singleton
/// [instance] (aliased as `NavigationHub.I`).
class NavigationHub extends ChangeNotifier {
  NavigationHub._();

  /// The shared instance.
  static final NavigationHub instance = NavigationHub._();

  /// Terse alias for [instance].
  static NavigationHub get I => instance;

  final Map<String, SuperNavigationController> _controllers = {};
  String? _activeId;

  /// The id of the active container, or null if none.
  String? get activeId => _activeId;

  /// Whether [id] is the active container.
  bool isActive(String id) => _activeId == id;

  /// The active controller, or null.
  SuperNavigationController? get active =>
      _activeId == null ? null : _controllers[_activeId];

  /// Look up a registered controller by [id].
  SuperNavigationController? controller(String id) => _controllers[id];

  /// Register [c]. The first registered container becomes active.
  void register(SuperNavigationController c) {
    _controllers[c.id] = c;
    _activeId ??= c.id;
    _notify();
  }

  /// Unregister the container [id]. If it was active, the most-recently
  /// registered remaining container becomes active.
  void unregister(String id) {
    _controllers.remove(id);
    if (_activeId == id) {
      _activeId = _controllers.isEmpty ? null : _controllers.keys.last;
      _notify();
    }
  }

  /// Make [id] the active container (called when the user interacts with it).
  void setActive(String id) {
    if (_controllers.containsKey(id) && _activeId != id) {
      _activeId = id;
      _notify();
    }
  }

  // register()/unregister() are called from a NavigationPage's initState/dispose,
  // which run during the parent's build; notifying listeners synchronously then
  // would markNeedsBuild mid-build. Defer to after the frame when in the build
  // phase; notify immediately otherwise (e.g. from a pointer event).
  void _notify() {
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  /// The global back action: pops the active container if it can go back and is
  /// not mid-transition. Returns true when it handled the back. Every inactive
  /// container is left untouched.
  bool handleBack() {
    final c = active;
    if (c != null && c.canGoBack && !c.isTransitioning) {
      c.back();
      return true;
    }
    return false;
  }

  /// Test-only reset of the singleton state.
  @visibleForTesting
  void resetForTest() {
    _controllers.clear();
    _activeId = null;
  }
}
