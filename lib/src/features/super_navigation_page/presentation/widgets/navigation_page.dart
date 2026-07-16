// ============================================================
// presentation/widgets/navigation_page.dart
// ------------------------------------------------------------
// The React binding's Flutter counterpart — the View. NavigationPage owns one
// SuperNavigationController, registers it with the NavigationHub, marks itself
// active on interaction, renders the root view + a retention-governed stack of
// animated overlays clipped to its own bounds, routes the hardware/system back
// to itself only when active, and exposes the navigator to descendant views via
// context. The navigator handle (SuperNavigator) is bound to the calling view's
// entry, so `close()`/`params` refer to that view.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_core/super_core.dart';
import 'package:super_naviagtion_page/src/features/super_navigation_page/domain/entities/nav_options.dart';

import '../../domain/entities/nav_entry.dart';
import '../../domain/entities/nav_events.dart';
import '../../domain/entities/nav_presentation.dart';
import '../../domain/entities/nav_result.dart';
import '../../domain/entities/retention_policy.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/navigation_hub.dart';
import 'nav_overlay.dart';

/// Builds a registered view. Read the navigator with `NavigationPage.of(context)`
/// and this view's input with `NavigationPage.paramsOf(context)`.
typedef NavViewBuilder = Widget Function(BuildContext context);

// ── SuperNavigator — the API a view calls, bound to its own entry ────────────

/// A navigator handle bound to the nearest [NavigationPage] and the calling
/// view's entry. Obtain it with `NavigationPage.of(context)`.
class SuperNavigator {
  const SuperNavigator(this._c, this._entryId, this.params, this.isTop);

  final SuperNavigationController _c;
  final String? _entryId;

  /// The controller behind this container (for advanced use / lifecycle events).
  SuperNavigationController get controller => _c;

  /// The data passed to this view when it was opened.
  final Object? params;

  /// This view's data cast to [T], or null.
  T? paramsAs<T>() => params is T ? params as T : null;

  /// Whether this view is currently the top of the stack.
  final bool isTop;

  /// Whether a back is possible in this container.
  bool get canGoBack => _c.canGoBack;

  /// Open [viewKey] above the current view; resolves when it closes.
  Future<NavResult> open(
    String viewKey, {
    Object? params,
    NavPresentationMode? mode,
    NavPresentation? presentation,
    Duration? duration,
    bool dismissOnOutside = true,
    Size? size,
    String? key,
  }) =>
      _c.open(viewKey,
          params: params,
          mode: mode,
          presentation: presentation,
          duration: duration,
          dismissOnOutside: dismissOnOutside,
          size: size,
          key: key);

  /// Pop the top view (usually this one), delivering [result] upward.
  Future<bool> back([NavResult? result]) => _c.back(result);

  /// Alias of [back].
  Future<bool> close([NavResult? result]) => _c.close(result);

  /// Close bypassing any close-guard (e.g. after an intentional save).
  Future<bool> forceClose([NavResult? result]) => _c.close(result, true);

  /// Swap the current view for [viewKey], leaving no back entry.
  Future<NavResult> replace(String viewKey,
          {Object? params, NavPresentationMode? mode, NavPresentation? presentation}) =>
      _c.replace(viewKey, params: params, mode: mode, presentation: presentation);

  /// Dismiss every popup back to the root view.
  Future<bool> popToRoot() => _c.popToRoot();

  /// Alias of [popToRoot].
  Future<bool> closeAll() => _c.closeAll();

  /// Close self with a success result.
  Future<bool> submit([Object? data]) => _c.close(NavResult.success(data));

  /// Close self with a cancellation result.
  Future<bool> cancel([String? reason]) => _c.close(NavResult.cancelled(reason));

  /// Close self with an error result.
  Future<bool> fail(Object error) => _c.close(NavResult.error(error));

  /// Register an unsaved-changes guard for this view.
  void setGuard(NavCloseGuard guard) {
    if (_entryId != null) _c.setGuard(_entryId, guard);
  }

  /// Remove this view's close-guard.
  void clearGuard() {
    if (_entryId != null) _c.clearGuard(_entryId);
  }
}

// ── scopes ───────────────────────────────────────────────────────────────────

class _NavPageScope extends InheritedWidget {
  const _NavPageScope({required this.controller, required super.child});
  final SuperNavigationController controller;
  @override
  bool updateShouldNotify(_NavPageScope old) => controller != old.controller;
}

