// ============================================================
// example/lib/orders_demo.dart
// ------------------------------------------------------------
// EXAMPLE 1 — Sequential navigation inside a single NavigationPage.
// An orders list opens a detail drawer, which opens a confirm dialog three deep.
// Data is passed down, a typed result is returned up, the detail note survives
// being covered (retention = preserve), cancellation is distinguished from
// success, and a rapid double-open is suppressed by the dedupe key.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

import 'widgets/demo_kit.dart';

class _Order {
  const _Order(this.id, this.vendor, this.store, this.items, this.amount);
  final String id;
  final String vendor;
  final String store;
  final int items;
  final double amount;
}

const _orders = [
  _Order('PO-2024-0117', 'Northwind Traders', 'Downtown Central', 12, 5240.00),
  _Order('PO-2024-0118', 'Acme Industrial', 'Riverside Depot', 34, 18990.50),
  _Order('PO-2024-0119', 'Globex Materials', 'Main Branch', 3, 742.00),
];

String _money(double n) => '\$${n.toStringAsFixed(2)}';

class OrdersDemo extends StatefulWidget {
  const OrdersDemo({super.key});
  @override
  State<OrdersDemo> createState() => _OrdersDemoState();
}

class _OrdersDemoState extends State<OrdersDemo> {
  final _controller = SuperNavigationController(id: 'orders', defaultMode: NavPresentationMode.drawer);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 720;
    final page = NavigationPage(
      id: 'orders',
      controller: _controller,
      root: 'list',
      retention: RetentionPolicy.preserve,
      views: {
        'list': (c) => const _OrdersList(),
        'details': (c) => const _OrderDetails(),
        'confirm': (c) => const _ConfirmDecision(),
      },
    );
    final log = EventLogPanel(controllers: [_controller], height: wide ? 460 : 240);

    return DemoScaffold(
      title: 'Sequential navigation',
      subtitle: 'One container · list → details → confirm',
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SizedBox(height: 460, child: page)),
                const SizedBox(width: 16),
                SizedBox(width: 320, child: log),
              ],
            )
          : Column(children: [
              SizedBox(height: 420, child: page),
              const SizedBox(height: 14),
              log,
            ]),
    );
  }
}

