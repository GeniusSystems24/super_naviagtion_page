// ============================================================
// example/lib/main.dart
// ------------------------------------------------------------
// Gallery launcher for super_naviagtion_page. Registers the SuperThemeData
// extension (light/dark parity), exposes a global Light/Dark + LTR/RTL toggle,
// and lists the demos that all use ONE NavigationPage widget:
//   1. Sequential navigation   — list → details → confirm in one container
//   2. Independent containers   — two isolated stacks, active-container back
//   3. Multi-step workflow      — guarded wizard, typed result, restore
//   4. Presentation modes       — one view, six modes
//   5. Deep nesting & retention — unlimited nesting + memory strategies
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

import 'containers_demo.dart';
import 'modes_demo.dart';
import 'nested_demo.dart';
import 'orders_demo.dart';
import 'wizard_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.dark;
  TextDirection _dir = TextDirection.ltr;

  ThemeData _theme(SuperThemeData s) => ThemeData(
        brightness: s.brightness,
        scaffoldBackgroundColor: s.bg,
        extensions: [s],
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Super Naviagtion Page',
      themeMode: _mode,
      theme: _theme(SuperThemeData.light),
      darkTheme: _theme(SuperThemeData.dark),
      builder: (context, child) => Directionality(textDirection: _dir, child: child!),
      home: _Launcher(
        mode: _mode,
        dir: _dir,
        onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
        onToggleDir: () => setState(() => _dir = _dir == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr),
      ),
    );
  }
}

class _Demo {
  const _Demo(this.title, this.subtitle, this.icon, this.builder);
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

class _Launcher extends StatelessWidget {
  const _Launcher({required this.mode, required this.dir, required this.onToggleTheme, required this.onToggleDir});
  final ThemeMode mode;
  final TextDirection dir;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleDir;

  static final _demos = [
    _Demo('Sequential navigation', 'One container · list → details → confirm · typed results',
        Icons.list_alt_outlined, (_) => const OrdersDemo()),
    _Demo('Independent containers', 'Two isolated stacks · active-container back routing',
        Icons.dashboard_outlined, (_) => const ContainersDemo()),
    _Demo('Multi-step workflow', 'Guarded wizard · child picker · error result · restore',
        Icons.assignment_outlined, (_) => const WizardDemo()),
    _Demo('Presentation modes', 'One view presented six ways · dialog/sheet/drawer/full',
        Icons.view_carousel_outlined, (_) => const ModesDemo()),
    _Demo('Deep nesting & retention', 'Unlimited nesting · preserve/suspend/recreate/dispose',
        Icons.account_tree_outlined, (_) => const NestedDemo()),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SuperTokens.space10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SUPER NAVIAGTION PAGE • GALLERY',
                      style: SuperText.eyebrow.copyWith(color: SuperTokens.accent)),
                  const SizedBox(height: SuperTokens.space2),
                  Text('NavigationPage Demos', style: SuperText.h1.copyWith(color: t.fg1)),
                  const SizedBox(height: SuperTokens.space2),
                  Text('Five scenarios, one widget — an independent, bounded navigation container.',
                      style: SuperText.body.copyWith(color: t.fg3)),
                  const SizedBox(height: SuperTokens.space8),
                  for (final d in _demos) ...[
                    _DemoCard(demo: d),
                    const SizedBox(height: SuperTokens.space3),
                  ],
                  const SizedBox(height: SuperTokens.space6),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SuperButton(
                      label: mode == ThemeMode.dark ? 'Light Theme' : 'Dark Theme',
                      variant: SuperButtonVariant.secondary,
                      onPressed: onToggleTheme,
                    ),
                    const SizedBox(width: SuperTokens.space3),
                    SuperButton(
                      label: dir == TextDirection.ltr ? 'العربية (RTL)' : 'English (LTR)',
                      variant: SuperButtonVariant.secondary,
                      onPressed: onToggleDir,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.demo});
  final _Demo demo;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: demo.builder)),
        child: Container(
          padding: const EdgeInsets.all(SuperTokens.space4),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
            border: Border.all(color: t.border),
            boxShadow: t.cardShadow,
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color.alphaBlend(SuperTokens.accent.withOpacity(0.14), t.surface),
                borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
              ),
              child: Icon(demo.icon, size: 22, color: SuperTokens.accent),
            ),
            const SizedBox(width: SuperTokens.space4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(demo.title, style: SuperText.heading.copyWith(color: t.fg1)),
                const SizedBox(height: 2),
                Text(demo.subtitle, style: SuperText.caption.copyWith(color: t.fg3)),
              ]),
            ),
            Icon(Icons.chevron_right, color: t.fg4),
          ]),
        ),
      ),
    );
  }
}
