// ============================================================
// example/lib/wizard_demo.dart
// ------------------------------------------------------------
// EXAMPLE 3 — A multi-step workflow (a store-setup wizard) as a bottom sheet
// that seeds a draft, opens a child location picker, and returns a final typed
// result. Editing arms an unsaved-changes close-guard so back is intercepted;
// Create can succeed or return a typed error; "Recreate screen" serializes the
// stack depth and restores it on a fresh controller, disposing the old one and
// settling its pending result.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

import 'widgets/demo_kit.dart';

const _templates = [
  ('retail', 'Retail Store', 'USD'),
  ('wholesale', 'Wholesale Depot', 'SAR'),
];
const _locations = [
  'Downtown Central',
  'Riverside Depot',
  'Main Branch',
  'North Hub'
];

class WizardDemo extends StatefulWidget {
  const WizardDemo({super.key});
  @override
  State<WizardDemo> createState() => _WizardDemoState();
}

class _WizardDemoState extends State<WizardDemo> {
  SuperNavigationController _controller =
      SuperNavigationController(id: 'wizard');
  int _pageKey = 0;

  void _recreate() {
    final snap = _controller.serialize();
    final old = _controller;
    setState(() {
      _controller = SuperNavigationController(id: 'wizard')..restore(snap);
      _pageKey++;
    });
    old.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final wide = MediaQuery.sizeOf(context).width > 720;

    final page = NavigationPage(
      key: ValueKey(_pageKey),
      id: 'wizard',
      controller: _controller,
      root: 'start',
      views: {
        'start': (c) => const _WizardStart(),
        'form': (c) => const _WizardForm(),
        'location': (c) => const _LocationPicker(),
      },
    );

    final rail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuperButton(
          label: 'Recreate screen',
          variant: SuperButtonVariant.secondary,
          icon: const Icon(Icons.restart_alt, size: 15),
          onPressed: _recreate,
        ),
        const SizedBox(height: 8),
        Text(
            'Open the wizard a level deep, then Recreate — the stack depth is serialized and restored on the fresh controller.',
            style: SuperText.caption.copyWith(color: t.fg4)),
        const SizedBox(height: 12),
        EventLogPanel(
            controllers: [_controller],
            height: wide ? 320 : 200,
            title: 'Lifecycle events'),
      ],
    );

    return DemoScaffold(
      title: 'Multi-step workflow',
      subtitle: 'Guarded form · child picker · typed result · restore',
      body: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: SizedBox(height: 470, child: page)),
              const SizedBox(width: 16),
              SizedBox(width: 320, child: rail),
            ])
          : ListView(children: [
              SizedBox(height: 440, child: page),
              const SizedBox(height: 14),
              rail
            ]),
    );
  }
}

class _WizardStart extends StatefulWidget {
  const _WizardStart();
  @override
  State<_WizardStart> createState() => _WizardStartState();
}

class _WizardStartState extends State<_WizardStart> {
  String? _result;

  Future<void> _start(
      BuildContext context, (String, String, String) tpl) async {
    setState(() => _result = null);
    final r = await NavigationPage.of(context).open(
      'form',
      params: {'nameEn': tpl.$2, 'currency': tpl.$3, 'location': ''},
      mode: NavPresentationMode.bottomSheet,
      dismissOnOutside: false,
      key: 'form',
    );
    setState(() {
      _result = r.when(
        success: (data) {
          final m = data as Map;
          return 'Created ${m['nameEn']} in ${(m['location'] as String).isEmpty ? "no location" : m['location']} · ${m['currency']}';
        },
        cancelled: (reason) =>
            'Setup ${reason == 'discarded' ? 'discarded' : 'cancelled'} — nothing saved',
        error: (e, _) => 'Failed: $e — no changes applied',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final cs = SuperMaterialThemeData.of(context).colorScheme;
    return ColoredBox(
      color: t.bg,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('STORES & PRODUCTS • SETUP',
              style: SuperText.eyebrow.copyWith(color: cs.primary)),
          const SizedBox(height: 5),
          Text('Create Store',
              style: SuperText.h1.copyWith(fontSize: 20, color: t.fg1)),
          const SizedBox(height: 5),
          Text(
              'Pick a template to seed the setup form. The wizard opens as a sheet, edits its own draft, and returns a result here.',
              style: SuperText.caption.copyWith(color: t.fg3)),
          const SizedBox(height: 16),
          Row(children: [
            for (final tpl in _templates) ...[
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
                  onTap: () => _start(context, tpl),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.storefront_outlined,
                              size: 18, color: cs.primary),
                          const SizedBox(height: 8),
                          Text(tpl.$2,
                              style: SuperText.body.copyWith(
                                  fontWeight: FontWeight.w700, color: t.fg1)),
                          const SizedBox(height: 3),
                          Text('seed · ${tpl.$3}',
                              style: SuperText.mono
                                  .copyWith(fontSize: 11, color: t.fg4)),
                        ]),
                  ),
                ),
              ),
              if (tpl != _templates.last) const SizedBox(width: 10),
            ],
          ]),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: t.inputBg,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
              ),
              child: Text(_result!,
                  style: SuperText.caption.copyWith(color: t.fg2)),
            ),
          ],
        ],
      ),
    );
  }
}

class _WizardForm extends StatefulWidget {
  const _WizardForm();
  @override
  State<_WizardForm> createState() => _WizardFormState();
}

