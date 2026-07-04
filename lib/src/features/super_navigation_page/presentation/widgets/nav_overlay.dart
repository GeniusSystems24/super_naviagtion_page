// ============================================================
// presentation/widgets/nav_overlay.dart
// ------------------------------------------------------------
// The presentation of ONE overlay entry: a scrim + an animated, gesture-driven
// panel positioned per its NavPresentation. Interprets the declarative
// presentation fields generically (position / transition / swipe / heights), so
// a mode registered in NavPresentations renders here with no change. Owns its
// own enter/exit AnimationController and signals removal when the exit finishes.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:super_core/super_core.dart';

import '../../domain/entities/nav_entry.dart';
import '../../domain/entities/nav_presentation.dart';
import '../../domain/entities/nav_result.dart';
import '../controllers/navigation_controller.dart';

/// Renders a single overlay [entry] with its transition, scrim and gestures.
class NavOverlay extends StatefulWidget {
  const NavOverlay({
    required super.key,
    required this.controller,
    required this.entry,
    required this.isTop,
    required this.dismissing,
    required this.onDismissed,
    required this.pageSize,
    required this.child,
  });

  final SuperNavigationController controller;
  final NavEntry entry;
  final bool isTop;

  /// True once this entry has left the logical stack — play the exit and then
  /// call [onDismissed] so the parent can remove it.
  final bool dismissing;
  final VoidCallback onDismissed;

  /// The bounds of the parent NavigationPage — used for fractional sizing.
  final Size pageSize;

  /// The view content, already wrapped in its entry scope.
  final Widget child;

  @override
  State<NavOverlay> createState() => _NavOverlayState();
}

