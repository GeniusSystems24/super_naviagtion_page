// ============================================================
// example/lib/containers_demo.dart
// ------------------------------------------------------------
// EXAMPLE 2 — Multiple independent NavigationPages on one screen.
// A Warehouse container and a Ledger container, each with its own stack and its
// own popups. Whichever you touch last becomes the active container (accent
// ring); the "System back" button — routed through NavigationHub — pops only
// that one. Remove the Ledger and the Warehouse is untouched, its pending work
// settled cleanly.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

import 'widgets/demo_kit.dart';

class ContainersDemo extends StatefulWidget {
  const ContainersDemo({super.key});
  @override
  State<ContainersDemo> createState() => _ContainersDemoState();
}

class _ContainersDemoState extends State<ContainersDemo> {
  final _a = SuperNavigationController(id: 'warehouse');
  final _b = SuperNavigationController(id: 'ledger');
  bool _showB = true;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final wide = MediaQuery.sizeOf(context).width > 720;

    final a = NavigationPage(
      id: 'warehouse',
      controller: _a,
      root: 'list',
      defaultMode: NavPresentationMode.bottomSheet,
      views: {
        'list': (c) => const _WarehouseList(),
        'item': (c) => const _WarehouseItem(),
      },
    );
    final b = NavigationPage(
      id: 'ledger',
      controller: _b,
      root: 'list',
      defaultMode: NavPresentationMode.drawer,
      views: {
        'list': (c) => const _LedgerList(),
        'entry': (c) => const _LedgerEntry(),
        'note': (c) => const _LedgerNote(),
      },
    );

    return DemoScaffold(
      title: 'Independent containers',
      subtitle: 'Two isolated stacks · active-container back routing',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            AnimatedBuilder(
              animation: NavigationHub.I,
              builder: (context, _) {
                final active = NavigationHub.I.activeId;
                final name = active == 'warehouse'
                    ? 'Warehouse'
                    : active == 'ledger'
                        ? 'Ledger'
                        : '—';
                final tone = active == 'warehouse'
                    ? PillTone.accent
                    : active == 'ledger'
                        ? PillTone.success
                        : PillTone.neutral;
                return StatusPill('ACTIVE · $name', tone: tone);
              },
            ),
            const SizedBox(width: 10),
            SuperButton(
              label: 'System back',
              variant: SuperButtonVariant.secondary,
              icon: const Icon(Icons.west, size: 15),
              onPressed: () => NavigationHub.I.handleBack(),
            ),
            const Spacer(),
            SuperButton(
              label: _showB ? 'Remove Ledger' : 'Restore Ledger',
              variant: SuperButtonVariant.secondary,
              onPressed: () => setState(() => _showB = !_showB),
            ),
          ]),
          const SizedBox(height: 6),
          Text('Tap a container to make it active, then press System back — it pops only the active one.',
              style: SuperText.caption.copyWith(color: t.fg4)),
          const SizedBox(height: 14),
          SizedBox(
            height: 360,
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: a),
                    if (_showB) ...[const SizedBox(width: 14), Expanded(child: b)],
                  ])
                : a,
          ),
          const SizedBox(height: 14),
          EventLogPanel(controllers: [_a, _b], height: 200, title: 'Events across both containers'),
        ],
      ),
    );
  }
}

// ── Warehouse ──
class _WarehouseList extends StatelessWidget {
  const _WarehouseList();
  static const _items = [
    ('SKU-4401', 'Steel Bracket 40mm', 'A-12', 1240),
    ('SKU-4402', 'Hex Bolt M8', 'A-13', 8600),
    ('SKU-4407', 'Rubber Gasket 2"', 'B-04', 320),
  ];
  @override
  Widget build(BuildContext context) {
    return _ContainerList(
      eyebrow: 'WAREHOUSE A',
      title: 'Inventory',
      tint: SuperMaterialThemeData.of(context).colorScheme.primary,
      rows: [
        for (final it in _items)
          DemoRow(
            code: it.$1,
            label: it.$2,
            trailing: '${it.$4}',
            tint: SuperMaterialThemeData.of(context).colorScheme.primary,
            onTap: () => NavigationPage.of(context)
                .open('item', params: it, mode: NavPresentationMode.bottomSheet),
          ),
      ],
    );
  }
}