class _NavEntryScope extends InheritedWidget {
  const _NavEntryScope({
    required this.entryId,
    required this.params,
    required this.isTop,
    required super.child,
  });
  final String? entryId;
  final Object? params;
  final bool isTop;
  @override
  bool updateShouldNotify(_NavEntryScope old) =>
      entryId != old.entryId || params != old.params || isTop != old.isTop;
}

// ── NavigationPage ─────────────────────────────────────────────────────────

/// An independent navigation container. See the package docs for usage.
class NavigationPage extends StatefulWidget {
  const NavigationPage({
    super.key,
    required this.id,
    required this.views,
    required this.root,
    this.rootParams,
    this.controller,
    this.defaultMode,
    this.retention = RetentionPolicy.preserve,
    this.maxRetained,
    this.concurrency = NavConcurrency.ignore,
    this.height,
    this.onEvent,
    this.clip = true,
  });

  /// Stable, unique container id (Hub registration + active routing).
  final String id;

  /// The registered views, keyed by name.
  final Map<String, NavViewBuilder> views;

  /// The root (base) view key.
  final String root;

  /// Optional data for the root view.
  final Object? rootParams;

  /// An externally-owned controller. When null, one is created and disposed
  /// with the widget. When provided, the host owns its lifecycle.
  final SuperNavigationController? controller;

  /// This container's default presentation mode.
  final NavPresentationMode? defaultMode;

  /// The retention policy for covered views.
  final RetentionPolicy retention;

  /// Optional cap on mounted covered views (memory).
  final int? maxRetained;

  /// Overlapping-request policy.
  final NavConcurrency concurrency;

  /// Fixed height; when null the container fills the available height.
  final double? height;

  /// Lifecycle event sink.
  final NavEventListener? onEvent;

  /// Whether overlays are clipped to the container bounds (they should be).
  final bool clip;

  /// The navigator bound to the calling view's entry.
  static SuperNavigator of(BuildContext context) {
    final page = context.dependOnInheritedWidgetOfExactType<_NavPageScope>();
    assert(page != null, 'NavigationPage.of() called outside a NavigationPage');
    final entry = context.dependOnInheritedWidgetOfExactType<_NavEntryScope>();
    return SuperNavigator(
        page!.controller, entry?.entryId, entry?.params, entry?.isTop ?? false);
  }

  /// The current view's input params, or null.
  static Object? paramsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NavEntryScope>()?.params;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _RenderItem {
  _RenderItem(this.entry);
  final NavEntry entry;
  bool dismissing = false;
}

class _NavigationPageState extends State<NavigationPage> {
  late SuperNavigationController _controller;
  bool _ownsController = false;
  VoidCallback? _removeEventListener;
  final List<_RenderItem> _rendered = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        SuperNavigationController(
          id: widget.id,
          retention: widget.retention,
          maxRetained: widget.maxRetained,
          defaultMode: widget.defaultMode,
          concurrency: widget.concurrency,
        );
    _ownsController = widget.controller == null;
    if (_controller.entries.isEmpty) {
      _controller.setRoot(widget.root, params: widget.rootParams);
    }
    _controller.addListener(_onChange);
    if (widget.onEvent != null) {
      _removeEventListener = _controller.addEventListener(widget.onEvent!);
    }
    NavigationHub.I.register(_controller);
    _reconcile();
  }

  @override
  void didUpdateWidget(covariant NavigationPage old) {
    super.didUpdateWidget(old);
    // keep runtime knobs in sync with props (live retention / mode switching)
    _controller.retention = widget.retention;
    _controller.maxRetained = widget.maxRetained;
    _controller.defaultMode = widget.defaultMode;
    _controller.concurrency = widget.concurrency;
  }

  void _onChange() {
    _reconcile();
    if (mounted) setState(() {});
  }

  void _reconcile() {
    final overlays = _controller.overlays;
    final curIds = overlays.map((e) => e.id).toSet();
    for (final e in overlays) {
      if (!_rendered.any((r) => r.entry.id == e.id)) _rendered.add(_RenderItem(e));
    }
    for (final r in _rendered) {
      if (!curIds.contains(r.entry.id)) r.dismissing = true;
    }
    _rendered.sort((a, b) => a.entry.createdAt.compareTo(b.entry.createdAt));
  }

