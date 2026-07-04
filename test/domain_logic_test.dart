// ============================================================
// test/domain_logic_test.dart
// ------------------------------------------------------------
// Pure-Dart unit tests for the NavigationPage domain layer: NavResult,
// NavStack algebra, RetentionPolicy, the presentation registry, and NavEntry
// result settlement. No Flutter binding required.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

NavEntry _entry(String key, {bool root = false}) => NavEntry(
      id: key,
      viewKey: key,
      isRoot: root,
      options: NavOptions(presentation: NavPresentations.get('dialog')),
    );

void main() {
  group('NavResult', () {
    test('success carries data and folds correctly', () {
      final r = NavResult.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.dataOrNull<int>(), 42);
      expect(
        r.when(success: (d) => 'ok:$d', cancelled: (_) => 'c', error: (_, __) => 'e'),
        'ok:42',
      );
    });

    test('cancelled carries a reason', () {
      final r = NavResult.cancelled('dismissed');
      expect(r.isCancelled, isTrue);
      expect((r as NavCancelled).reason, 'dismissed');
    });

    test('error carries the original error', () {
      final err = StateError('boom');
      final r = NavResult.error(err);
      expect(r.isError, isTrue);
      expect((r as NavError).error, err);
    });

    test('dataOrNull returns null for non-success and wrong type', () {
      expect(NavResult.cancelled().dataOrNull<int>(), isNull);
      expect(NavResult.success('str').dataOrNull<int>(), isNull);
    });

    test('value equality by payload', () {
      expect(NavResult.success(1), NavResult.success(1));
      expect(NavResult.cancelled('x'), NavResult.cancelled('x'));
      expect(NavResult.success(1) == NavResult.success(2), isFalse);
    });
  });

  group('NavStack algebra', () {
    late List<NavEntry> base;
    setUp(() => base = [_entry('root', root: true)]);

    test('push / pop are pure (do not mutate input)', () {
      final pushed = NavStack.push(base, _entry('a'));
      expect(base.length, 1); // unchanged
      expect(pushed.length, 2);
      final popped = NavStack.pop(pushed);
      expect(popped.length, 1);
      expect(pushed.length, 2); // unchanged
    });

    test('pop on empty is a no-op', () {
      expect(NavStack.pop(<NavEntry>[]), isEmpty);
    });

    test('replaceTop swaps only the last', () {
      final s = NavStack.push(base, _entry('a'));
      final r = NavStack.replaceTop(s, _entry('b'));
      expect(r.length, 2);
      expect(r.last.viewKey, 'b');
      expect(r.first.isRoot, isTrue);
    });

    test('overlays / clearOverlays partition the root', () {
      var s = NavStack.push(base, _entry('a'));
      s = NavStack.push(s, _entry('b'));
      expect(NavStack.overlays(s).map((e) => e.viewKey), ['a', 'b']);
      expect(NavStack.clearOverlays(s).length, 1);
      expect(NavStack.clearOverlays(s).single.isRoot, isTrue);
    });

    test('canGoBack / depth / peek / root', () {
      expect(NavStack.canGoBack(base), isFalse);
      final s = NavStack.push(base, _entry('a'));
      expect(NavStack.canGoBack(s), isTrue);
      expect(NavStack.depth(s), 2);
      expect(NavStack.peek(s)!.viewKey, 'a');
      expect(NavStack.root(s)!.isRoot, isTrue);
    });
  });

  group('RetentionPolicy', () {
    test('keepsState / keepsMounted', () {
      expect(RetentionPolicy.preserve.keepsState, isTrue);
      expect(RetentionPolicy.suspend.keepsState, isTrue);
      expect(RetentionPolicy.recreate.keepsState, isFalse);
      expect(RetentionPolicy.dispose.keepsState, isFalse);
      expect(RetentionPolicy.dispose.keepsMounted, isFalse);
    });
  });

  group('NavPresentations registry (open/closed)', () {
    test('built-ins are registered', () {
      for (final n in ['dialog', 'bottomSheet', 'drawer', 'fullScreen']) {
        expect(NavPresentations.names(), contains(n));
        expect(NavPresentations.get(n).name, n);
      }
    });

    test('unknown falls back to dialog', () {
      expect(NavPresentations.get('nope').name, 'dialog');
    });

    test('a custom presentation can be registered and resolved', () {
      NavPresentations.register(const NavPresentation(
        name: 'peek',
        position: NavPosition.top,
        transition: NavTransitionKind.slideDown,
      ));
      expect(NavPresentations.get('peek').position, NavPosition.top);
    });

    test('mode maps to its registered presentation', () {
      expect(NavPresentationMode.bottomSheet.presentation.position, NavPosition.bottom);
      expect(NavPresentationMode.drawer.presentation.swipe, NavSwipe.inlineEnd);
    });
  });

  group('NavEntry', () {
    test('settles exactly once', () async {
      final e = _entry('a');
      expect(e.isSettled, isFalse);
      e.settle(NavResult.success('first'));
      e.settle(NavResult.success('second')); // ignored
      expect(e.isSettled, isTrue);
      expect((await e.result).dataOrNull<String>(), 'first');
    });
  });
}
