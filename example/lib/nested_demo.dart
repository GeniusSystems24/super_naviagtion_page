// ============================================================
// example/lib/nested_demo.dart
// ------------------------------------------------------------
// EXAMPLE 5 — A self-contained mini-app nested without limit. One NavigationPage
// you can drill into as deep as you like; every level opens the next in a
// rotating mode and keeps its own edit counter. A live control switches the
// retention strategy (preserve / suspend / recreate / dispose) and a memory
// cap, so you can watch which levels keep their edits and how many stay mounted.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

import 'widgets/demo_kit.dart';

const _modeCycle = [
  NavPresentationMode.bottomSheet,
  NavPresentationMode.drawer,
  NavPresentationMode.fullScreen,
];
NavPresentationMode _modeForDepth(int d) => _modeCycle[(d - 1) % _modeCycle.length];

const _pool = ['Assets', 'Ledgers', 'Inventory', 'Reports', 'Settlements', 'Archive'];
List<String> _childrenFor(int depth) =>
    [0, 1, 2].map((i) => '${_pool[(depth * 2 + i) % _pool.length]}${depth > 1 ? ' $depth.${i + 1}' : ''}').toList();

class NestedDemo extends StatefulWidget {
  const NestedDemo({super.key});
  @override
  State<NestedDemo> createState() => _NestedDemoState();
}

