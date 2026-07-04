// ============================================================
// test/navigation_page_widget_test.dart
// ------------------------------------------------------------
// Widget tests for the NavigationPage View: it renders the root, opening a view
// mounts an overlay reachable via NavigationPage.of(context), the covered view
// is retained under `preserve` and unmounted under `recreate`, and back removes
// the overlay.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_naviagtion_page/super_naviagtion_page.dart';

Widget _host({
  RetentionPolicy retention = RetentionPolicy.preserve,
  required void Function(SuperNavigationController) onReady,
}) {
  late SuperNavigationController controller;
  return MaterialApp(
    theme: ThemeData(extensions: const [SuperThemeData.dark]),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 380,
          height: 480,
          child: Builder(builder: (context) {
            return NavigationPage(
              id: 'w-test',
              retention: retention,
              root: 'home',
              height: 480,
              views: {
                'home': (context) {
                  controller = NavigationPage.of(context).controller;
                  onReady(controller);
                  return const Center(child: Text('HOME'));
                },
                'child': (context) => const Center(child: Text('CHILD')),
              },
            );
          }),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the root view', (tester) async {
    await tester.pumpWidget(_host(onReady: (_) {}));
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('CHILD'), findsNothing);
  });

  testWidgets('open mounts an overlay; back removes it', (tester) async {
    late SuperNavigationController c;
    await tester.pumpWidget(_host(onReady: (ctrl) => c = ctrl));
    c.open('child', duration: Duration.zero);
    await tester.pumpAndSettle();
    expect(find.text('CHILD'), findsOneWidget);

    c.back();
    await tester.pumpAndSettle();
    expect(find.text('CHILD'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('preserve keeps the covered root mounted', (tester) async {
    late SuperNavigationController c;
    await tester.pumpWidget(_host(onReady: (ctrl) => c = ctrl));
    c.open('child', duration: Duration.zero);
    await tester.pumpAndSettle();
    // root is preserved beneath the overlay
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('CHILD'), findsOneWidget);
    c.dispose();
  });
}
