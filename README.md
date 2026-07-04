# super_naviagtion_page

A **GeniusLink design-system** Flutter package providing **`NavigationPage`** — an independent, self-contained navigation container that lives inside a bounded area of the screen.

Any view can open another view above it as a **popup / overlay clipped to its parent `NavigationPage`**. Each container owns a **private navigation stack** with back / back-to-root / replace / close-all, passes typed data **down** and returns typed **`NavResult`s up**, **nests without limit**, and presents each level in a **configurable mode** — dialog, bottom sheet, drawer, top drawer or full-screen overlay.

Put **multiple `NavigationPage`s on one screen** and they behave as isolated mini-apps: each keeps its own stack, active view, lifecycle events, back handling and pending results, and the **system-back action routes only to the active one** via `NavigationHub`. A per-container **retention policy** (`preserve` / `suspend` / `recreate` / `dispose`) plus an optional `maxRetained` cap keeps deep stacks memory-conscious.

A faithful Dart port of the React `super-navigation-page` tool. Clean Architecture, SOLID, light + dark, LTR + RTL.

---

## Features

- **In-widget navigation container** — a view opens another view above it, bounded to the parent `NavigationPage` (not the whole screen).
- **Private stack per container** — `open` · `back` · `close` · `replace` · `popToRoot` / `closeAll`, with full history.
- **Typed data + results** — pass any `Object?` down; every `open(...)` resolves to a `NavResult` (`success` / `cancelled` / `error`).
- **Unlimited nesting** — the stack is a plain list with no depth cap; any view can open children indefinitely.
- **Six presentation modes** — `dialog`, `bottomSheet` (drag-to-expand · swipe-down), `drawer` / `drawerStart` (edge-swipe), `drawerTop`, `fullScreen`. Register your own — the registry is open/closed.
- **Multiple independent containers** — isolated stacks on one screen; the active one is tracked by `NavigationHub` and is the only one the system-back touches.
- **Retention strategies** — `preserve` · `suspend` · `recreate` · `dispose` + `maxRetained`, the memory knob for covered views.
- **Close-guards** — a view can veto its own dismissal (unsaved-changes) and `forceClose` bypasses it.
- **Concurrency-safe** — one transition per container (lock), duplicate-open suppression, `ignore`/`queue` policies.
- **Lifecycle events** — six events per container for logging / analytics.
- **Save / restore** — `serialize()` / `restore()` a stack across a screen recreation.
- **Deterministic disposal** — pending results settle as `cancelled('disposed')`; timers and listeners are freed.

---

## Install

```yaml
# pubspec.yaml
dependencies:
  super_naviagtion_page:
    path: ../super_naviagtion_page   # or a git/hosted ref
```

```dart
import 'package:super_naviagtion_page/super_naviagtion_page.dart';
```

### Register the theme extension

`NavigationPage` themes through a `ThemeExtension` from `super_core`. Register it once so colors track light/dark:

```dart
MaterialApp(
  theme:     ThemeData(brightness: Brightness.light, extensions: [SuperThemeData.light]),
  darkTheme: ThemeData(brightness: Brightness.dark,  extensions: [SuperThemeData.dark]),
);
```

> Fonts: the design system uses Manrope (display), Inter (body), JetBrains Mono (numerics) and Noto Naskh Arabic. Drop the `.ttf` files under `assets/fonts/` and add a `fonts:` block to `pubspec.yaml` to match it exactly; otherwise platform defaults are used.

---

## Quick start

Give a `NavigationPage` an `id`, a map of `views`, and a `root` key. Inside any view, read the navigator with `NavigationPage.of(context)`.

```dart
NavigationPage(
  id: 'orders',                         // unique — Hub registration + active routing
  root: 'list',                         // the base view, always present
  defaultMode: NavPresentationMode.drawer,
  retention: RetentionPolicy.preserve,
  views: {
    'list':    (context) => const OrdersList(),
    'details': (context) => const OrderDetails(),
    'confirm': (context) => const ConfirmDialog(),
  },
);
```

Open a view and await its result:

```dart
class OrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('PO-2024-0117'),
      onTap: () async {
        final nav = NavigationPage.of(context);
        final result = await nav.open('details', params: order, mode: NavPresentationMode.drawer);
        result.when(
          success:   (data)   => print('decision: $data'),
          cancelled: (reason) => print('cancelled: $reason'),
          error:     (e, _)   => print('failed: $e'),
        );
      },
    );
  }
}
```

Return a result from the opened view:

```dart
class ConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nav = NavigationPage.of(context);
    return Row(children: [
      TextButton(onPressed: () => nav.cancel('user'), child: const Text('Cancel')),
      FilledButton(onPressed: () => nav.submit({'confirmed': true}), child: const Text('Approve')),
    ]);
  }
}
```