class _WizardFormState extends State<_WizardForm> {
  late final Map _seed = NavigationPage.paramsOf(context) as Map;
  late final TextEditingController _name =
      TextEditingController(text: _seed['nameEn'] as String);
  late final TextEditingController _currency =
      TextEditingController(text: _seed['currency'] as String);
  String _location = '';
  bool _dirty = false;
  bool _failMode = false;
  bool _busy = false;
  bool _guardArmed = false;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
    if (!_guardArmed) {
      _guardArmed = true;
      NavigationPage.of(context).setGuard(_confirmDiscard);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.superTheme.surface,
      builder: (context) => _DiscardSheet(),
    );
    return discard ?? false;
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final nav = NavigationPage.of(context);
    if (_failMode) {
      nav.fail('Store service unavailable');
      return;
    }
    nav.forceClose(NavResult.success({
      'nameEn': _name.text,
      'currency': _currency.text,
      'location': _location,
    }));
  }

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final r = await NavigationPage.of(context).open('location',
        params: _location, mode: NavPresentationMode.drawer, key: 'location');
    if (r.isSuccess) {
      setState(() => _location = r.dataOrNull<String>() ?? _location);
      _markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final cs = SuperMaterialThemeData.of(context).colorScheme;
    final nav = NavigationPage.of(context);
    return Column(
      children: [
        OverlayHeader(
          eyebrow: 'Step 1 of 1 · setup sheet',
          title: 'Store details',
          tint: SuperThemeData.of(context).tokens.warning,
          trailing: _dirty
              ? const StatusPill('UNSAVED', tone: PillTone.warning)
              : const StatusPill('GUARDED', tone: PillTone.neutral),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('NAME', style: SuperText.label.copyWith(color: t.fg3)),
              const SizedBox(height: 6),
              TextField(
                  controller: _name,
                  onChanged: (_) => _markDirty(),
                  style: SuperText.body.copyWith(color: t.fg1),
                  decoration: _dec(context, 'Store name')),
              const SizedBox(height: 14),
              Text('CURRENCY', style: SuperText.label.copyWith(color: t.fg3)),
              const SizedBox(height: 6),
              TextField(
                  controller: _currency,
                  onChanged: (_) => _markDirty(),
                  style: SuperText.body.copyWith(color: t.fg1),
                  decoration: _dec(context, 'USD')),
              const SizedBox(height: 14),
              Text('LOCATION', style: SuperText.label.copyWith(color: t.fg3)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickLocation,
                borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusControl),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: t.inputBg,
                    border: Border.all(color: t.borderStrong),
                    borderRadius:
                        BorderRadius.circular(SuperThemeData.of(context).tokens.radiusControl),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            _location.isEmpty
                                ? 'Choose a location…'
                                : _location,
                            style: SuperText.body.copyWith(
                                color: _location.isEmpty ? t.fg4 : t.fg1))),
                    Icon(Icons.chevron_right, size: 16, color: t.fg4),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => _failMode = !_failMode),
                child: Row(children: [
                  Icon(
                      _failMode
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: _failMode ? cs.primary : t.fg4),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Simulate a service error on Create (returns an error result)',
                          style: SuperText.caption.copyWith(color: t.fg2))),
                ]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: t.border))),
          child: Row(children: [
            SuperButton(
                label: 'Cancel',
                variant: SuperButtonVariant.secondary,
                onPressed: () => nav.back()),
            const Spacer(),
            SuperButton(
                label: _busy ? 'Creating…' : 'Create Store',
                onPressed: _name.text.isEmpty || _busy ? null : _create),
          ]),
        ),
      ],
    );
  }
}

class _DiscardSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: SuperThemeData.of(context).tokens.warning, size: 20),
              const SizedBox(width: 9),
              Text('Discard unsaved changes?',
                  style: SuperText.heading.copyWith(color: t.fg1)),
            ]),
            const SizedBox(height: 8),
            Text(
                'The back action was blocked by the view close-guard. Discard the draft to leave, or keep editing.',
                style: SuperText.caption.copyWith(color: t.fg3)),
            const SizedBox(height: 16),
            Row(children: [
              SuperButton(
                  label: 'Keep editing',
                  variant: SuperButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false)),
              const Spacer(),
              SuperButton(
                  label: 'Discard',
                  onPressed: () => Navigator.of(context).pop(true)),
            ]),
          ]),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final cs = SuperMaterialThemeData.of(context).colorScheme;
    final nav = NavigationPage.of(context);
    final current = nav.params as String;
    return Column(children: [
      OverlayHeader(
          eyebrow: 'Child view · depth 3',
          title: 'Choose location',
          onBack: () => nav.back()),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            for (final loc in _locations) ...[
              InkWell(
                onTap: () => nav.submit(loc),
                borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: loc == current ? t.selectionFill(0.12) : t.surface,
                    border: Border.all(
                        color: loc == current ? cs.primary : t.border),
                    borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusMd),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Text(loc,
                            style: SuperText.body.copyWith(color: t.fg1))),
                    if (loc == current)
                      Icon(Icons.check, size: 16, color: cs.primary),
                  ]),
                ),
              ),
              const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    ]);
  }
}

InputDecoration _dec(BuildContext context, String hint) {
  final t = context.superTheme;
  final cs = SuperMaterialThemeData.of(context).colorScheme;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(SuperThemeData.of(context).tokens.radiusControl),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: SuperText.caption.copyWith(color: t.fg4),
    filled: true,
    fillColor: t.inputBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    enabledBorder: border(t.borderStrong),
    focusedBorder: border(cs.primary),
  );
}