class _NavOverlayState extends State<NavOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final CurvedAnimation _curve;
  double _drag = 0; // live drag offset (px)
  bool _expanded = false;

  NavPresentation get _p => widget.entry.options.presentation;
  Duration get _dur =>
      widget.entry.options.duration ?? _p.transition.defaultDuration;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: _dur, value: 0)..forward();
    _ac.addStatusListener(_onStatus);
    _curve = CurvedAnimation(parent: _ac, curve: SuperTokens.curveStandard);
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.dismissed && widget.dismissing) widget.onDismissed();
  }

  @override
  void didUpdateWidget(covariant NavOverlay old) {
    super.didUpdateWidget(old);
    if (widget.dismissing && !old.dismissing) {
      _ac.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _ac.dispose();
    super.dispose();
  }

  bool get _canDismiss =>
      widget.isTop &&
      !widget.controller.isTransitioning &&
      _p.dismissible;

  void _dismiss(String reason) {
    if (_canDismiss) widget.controller.close(NavResult.cancelled(reason));
  }

  // ── gestures ──
  void _onVUpdate(DragUpdateDetails d) {
    setState(() {
      var next = _drag + d.delta.dy;
      // rubber-band upward drag unless the sheet can expand
      if (next < 0 && !(_p.dragExpand && !_expanded)) next *= 0.22;
      _drag = next;
    });
  }

  void _onVEnd(DragEndDetails d) {
    final drag = _drag;
    setState(() => _drag = 0);
    if (drag > 90 && _p.swipe == NavSwipe.down) {
      _dismiss('swipe');
    } else if (drag < -40 && _p.dragExpand && !_expanded) {
      setState(() => _expanded = true);
    } else if (drag > 40 && _expanded) {
      setState(() => _expanded = false);
    }
  }

  void _onHUpdate(DragUpdateDetails d, double dir) {
    setState(() {
      var next = _drag + d.delta.dx;
      if (next.sign != dir && next != 0) next *= 0.2; // rubber-band the wrong way
      _drag = next;
    });
  }

  void _onHEnd(DragEndDetails d, double dir) {
    final drag = _drag;
    setState(() => _drag = 0);
    if (drag.abs() > 90 && drag.sign == dir) _dismiss('swipe');
  }

  // ── geometry ──
  AlignmentGeometry _align() => switch (_p.position) {
        NavPosition.center => Alignment.center,
        NavPosition.bottom => Alignment.bottomCenter,
        NavPosition.top => Alignment.topCenter,
        NavPosition.inlineStart => AlignmentDirectional.centerStart,
        NavPosition.inlineEnd => AlignmentDirectional.centerEnd,
        NavPosition.fill => Alignment.center,
      };

  BorderRadius _radius() {
    const r = Radius.circular(14);
    return switch (_p.position) {
      NavPosition.bottom => const BorderRadius.vertical(top: r),
      NavPosition.top => const BorderRadius.vertical(bottom: r),
      NavPosition.inlineStart ||
      NavPosition.inlineEnd ||
      NavPosition.fill =>
        BorderRadius.zero,
      NavPosition.center => BorderRadius.circular(SuperTokens.radiusCard),
    };
  }

  Widget _applyTransition(Animation<double> a, TextDirection dir, Widget child) {
    final faded = FadeTransition(opacity: a, child: child);
    switch (_p.transition) {
      case NavTransitionKind.none:
        return child;
      case NavTransitionKind.fade:
        return faded;
      case NavTransitionKind.slideUp:
        return SlideTransition(
            position: a.drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
            child: faded);
      case NavTransitionKind.slideDown:
        return SlideTransition(
            position: a.drive(Tween(begin: const Offset(0, -1), end: Offset.zero)),
            child: faded);
      case NavTransitionKind.slideInline:
        var base = _p.position == NavPosition.inlineStart ? -1.0 : 1.0;
        if (dir == TextDirection.rtl) base = -base;
        return SlideTransition(
            position: a.drive(Tween(begin: Offset(base, 0), end: Offset.zero)),
            child: faded);
      case NavTransitionKind.scale:
        return ScaleTransition(
            scale: a.drive(Tween(begin: 0.955, end: 1.0)), child: faded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final dir = Directionality.of(context);
    final page = widget.pageSize;
    final a = _curve;

    final isSheet = _p.swipe == NavSwipe.down;
    final inlineSwipe =
        _p.swipe == NavSwipe.inlineStart || _p.swipe == NavSwipe.inlineEnd;

    // panel size
    double? w;
    double? h;
    final override = widget.entry.options.effectiveSize;
    switch (_p.position) {
      case NavPosition.center:
        w = math.min(override?.width ?? 440, page.width * 0.9);
        break;
      case NavPosition.bottom:
        w = page.width;
        h = (_expanded ? _p.maxHeight : _p.initialHeight) * page.height;
        break;
      case NavPosition.top:
        w = page.width;
        break;
      case NavPosition.inlineStart:
      case NavPosition.inlineEnd:
        w = math.min(override?.width ?? 420, page.width * 0.88);
        h = page.height;
        break;
      case NavPosition.fill:
        w = page.width;
        h = page.height;
        break;
    }

    // body: drag chrome per mode
    Widget body = widget.child;
    if (isSheet) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: widget.isTop ? _onVUpdate : null,
            onVerticalDragEnd: widget.isTop ? _onVEnd : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    Widget panel = AnimatedContainer(
      duration: SuperTokens.durBase,
      curve: SuperTokens.curveStandard,
      width: w,
      height: h,
      constraints: h == null
          ? BoxConstraints(maxHeight: page.height * (_p.position == NavPosition.top ? 0.7 : 0.9))
          : null,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.borderStrong),
        borderRadius: _radius(),
        boxShadow: SuperThemeData.popShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: body,
    );

    if (inlineSwipe) {
      final dirSign = _p.swipe == NavSwipe.inlineEnd ? 1.0 : -1.0;
      panel = Stack(
        children: [
          panel,
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: _p.swipe == NavSwipe.inlineEnd ? 0 : null,
            end: _p.swipe == NavSwipe.inlineStart ? 0 : null,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate:
                  widget.isTop ? (d) => _onHUpdate(d, dirSign) : null,
              onHorizontalDragEnd: widget.isTop ? (d) => _onHEnd(d, dirSign) : null,
              child: const SizedBox(width: 18),
            ),
          ),
        ],
      );
    }

    final dragTranslate = isSheet
        ? Offset(0, math.max(_drag, -70))
        : inlineSwipe
            ? Offset(_drag, 0)
            : Offset.zero;

    final positioned = _applyTransition(
      a,
      dir,
      Transform.translate(offset: dragTranslate, child: panel),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // scrim
        FadeTransition(
          opacity: a.drive(Tween(begin: 0.0, end: _p.scrim ? _p.dimOpacity : 0.0)),
          child: IgnorePointer(
            ignoring: !_p.blocking && !_p.scrim,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.entry.options.dismissOnOutside
                  ? () => _dismiss('dismissed')
                  : null,
              child: const ColoredBox(color: Color(0xFF05070C)),
            ),
          ),
        ),
        Align(alignment: _align(), child: positioned),
      ],
    );
  }
}
