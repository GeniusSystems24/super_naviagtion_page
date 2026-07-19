// ============================================================
// example/lib/widgets/demo_kit.dart
// ------------------------------------------------------------
// Shared demo-only scaffolding used by every NavigationPage example: a scene
// scaffold (app bar + optional side rail), a live lifecycle-event log wired to
// a controller's events, list rows, cells and stat chips. Nothing here is part
// of the package — it just frames the live containers.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

/// A simple page scaffold for a demo.
class DemoScaffold extends StatelessWidget {
  const DemoScaffold(
      {super.key, required this.title, required this.body, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: t.fg2),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: SuperText.heading.copyWith(color: t.fg1)),
            if (subtitle != null)
              Text(subtitle!, style: SuperText.caption.copyWith(color: t.fg3)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
            padding: EdgeInsets.all(SuperThemeData.of(context).tokens.space6), child: body),
      ),
    );
  }
}

/// A rolling in-memory lifecycle-event log bound to a controller.
class EventLogPanel extends StatefulWidget {
  const EventLogPanel(
      {super.key,
      required this.controllers,
      this.height = 300,
      this.title = 'Lifecycle events'});
  final List<SuperNavigationController> controllers;
  final double height;
  final String title;

  @override
  State<EventLogPanel> createState() => EventLogPanelState();
}

class _LogLine {
  _LogLine(this.event, this.data, this.time);
  final NavEvent event;
  final NavEventData data;
  final String time;
}

class EventLogPanelState extends State<EventLogPanel> {
  final List<_LogLine> _lines = [];
  final List<VoidCallback> _removers = [];

  @override
  void initState() {
    super.initState();
    for (final c in widget.controllers) {
      _removers.add(c.addEventListener(_onEvent));
    }
  }

  void _onEvent(NavEvent e, NavEventData d) {
    final now = DateTime.now();
    final time =
        '${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    setState(() {
      _lines.insert(0, _LogLine(e, d, time));
      if (_lines.length > 60) _lines.removeLast();
    });
  }

  @override
  void dispose() {
    for (final r in _removers) {
      r();
    }
    super.dispose();
  }

  (Color, IconData, String) _meta(NavEvent e) => switch (e) {
        NavEvent.navigationStarted => (
            SuperMaterialThemeData.of(context).colorScheme.primary,
            Icons.north_east,
            'started'
          ),
        NavEvent.navigationCompleted => (
            SuperThemeData.of(context).tokens.success,
            Icons.check,
            'completed'
          ),
        NavEvent.navigatingBack => (SuperThemeData.of(context).tokens.warning, Icons.west, 'back'),
        NavEvent.viewClosed => (context.superTheme.fg3, Icons.close, 'closed'),
        NavEvent.navigationRejected => (
            SuperMaterialThemeData.of(context).colorScheme.error,
            Icons.block,
            'rejected'
          ),
        NavEvent.closeBlocked => (
            SuperMaterialThemeData.of(context).colorScheme.error,
            Icons.lock_outline,
            'blocked'
          ),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title.toUpperCase(),
                    style: SuperText.label.copyWith(color: t.fg3)),
                GestureDetector(
                  onTap: () => setState(_lines.clear),
                  child: Text('CLEAR',
                      style: SuperText.pill.copyWith(color: t.fg4)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _lines.isEmpty
                ? Center(
                    child: Text(
                        'Interact with the container —\nevents land here.',
                        textAlign: TextAlign.center,
                        style: SuperText.caption.copyWith(color: t.fg4)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _lines.length,
                    itemBuilder: (context, i) {
                      final l = _lines[i];
                      final (color, icon, label) = _meta(l.event);
                      final detail = l.data.viewKey ??
                          (l.data.toRoot ? 'root' : l.data.reason ?? '');
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 62,
                              child: Text(l.time,
                                  style: SuperText.mono
                                      .copyWith(fontSize: 10, color: t.fg4)),
                            ),
                            Icon(icon, size: 13, color: color),
                            const SizedBox(width: 7),
                            SizedBox(
                              width: 72,
                              child: Text(label.toUpperCase(),
                                  style: SuperText.pill.copyWith(color: color)),
                            ),
                            Expanded(
                              child: Text(detail,
                                  overflow: TextOverflow.ellipsis,
                                  style: SuperText.mono
                                      .copyWith(fontSize: 11, color: t.fg2)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A tappable list row (mono code + label + trailing).
class DemoRow extends StatelessWidget {
  const DemoRow({
    super.key,
    required this.code,
    required this.label,
    this.trailing,
    this.onTap,
    this.tint,
    this.leadingIcon,
  });
  final String code;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final Color? tint;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
          ),
          child: Row(
            children: [
              Icon(leadingIcon ?? Icons.circle,
                  size: leadingIcon != null ? 16 : 7,
                  color: tint ??
                      SuperMaterialThemeData.of(context).colorScheme.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code,
                        style: SuperText.mono.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: t.fg1)),
                    const SizedBox(height: 1),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SuperText.caption.copyWith(color: t.fg3)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing!,
                    style: SuperText.mono.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: t.fg2)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 16, color: t.fg4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A key/value cell.
class DemoCell extends StatelessWidget {
  const DemoCell(
      {super.key, required this.k, required this.v, this.mono = false});
  final String k;
  final String v;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.inputBg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.toUpperCase(), style: SuperText.pill.copyWith(color: t.fg4)),
          const SizedBox(height: 3),
          Text(v,
              style: (mono ? SuperText.mono : SuperText.body).copyWith(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg1)),
        ],
      ),
    );
  }
}

/// A small labelled stat chip.
class DemoStat extends StatelessWidget {
  const DemoStat(
      {super.key, required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: t.inputBg,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: SuperText.pill.copyWith(color: t.fg4)),
            const SizedBox(height: 2),
            Text(value,
                style: SuperText.mono.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color ?? t.fg1)),
          ],
        ),
      ),
    );
  }
}

/// A panel header used inside overlay views.
class OverlayHeader extends StatelessWidget {
  const OverlayHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.tint,
    this.onBack,
    this.onClose,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final Color? tint;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: Row(
        children: [
          if (onBack != null) ...[
            _iconBtn(context, Icons.chevron_left, onBack!),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(),
                    style: SuperText.pill.copyWith(
                        color: tint ??
                            SuperMaterialThemeData.of(context)
                                .colorScheme
                                .primary)),
                const SizedBox(height: 2),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        SuperText.heading.copyWith(fontSize: 15, color: t.fg1)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onClose != null) ...[
            const SizedBox(width: 8),
            _iconBtn(context, Icons.close, onClose!),
          ],
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final t = context.superTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.inputBg,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 17, color: t.fg2),
      ),
    );
  }
}