class _NestedDemoState extends State<NestedDemo> {
  final _controller = SuperNavigationController(id: 'nested');
  RetentionPolicy _retention = RetentionPolicy.preserve;
  int? _cap;
  int _depth = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() => _depth = _controller.depth - 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _retentions = [
    (RetentionPolicy.preserve, 'Preserve', 'Covered levels stay mounted and painted — full state kept.'),
    (RetentionPolicy.suspend, 'Suspend', 'Covered levels stay mounted but offstage — state kept, paint skipped.'),
    (RetentionPolicy.recreate, 'Recreate', 'Covered levels unmount and rebuild fresh — edits reset.'),
    (RetentionPolicy.dispose, 'Dispose', 'Covered levels released — revealed brand-new.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final wide = MediaQuery.sizeOf(context).width > 720;
    final stateKept = _retention.keepsState;
    final mounted = stateKept ? (_cap == null ? _depth : _depth.clamp(0, _cap!)) : (_depth == 0 ? 0 : 1);
    final desc = _retentions.firstWhere((r) => r.$1 == _retention).$3;

    final page = NavigationPage(
      id: 'nested',
      controller: _controller,
      root: 'catalog',
      retention: _retention,
      maxRetained: _cap,
      views: {
        'catalog': (c) => const _NestedRoot(),
        'node': (c) => const _NestedNode(),
      },
    );

    final rail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('RETENTION STRATEGY', style: SuperText.label.copyWith(color: t.fg3)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final r in _retentions)
                _Choice(label: r.$2, selected: _retention == r.$1, onTap: () => setState(() => _retention = r.$1)),
            ]),
            const SizedBox(height: 8),
            Text(desc, style: SuperText.caption.copyWith(color: t.fg3)),
            const SizedBox(height: 14),
            Text('MAX RETAINED (MEMORY CAP)', style: SuperText.label.copyWith(color: t.fg3)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              _Choice(label: '∞', selected: _cap == null, onTap: () => setState(() => _cap = null)),
              _Choice(label: '3', selected: _cap == 3, onTap: () => setState(() => _cap = 3)),
              _Choice(label: '1', selected: _cap == 1, onTap: () => setState(() => _cap = 1)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              DemoStat(label: 'Depth', value: '$_depth', color: SuperMaterialThemeData.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              DemoStat(label: 'In memory', value: '$mounted', color: stateKept ? SuperTokens.success : SuperTokens.warning),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        EventLogPanel(controllers: [_controller], height: wide ? 220 : 180),
      ],
    );

    return DemoScaffold(
      title: 'Deep nesting & retention',
      subtitle: 'A mini-app nested without limit',
      body: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: SizedBox(height: 480, child: page)),
              const SizedBox(width: 16),
              SizedBox(width: 320, child: rail),
            ])
          : ListView(children: [SizedBox(height: 440, child: page), const SizedBox(height: 14), rail]),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.selectionFill(0.14) : t.inputBg,
          border: Border.all(color: selected ? SuperMaterialThemeData.of(context).colorScheme.primary : t.border),
          borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
        ),
        child: Text(label, style: SuperText.caption.copyWith(
            color: selected ? SuperMaterialThemeData.of(context).colorScheme.primary : t.fg2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

class _NestedRoot extends StatelessWidget {
  const _NestedRoot();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return ColoredBox(
      color: t.bg,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('CATALOG • ROOT', style: SuperText.eyebrow.copyWith(color: SuperMaterialThemeData.of(context).colorScheme.primary)),
          const SizedBox(height: 5),
          Text('A mini-app in one container', style: SuperText.h1.copyWith(fontSize: 20, color: t.fg1)),
          const SizedBox(height: 5),
          Text('Drill in as deep as you like — every level opens the next in a rotating mode and keeps its own edits.',
              style: SuperText.caption.copyWith(color: t.fg3)),
          const SizedBox(height: 16),
          for (final name in _childrenFor(0)) ...[
            DemoRow(
              code: name,
              label: 'Open level 1',
              leadingIcon: Icons.folder_outlined,
              onTap: () => NavigationPage.of(context)
                  .open('node', params: {'path': [name], 'depth': 1}, mode: _modeForDepth(1)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _NestedNode extends StatefulWidget {
  const _NestedNode();
  @override
  State<_NestedNode> createState() => _NestedNodeState();
}

class _NestedNodeState extends State<_NestedNode> {
  int _edits = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final nav = NavigationPage.of(context);
    final p = nav.params as Map;
    final path = (p['path'] as List).cast<String>();
    final depth = p['depth'] as int;
    final mode = _modeForDepth(depth);
    final kids = _childrenFor(depth);

    return Column(children: [
      OverlayHeader(
        eyebrow: 'root / ${path.join(' / ')}',
        title: path.last,
        onBack: () => nav.back(),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          StatusPill('L$depth', tone: PillTone.accent),
          const SizedBox(width: 6),
          StatusPill(mode.name, tone: PillTone.warning),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.inputBg,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('LOCAL EDITS ON THIS LEVEL', style: SuperText.pill.copyWith(color: t.fg4)),
                    const SizedBox(height: 2),
                    Text('$_edits', style: SuperText.mono.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: _edits > 0 ? SuperTokens.success : t.fg2)),
                  ]),
                ),
                SuperButton(label: 'Edit', variant: SuperButtonVariant.secondary, onPressed: () => setState(() => _edits++)),
              ]),
            ),
            const SizedBox(height: 14),
            Text('OPEN A DEEPER LEVEL', style: SuperText.label.copyWith(color: t.fg3)),
            const SizedBox(height: 8),
            for (final name in kids) ...[
              DemoRow(
                code: name,
                label: 'L${depth + 1} · ${_modeForDepth(depth + 1).name}',
                leadingIcon: Icons.folder_outlined,
                onTap: () => nav.open('node',
                    params: {'path': [...path, name], 'depth': depth + 1},
                    mode: _modeForDepth(depth + 1),
                    key: 'node-${path.length}-$name'),
              ),
              const SizedBox(height: 7),
            ],
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
        child: Row(children: [
          SuperButton(label: 'Back', variant: SuperButtonVariant.secondary, onPressed: () => nav.back()),
          const SizedBox(width: 8),
          SuperButton(label: 'To root', variant: SuperButtonVariant.secondary, onPressed: () => nav.popToRoot()),
        ]),
      ),
    ]);
  }
}
