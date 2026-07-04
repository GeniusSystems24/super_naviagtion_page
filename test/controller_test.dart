// ============================================================
// test/controller_test.dart
// ------------------------------------------------------------
// Behavioural tests for SuperNavigationController and NavigationHub: open/close
// with typed results, data passing, duplicate + concurrency guards, replace,
// popToRoot, close-guards, disposal, serialize/restore, lifecycle events, and
// active-container back routing across multiple containers.
//
// Transitions are driven by real Timers, so opens pass `duration: Duration.zero`
// and the helper `_tick()` yields the event loop to let them fire.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

Future<void> _tick() => Future<void>.delayed(const Duration(milliseconds: 2));

SuperNavigationController _make({
  NavConcurrency concurrency = NavConcurrency.ignore,
}) {
  final c = SuperNavigationController(id: 'test', concurrency: concurrency)
    ..setRoot('root');
  return c;
}

void main() {
  group('open / close', () {
    test('setRoot yields depth 1 and no back', () {
      final c = _make();
      expect(c.depth, 1);
      expect(c.canGoBack, isFalse);
      expect(c.top!.isRoot, isTrue);
      c.dispose();
    });

    test('open pushes and resolves with the result passed to close', () async {
      final c = _make();
      final future = c.open('details', params: 'PO-1', duration: Duration.zero);
      await _tick();
      expect(c.depth, 2);
      expect(c.canGoBack, isTrue);
      expect(c.top!.params, 'PO-1');

      c.close(NavResult.success('approved'));
      await _tick();
      final r = await future;
      expect(r.isSuccess, isTrue);
      expect(r.dataOrNull<String>(), 'approved');
      expect(c.depth, 1);
      c.dispose();
    });

    test('submit / cancel convenience results', () async {
      final c = _make();
      final f1 = c.open('a', duration: Duration.zero);
      await _tick();
      c.close(NavResult.success({'ok': true}));
      await _tick();
      expect((await f1).isSuccess, isTrue);

      final f2 = c.open('b', duration: Duration.zero);
      await _tick();
      c.close(NavResult.cancelled('user'));
      await _tick();
      expect((await f2).isCancelled, isTrue);
      c.dispose();
    });
  });

  group('guards against bad input', () {
    test('duplicate open within the dedupe window is dropped', () async {
      final c = _make();
      c.open('dupe', duration: Duration.zero, key: 'k');
      final second = c.open('dupe', duration: Duration.zero, key: 'k');
      final r = await second;
      expect(r.isCancelled, isTrue);
      expect((r as NavCancelled).reason, 'duplicate');
      c.dispose();
    });

    test('concurrency=ignore rejects a request mid-transition', () async {
      // non-zero duration keeps the lock held across the second call
      final c = _make();
      c.open('first', duration: const Duration(milliseconds: 40));
      final busy = await c.open('second', duration: Duration.zero, key: 'other');
      expect(busy.isCancelled, isTrue);
      expect((busy as NavCancelled).reason, 'busy');
      c.dispose();
    });

    test('back on the root returns false', () async {
      final c = _make();
      expect(await c.back(), isFalse);
      c.dispose();
    });
  });

  group('replace / popToRoot', () {
    test('replace swaps the top without adding history', () async {
      final c = _make();
      c.open('a', duration: Duration.zero);
      await _tick();
      c.replace('b');
      await _tick();
      expect(c.depth, 2);
      expect(c.top!.viewKey, 'b');
      c.dispose();
    });

    test('popToRoot clears every overlay', () async {
      final c = _make();
      c.open('a', duration: Duration.zero);
      await _tick();
      c.open('b', duration: Duration.zero, key: 'b');
      await _tick();
      c.open('c', duration: Duration.zero, key: 'c');
      await _tick();
      expect(c.depth, 4);
      await c.popToRoot();
      await _tick();
      expect(c.depth, 1);
      expect(c.canGoBack, isFalse);
      c.dispose();
    });
  });

  group('close-guards', () {
    test('a guard vetoes back; forceClose bypasses it', () async {
      final c = _make();
      c.open('form', duration: Duration.zero);
      await _tick();
      final id = c.top!.id;
      c.setGuard(id, () async => false); // always veto

      expect(await c.back(), isFalse); // blocked
      expect(c.depth, 2);

      expect(await c.close(NavResult.success(), true), isTrue);
      await _tick();
      expect(c.depth, 1);
      c.dispose();
    });
  });

  group('lifecycle events', () {
    test('emits started/completed/back/closed in order', () async {
      final c = _make();
      final events = <NavEvent>[];
      c.addEventListener((e, _) => events.add(e));
      c.open('a', duration: Duration.zero);
      await _tick();
      c.close(NavResult.success());
      await _tick();
      expect(events, containsAllInOrder([
        NavEvent.navigationStarted,
        NavEvent.navigationCompleted,
        NavEvent.navigatingBack,
        NavEvent.viewClosed,
      ]));
      c.dispose();
    });

    test('rejected event fires on a duplicate', () async {
      final c = _make();
      NavEventData? rejected;
      c.addEventListener((e, d) {
        if (e == NavEvent.navigationRejected) rejected = d;
      });
      c.open('x', duration: Duration.zero, key: 'k');
      await c.open('x', duration: Duration.zero, key: 'k');
      expect(rejected?.reason, 'duplicate');
      c.dispose();
    });
  });

  group('disposal', () {
    test('settles pending opens as cancelled(disposed)', () async {
      final c = _make();
      final pending = c.open('a', duration: Duration.zero);
      await _tick();
      c.dispose();
      final r = await pending;
      expect(r.isCancelled, isTrue);
      expect((r as NavCancelled).reason, 'disposed');
    });
  });

  group('serialize / restore', () {
    test('round-trips the stack depth and view keys', () async {
      final c = _make();
      c.open('a', params: 1, duration: Duration.zero);
      await _tick();
      c.open('b', params: 2, duration: Duration.zero, key: 'b');
      await _tick();
      final snap = c.serialize();
      expect(snap.frames.length, 3);

      final restored = SuperNavigationController(id: 'test2')..restore(snap);
      expect(restored.depth, 3);
      expect(restored.overlays.map((e) => e.viewKey), ['a', 'b']);
      expect(restored.overlays.first.params, 1);
      c.dispose();
      restored.dispose();
    });
  });

  group('NavigationHub — active routing', () {
    setUp(() => NavigationHub.I.resetForTest());

    test('first registered container is active; back routes only to it', () async {
      final a = _make();
      final b = SuperNavigationController(id: 'B')..setRoot('root');
      NavigationHub.I.register(a);
      NavigationHub.I.register(b);
      expect(NavigationHub.I.activeId, a.id);

      // open something in both
      a.open('a1', duration: Duration.zero);
      await _tick();
      b.open('b1', duration: Duration.zero, key: 'b1');
      await _tick();

      // A is active — back pops A, leaves B untouched
      expect(NavigationHub.I.handleBack(), isTrue);
      await _tick();
      expect(a.canGoBack, isFalse);
      expect(b.canGoBack, isTrue);

      // activate B — now back pops B
      NavigationHub.I.setActive(b.id);
      expect(NavigationHub.I.handleBack(), isTrue);
      await _tick();
      expect(b.canGoBack, isFalse);

      a.dispose();
      b.dispose();
    });

    test('unregistering the active container reassigns active', () {
      final a = _make();
      final b = SuperNavigationController(id: 'B')..setRoot('root');
      NavigationHub.I.register(a);
      NavigationHub.I.register(b);
      NavigationHub.I.unregister(a.id);
      expect(NavigationHub.I.activeId, b.id);
      a.dispose();
      b.dispose();
    });
  });
}
