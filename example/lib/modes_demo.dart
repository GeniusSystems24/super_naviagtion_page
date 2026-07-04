// ============================================================
// example/lib/modes_demo.dart
// ------------------------------------------------------------
// EXAMPLE 4 — Presentation modes. One demo view opened in each built-in mode
// (dialog · bottom sheet · drawer · start drawer · top drawer · full-screen),
// plus a per-open override. Shows how a single view is presented six ways with
// no change to the view itself — the Open/Closed presentation registry.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

import 'widgets/demo_kit.dart';

const _modes = [
  (NavPresentationMode.dialog, 'Dialog', 'Centered modal · scale in', Icons.crop_square),
  (NavPresentationMode.bottomSheet, 'Bottom sheet', 'Rises · drag to expand · swipe down', Icons.vertical_align_bottom),
  (NavPresentationMode.drawer, 'Drawer (end)', 'Slides from the inline-end edge · swipe', Icons.chevron_left),
  (NavPresentationMode.drawerStart, 'Drawer (start)', 'Slides from the inline-start edge', Icons.chevron_right),
  (NavPresentationMode.drawerTop, 'Top drawer', 'Drops from the top edge', Icons.vertical_align_top),
  (NavPresentationMode.fullScreen, 'Full screen', 'Covers the page · previous preserved', Icons.fullscreen),
];

class ModesDemo extends StatefulWidget {
  const ModesDemo({super.key});
  @override
  State<ModesDemo> createState() => _ModesDemoState();
}

class _ModesDemoState extends State<ModesDemo> {
  final _controller = SuperNavigationController(id: 'modes');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 720;
    final page = NavigationPage(
      id: 'modes',
      controller: _controller,
      root: 'home',
      views: {
        'home': (c) => const _ModesHome(),
        'panel': (c) => const _ModePanel(),
      },
    );
    return DemoScaffold(
      title: 'Presentation modes',
      subtitle: 'One view, presented six ways',
      body: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: SizedBox(height: 470, child: page)),
              const SizedBox(width: 16),
              SizedBox(width: 320, child: EventLogPanel(controllers: [_controller], height: 300)),
            ])
          : ListView(children: [SizedBox(height: 460, child: page), const SizedBox(height: 14), EventLogPanel(controllers: [_controller], height: 200)]),
    );
  }
}

class _ModesHome extends StatelessWidget {
  const _ModesHome();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return ColoredBox(
      color: t.bg,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('OPEN THE SAME VIEW AS…', style: SuperText.eyebrow.copyWith(color: SuperTokens.accent)),
          const SizedBox(height: 12),
          for (final m in _modes) ...[
            DemoRow(
              code: m.$2,
              label: m.$3,
              leadingIcon: m.$4,
              onTap: () => NavigationPage.of(context).open('panel', params: m.$2, mode: m.$1),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final nav = NavigationPage.of(context);
    return Column(
      children: [
        OverlayHeader(
          eyebrow: 'Presented as',
          title: '${nav.params}',
          onClose: nav.canGoBack ? () => nav.close() : null,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.widgets_outlined, size: 34, color: t.fg3),
                const SizedBox(height: 12),
                Text('The same view component', style: SuperText.heading.copyWith(color: t.fg1)),
                const SizedBox(height: 6),
                Text('Only the presentation changed — the view is identical across every mode.',
                    textAlign: TextAlign.center, style: SuperText.caption.copyWith(color: t.fg3)),
                const SizedBox(height: 16),
                SuperButton(label: 'Close', variant: SuperButtonVariant.secondary, onPressed: () => nav.close()),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