// ── root: the list ──
class _OrdersList extends StatefulWidget {
  const _OrdersList();
  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList> {
  String? _last;

  Future<void> _open(BuildContext context, _Order o) async {
    final r = await NavigationPage.of(context).open('details', params: o, mode: NavPresentationMode.drawer);
    setState(() {
      _last = r.when(
        success: (data) {
          final m = data as Map;
          return '${o.id}: ${m['decision']}${(m['note'] as String).isNotEmpty ? " — ${m['note']}" : ''}';
        },
        cancelled: (reason) => '${o.id} review ${reason ?? 'cancelled'}',
        error: (e, _) => '${o.id} failed: $e',
      );
    });
  }

  void _doubleOpen(BuildContext context) {
    final nav = NavigationPage.of(context);
    nav.open('details', params: _orders.first, mode: NavPresentationMode.drawer, key: 'details');
    nav.open('details', params: _orders.first, mode: NavPresentationMode.drawer, key: 'details');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return ColoredBox(
      color: t.bg,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('PURCHASING • APPROVALS',
              style: SuperText.eyebrow.copyWith(color: SuperTokens.accent)),
          const SizedBox(height: 5),
          Text('Open Purchase Orders', style: SuperText.h1.copyWith(fontSize: 20, color: t.fg1)),
          const SizedBox(height: 5),
          Text('Select an order to review it in a drawer and post an approval decision.',
              style: SuperText.caption.copyWith(color: t.fg3)),
          const SizedBox(height: 16),
          for (final o in _orders) ...[
            DemoRow(
              code: o.id,
              label: '${o.vendor} · ${o.items} items',
              trailing: _money(o.amount),
              leadingIcon: Icons.receipt_long_outlined,
              onTap: () => _open(context, o),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          Row(children: [
            SuperButton(
              label: 'Rapid double-open',
              variant: SuperButtonVariant.secondary,
              onPressed: () => _doubleOpen(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('fires open() twice — the duplicate is dropped',
                  style: SuperText.caption.copyWith(color: t.fg4)),
            ),
          ]),
          if (_last != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: t.tint(SuperTokens.success, 0.12),
                border: Border.all(color: t.tintFill(SuperTokens.success, 0.45)),
                borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, size: 16, color: SuperTokens.success),
                const SizedBox(width: 9),
                Expanded(child: Text(_last!, style: SuperText.caption.copyWith(color: t.fg2))),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── depth 2: details drawer (holds a note that must survive being covered) ──
class _OrderDetails extends StatefulWidget {
  const _OrderDetails();
  @override
  State<_OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<_OrderDetails> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _decide(BuildContext context, String action) async {
    final nav = NavigationPage.of(context);
    final o = nav.paramsAs<_Order>()!;
    final r = await nav.open('confirm',
        params: {'id': o.id, 'amount': o.amount, 'action': action},
        mode: NavPresentationMode.dialog);
    if (r.isSuccess) {
      nav.submit({'decision': '${action}d', 'note': _note.text});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final nav = NavigationPage.of(context);
    final o = nav.paramsAs<_Order>()!;
    return Column(
      children: [
        OverlayHeader(
          eyebrow: 'Order detail',
          title: o.id,
          onBack: () => nav.back(),
          trailing: const StatusPill('DEPTH 2', tone: PillTone.accent),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.7,
                children: [
                  DemoCell(k: 'Vendor', v: o.vendor),
                  DemoCell(k: 'Store', v: o.store),
                  DemoCell(k: 'Line items', v: '${o.items}'),
                  DemoCell(k: 'Total', v: _money(o.amount), mono: true),
                ],
              ),
              const SizedBox(height: 14),
              Text('INTERNAL NOTE', style: SuperText.label.copyWith(color: t.fg3)),
              const SizedBox(height: 6),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                style: SuperText.body.copyWith(color: t.fg1),
                decoration: _inputDecoration(context, 'Add a note about this approval…'),
              ),
              const SizedBox(height: 8),
              Text('This note survives opening the confirm dialog on top (retention = preserve).',
                  style: SuperText.caption.copyWith(color: t.fg4)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
          child: Row(children: [
            SuperButton(label: 'Back', variant: SuperButtonVariant.secondary, onPressed: () => nav.back()),
            const Spacer(),
            SuperButton(label: 'Reject…', variant: SuperButtonVariant.secondary, onPressed: () => _decide(context, 'Reject')),
            const SizedBox(width: 8),
            SuperButton(label: 'Approve…', onPressed: () => _decide(context, 'Approve')),
          ]),
        ),
      ],
    );
  }
}

// ── depth 3: confirm dialog (returns a result up) ──
class _ConfirmDecision extends StatelessWidget {
  const _ConfirmDecision();
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final nav = NavigationPage.of(context);
    final p = nav.paramsAs<Map>()!;
    final danger = p['action'] == 'Reject';
    final color = danger ? SuperTokens.danger : SuperTokens.success;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: t.tintFill(color, 0.16),
              child: Icon(danger ? Icons.warning_amber_rounded : Icons.check, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['action']} this order?', style: SuperText.heading.copyWith(color: t.fg1)),
                Text('Depth 3 · returns a result to the drawer',
                    style: SuperText.caption.copyWith(color: t.fg3)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Text('You are about to ${(p['action'] as String).toLowerCase()} ${p['id']} for ${_money(p['amount'] as double)}.',
              style: SuperText.body.copyWith(color: t.fg2)),
          const SizedBox(height: 18),
          Row(children: [
            SuperButton(label: 'Discard all', variant: SuperButtonVariant.secondary, onPressed: () => nav.popToRoot()),
            const Spacer(),
            SuperButton(label: 'Cancel', variant: SuperButtonVariant.secondary, onPressed: () => nav.cancel('user')),
            const SizedBox(width: 8),
            SuperButton(label: p['action'] as String, onPressed: () => nav.submit({'confirmed': true})),
          ]),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String hint) {
  final t = context.superTheme;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
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
    focusedBorder: border(SuperTokens.accent),
  );
}