class _WarehouseItem extends StatelessWidget {
  const _WarehouseItem();
  @override
  Widget build(BuildContext context) {
    final nav = NavigationPage.of(context);
    final it = nav.params as (String, String, String, int);
    return Column(
      children: [
        OverlayHeader(eyebrow: 'Item · bottom sheet', title: it.$2, tint: SuperMaterialThemeData.of(context).colorScheme.primary, onClose: () => nav.close()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.7,
              children: [
                DemoCell(k: 'SKU', v: it.$1, mono: true),
                DemoCell(k: 'Bin', v: it.$3),
                DemoCell(k: 'On hand', v: '${it.$4}'),
                const DemoCell(k: 'Status', v: 'In stock'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ledger (goes two deep) ──
class _LedgerList extends StatelessWidget {
  const _LedgerList();
  static const _entries = [('JV-2024-0042', 'Opening balance', 5000), ('JV-2024-0043', 'Bank transfer', 12500)];
  @override
  Widget build(BuildContext context) {
    return _ContainerList(
      eyebrow: 'LEDGER B',
      title: 'Journal Entries',
      tint: SuperThemeData.of(context).tokens.success,
      rows: [
        for (final e in _entries)
          DemoRow(
            code: e.$1,
            label: e.$2,
            trailing: '\$${e.$3}',
            tint: SuperThemeData.of(context).tokens.success,
            onTap: () => NavigationPage.of(context)
                .open('entry', params: e, mode: NavPresentationMode.drawer),
          ),
      ],
    );
  }
}

class _LedgerEntry extends StatelessWidget {
  const _LedgerEntry();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final nav = NavigationPage.of(context);
    final e = nav.params as (String, String, int);
    return Column(
      children: [
        OverlayHeader(eyebrow: 'Entry · depth 2', title: e.$1, tint: SuperThemeData.of(context).tokens.success, onBack: () => nav.back()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${e.$2} — \$${e.$3}', style: SuperText.body.copyWith(color: t.fg2)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
          child: Row(children: [
            SuperButton(label: 'Back', variant: SuperButtonVariant.secondary, onPressed: () => nav.back()),
            const Spacer(),
            SuperButton(
              label: 'Add note…',
              onPressed: () => nav.open('note', params: e.$1, mode: NavPresentationMode.dialog),
            ),
          ]),
        ),
      ],
    );
  }
}

class _LedgerNote extends StatelessWidget {
  const _LedgerNote();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final nav = NavigationPage.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTE · DEPTH 3', style: SuperText.pill.copyWith(color: SuperThemeData.of(context).tokens.warning)),
          const SizedBox(height: 6),
          Text('Note on ${nav.params}', style: SuperText.heading.copyWith(color: t.fg1)),
          const SizedBox(height: 8),
          Text('This popup lives entirely inside Ledger B. The Warehouse is untouched by anything you do here.',
              style: SuperText.caption.copyWith(color: t.fg3)),
          const SizedBox(height: 16),
          Row(children: [
            SuperButton(label: 'To root', variant: SuperButtonVariant.secondary, onPressed: () => nav.popToRoot()),
            const Spacer(),
            SuperButton(label: 'Cancel', variant: SuperButtonVariant.secondary, onPressed: () => nav.cancel()),
            const SizedBox(width: 8),
            SuperButton(label: 'Save note', onPressed: () => nav.submit({'saved': true})),
          ]),
        ],
      ),
    );
  }
}

// ── shared list chrome ──
class _ContainerList extends StatelessWidget {
  const _ContainerList({required this.eyebrow, required this.title, required this.tint, required this.rows});
  final String eyebrow;
  final String title;
  final Color tint;
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return ColoredBox(
      color: t.bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(eyebrow, style: SuperText.pill.copyWith(color: tint)),
          const SizedBox(height: 3),
          Text(title, style: SuperText.heading.copyWith(color: t.fg1)),
          const SizedBox(height: 12),
          for (final r in rows) ...[r, const SizedBox(height: 8)],
        ],
      ),
    );
  }
}