`NavigationPage.of(context)` returns a `SuperNavigator` **bound to the calling view's entry**, so `params`, `close()`, `submit()` and `setGuard()` all refer to that view.

---

## The navigator API

Inside any view, `NavigationPage.of(context)` returns:

| Call | Behaviour |
|---|---|
| `open(view, {params, mode, presentation, size, key})` | Push a view; resolves to a `NavResult` when it closes. |
| `back([result])` · `close([result])` | Pop the top view, resolving its opener. |
| `popToRoot()` · `closeAll()` | Dismiss every popup back to the root. |
| `replace(view, {params, mode})` | Swap the current view, leaving no back entry. |
| `submit([data])` · `cancel([reason])` · `fail(error)` | Close self with a success / cancelled / error result. |
| `setGuard(fn)` · `clearGuard()` · `forceClose([result])` | Veto dismissal (unsaved changes), or bypass the veto. |
| `params` · `paramsAs<T>()` · `isTop` · `canGoBack` | Read the input data and this view's position. |

`NavigationPage.paramsOf(context)` reads the current view's params without the full navigator.

---

## Presentation modes

`NavPresentationMode` resolves to a registered `NavPresentation` describing position, transition, backdrop and gestures:

| Mode | Position | Gesture |
|---|---|---|
| `dialog` | center | scrim tap |
| `bottomSheet` | bottom | drag handle to expand · swipe down to dismiss |
| `drawer` | inline-end (right in LTR) | edge-swipe to dismiss |
| `drawerStart` | inline-start (left in LTR) | edge-swipe to dismiss |
| `drawerTop` | top | scrim tap |
| `fullScreen` | fill | none · covers the page as a new screen |

Choose per open: `nav.open('view', mode: NavPresentationMode.bottomSheet)`, set a container default with `defaultMode:`, or set a process-wide default with `NavPresentations.setGlobalDefault('drawer')`.

**Register a custom mode** — the registry is open/closed, so no controller or widget changes:

```dart
NavPresentations.register(const NavPresentation(
  name: 'peek',
  position: NavPosition.top,
  transition: NavTransitionKind.slideDown,
  dimOpacity: 0.3,
));

nav.open('preview', presentation: NavPresentations.get('peek'));
```

---

## Nested navigation

Depth is **unbounded** — any view can open a child, which can open a child, indefinitely. Each level can use a different mode:

```dart
nav.open('node', params: {'path': [...path, name], 'depth': depth + 1},
         mode: modeForDepth(depth + 1));
```

`back()` pops one level; `popToRoot()` returns to the base view. The whole stack stays isolated to its container.

### Retention (the memory knob)

What keeps a deep stack cheap is the per-container policy governing **covered** views:

| Policy | Covered view behaviour |
|---|---|
| `preserve` *(default)* | Stays mounted and painted beneath — full state kept. |
| `suspend` | Stays mounted but offstage — state kept, paint skipped. |
| `recreate` | Unmounted and rebuilt fresh when revealed — trades state for memory. |
| `dispose` | Released entirely — reappears brand-new. |

`maxRetained: N` caps how many covered views stay mounted; anything buried deeper is unmounted regardless of policy.

```dart
NavigationPage(
  id: 'catalog',
  root: 'home',
  retention: RetentionPolicy.suspend,
  maxRetained: 3,
  views: { /* … */ },
);
```

---

## Multiple independent containers

Put several `NavigationPage`s on one screen. Each owns its own stack; whichever the user touches last becomes **active** (an accent ring), and the global back action pops **only** that one:

```dart
Row(children: [
  Expanded(child: NavigationPage(id: 'warehouse', root: 'list', views: warehouseViews)),
  Expanded(child: NavigationPage(id: 'ledger',    root: 'list', views: ledgerViews)),
]);

// a toolbar / hardware back button:
NavigationHub.I.handleBack();          // pops the active container only
NavigationHub.I.setActive('ledger');   // make a container active programmatically
NavigationHub.I.activeId;              // which is active
```

Removing one container disposes its controller and settles its pending results as `cancelled('disposed')` — the other container is untouched. `BackButtonListener` is wired automatically, so the Android hardware back routes through the Hub to the active container.

---

## Close-guards (unsaved changes)

A view can veto its own dismissal. The guard returns `true` to allow, `false` to block (and may be async to show a confirmation):

```dart
nav.setGuard(() async {
  if (!dirty) return true;
  final discard = await showConfirmSheet(context);
  return discard;                    // false keeps the view open
});

// on an intentional save, bypass the guard:
nav.forceClose(NavResult.success(draft));
```