  void _removeRendered(String id) {
    _rendered.removeWhere((r) => r.entry.id == id);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _removeEventListener?.call();
    _controller.removeListener(_onChange);
    NavigationHub.I.unregister(_controller.id);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Widget _buildView(BuildContext context, NavEntry entry, bool isTop) {
    final builder = widget.views[entry.viewKey];
    final child = builder != null
        ? Builder(builder: builder)
        : _MissingView(viewKey: entry.viewKey);
    return _NavEntryScope(
      entryId: entry.id,
      params: entry.params,
      isTop: isTop,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
      final theme = SuperMaterialThemeData.of(context);
    final t = theme.superTheme;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final pageSize = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 360,
          constraints.hasBoundedHeight ? constraints.maxHeight : (widget.height ?? 400),
        );

        final active = _rendered.where((r) => !r.dismissing).toList();
        final topId = active.isEmpty ? null : active.last.entry.id;
        // setRoot runs in initState, so there is always a root entry.
        final rootEntry = _controller.entries.first;

        final children = <Widget>[
          // root view — always mounted, fills the page
          Positioned.fill(
            child: _buildView(context, rootEntry, active.isEmpty),
          ),
        ];

        for (final r in _rendered) {
          final isTop = r.entry.id == topId;
          if (!r.dismissing && !isTop) {
            // covered view: retention + memory cap decide whether it stays
            final depthFromTop = (active.length - 1) - active.indexOf(r);
            if (widget.maxRetained != null && depthFromTop > widget.maxRetained!) {
              continue; // memory cap → unmount
            }
            final ret = _controller.retention;
            if (ret == RetentionPolicy.recreate || ret == RetentionPolicy.dispose) {
              continue; // unmount; rebuilt fresh on reveal
            }
            final suspended = ret == RetentionPolicy.suspend;
            children.add(_wrapOverlay(context, r, isTop: false, pageSize: pageSize, suspended: suspended));
          } else {
            children.add(_wrapOverlay(context, r, isTop: isTop, pageSize: pageSize, suspended: false));
          }
        }

        Widget stack = Stack(fit: StackFit.expand, children: children);
        if (widget.clip) stack = ClipRRect(borderRadius: BorderRadius.circular(SuperTokens.radiusCard), child: stack);
        return stack;
      },
    );

    // active ring rebuilds when the Hub's active container changes
    final framed = AnimatedBuilder(
      animation: NavigationHub.I,
      builder: (context, child) {
        final isActive = NavigationHub.I.isActive(_controller.id);
        return AnimatedContainer(
          duration: SuperTokens.durBase,
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
            border: Border.all(
              color: isActive
                  ? Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.6), t.borderStrong)
                  : t.border,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.28), blurRadius: 0, spreadRadius: 2)]
                : null,
          ),
          child: child,
        );
      },
      child: content,
    );

    // Active-container tracking: touching this page makes it the active one, so
    // the host's back affordance (a PopScope / back button calling
    // NavigationHub.I.handleBack()) targets it. We intentionally do NOT wrap a
    // BackButtonListener here — it requires a Router ancestor and would throw
    // under a plain Navigator 1.0 MaterialApp. Hardware/system back is opt-in at
    // the host level via NavigationHub.I.handleBack().
    Widget result = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => NavigationHub.I.setActive(_controller.id),
      child: _NavPageScope(controller: _controller, child: framed),
    );

    if (widget.height != null) result = SizedBox(height: widget.height, child: result);
    return result;
  }

  Widget _wrapOverlay(
    BuildContext context,
    _RenderItem r, {
    required bool isTop,
    required Size pageSize,
    required bool suspended,
  }) {
    final overlay = NavOverlay(
      key: ValueKey(r.entry.id),
      controller: _controller,
      entry: r.entry,
      isTop: isTop,
      dismissing: r.dismissing,
      onDismissed: () => _removeRendered(r.entry.id),
      pageSize: pageSize,
      child: _buildView(context, r.entry, isTop),
    );
    if (suspended) {
      return TickerMode(
        enabled: false,
        child: Offstage(offstage: true, child: overlay),
      );
    }
    return overlay;
  }
}

class _MissingView extends StatelessWidget {
  const _MissingView({required this.viewKey});
  final String viewKey;
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.superTheme.surface,
        child: Center(
          child: Text('Unknown view: $viewKey',
              style: SuperText.body.copyWith(color: SuperMaterialThemeData.of(context).colorScheme.error)),
        ),
      );
}