A blocked back emits a `closeBlocked` lifecycle event.

---

## Lifecycle events

Every container emits six events. Subscribe with the `NavigationPage`'s `onEvent:` callback or `controller.addEventListener`:

`navigationStarted` · `navigationCompleted` · `navigatingBack` · `viewClosed` · `navigationRejected` · `closeBlocked`.

```dart
NavigationPage(
  id: 'orders', root: 'list', views: views,
  onEvent: (event, data) => analytics.log('$event ${data.viewKey}'),
);
```

---

## Concurrency & safety

- **One transition per container** — a per-controller lock serialises transitions; a request mid-transition is dropped (`ignore`) or queued (`queue`).
- **Duplicate suppression** — identical `open` calls (same `key`) inside a short window collapse to one.
- **Per-container synchronisation** — a busy container never blocks another.
- **Guaranteed settlement** — every `open()` resolves; unexpected teardown settles it as `cancelled('disposed')`, and a failed step returns `error(e)`.

---

## Save & restore

```dart
final snapshot = controller.serialize();          // stack + options
final restored = SuperNavigationController(id: 'orders')..restore(snapshot);
```

Restored overlays are pre-settled — anything awaiting a pre-restore `open()` was already resolved. See the **Multi-step workflow** example's "Recreate screen" button.

---

## Architecture

Clean Architecture, split per feature; the navigation logic is a **frameworkless core** the widget layer binds to:

```
lib/
├── super_naviagtion_page.dart                    # public barrel — import this
└── src/
    ├── core/                                     # facade over super_core (theme, widgets)
    └── features/
        └── super_navigation_page/
            ├── domain/
            │   ├── entities/                     # NavResult · NavPresentation · NavEntry ·
            │   │                                 #   NavOptions · RetentionPolicy · NavEvent
            │   └── usecases/                     # NavStack (pure stack algebra)
            └── presentation/
                ├── controllers/                  # SuperNavigationController (the Model/state)
                │                                 # NavigationHub (active-container coordinator)
                └── widgets/                      # NavigationPage (the View) · NavOverlay
```

- **Domain** — `NavStack`, `NavResult`, `NavPresentation`, `RetentionPolicy` are pure Dart with no Flutter. The stack algebra has no timers or events, so it is unit-testable in isolation.
- **Application** — `SuperNavigationController` is a `ChangeNotifier` owning one container's private stack, transition lock, dedupe guard, close-guards, events and disposal. It imports no widgets.
- **Coordination** — `NavigationHub` is the single source of truth for the active container and the global back route.
- **Presentation** — `NavigationPage` renders the controller's logical stack as an animated overlay stack; `NavOverlay` interprets each `NavPresentation` generically. Dependencies point inward only: Presentation → Application → Domain.

---

## Example

A runnable gallery lives in `example/` — it registers the theme extension, toggles light/dark and LTR/RTL, and links five demos that all use **one** `NavigationPage` widget:

```bash
cd example
flutter run
```

1. **Sequential navigation** — list → details → confirm in one container; data down, typed result up, note preserved, duplicate suppressed.
2. **Independent containers** — a Warehouse and a Ledger side by side; active-container back routing; remove one safely.
3. **Multi-step workflow** — a guarded store-setup wizard with a child picker, a typed error result, and screen recreate/restore.
4. **Presentation modes** — one view opened in every mode.
5. **Deep nesting & retention** — a mini-app nested without limit with a live retention-strategy + memory-cap switch.

---

## Testing

```bash
flutter test
```

- `test/domain_logic_test.dart` — pure-Dart tests for `NavResult`, the `NavStack` algebra, `RetentionPolicy`, the presentation registry and `NavEntry` settlement.
- `test/controller_test.dart` — `SuperNavigationController` + `NavigationHub` behaviour: open/close with typed results, duplicate + concurrency guards, replace, popToRoot, close-guards, disposal, serialize/restore, events, and active-container back routing.
- `test/navigation_page_widget_test.dart` — the `NavigationPage` View: renders the root, mounts/removes overlays, and honours the retention policy.

---

## Limitations

- The system-back integration is wired via `BackButtonListener` (Android hardware back / declarative back). It does **not** push browser `history` entries; deep-linking to a nested overlay is out of scope — combine with `go_router` at the page level if you need URL sync.
- Transition timing lives in the controller (lock) and is mirrored by the overlay's `AnimationController`; custom transitions should register a `NavTransitionKind` duration that matches.
- `serialize()` captures view keys, params and options; it does **not** snapshot a view's internal `State` — restored overlays rebuild fresh (their opener was already settled).
- Fonts are not bundled; see **Install**.

---

## License

Internal GeniusLink design-system package.
