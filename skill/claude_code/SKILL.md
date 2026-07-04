---
name: super-naviagtion-page-maintainer
description: >
  Maintain and extend the super_naviagtion_page Flutter package — NavigationPage,
  an independent, bounded in-widget navigation container with a private stack,
  typed results, unlimited nesting, six presentation modes, multiple independent
  containers (active-container back routing via NavigationHub), and configurable
  retention (preserve/suspend/recreate/dispose). Apply when adding a presentation
  mode, a controller capability, a lifecycle event, a retention policy, an
  example, or a test — or when fixing navigation behaviour. Enforces the package's
  Clean Architecture, SOLID and Clean-Code conventions.
---

# super_naviagtion_page — Maintainer Skill (Claude Code)

You are working **inside** the `super_naviagtion_page` package, not merely
consuming it. This skill tells you how the package is built, the invariants you
must not break, and the exact process for adding or changing a feature.

## 1. What the package is

`NavigationPage` is a self-contained navigation container bounded to a region of
the screen. A view opens another view **above it** as a mode-configurable
overlay clipped to the parent container. Each container has a **private stack**;
data goes **down** as `params`, results come **up** as `NavResult`; nesting is
unlimited; multiple containers coexist and the global back routes only to the
**active** one.

It is a faithful Dart port of the React `super-navigation-page` tool
(`react/src/tools/super-navigation-page/`). When in doubt about intended
behaviour, read the React source — the domain semantics are identical.

## 2. Architecture — the dependency rule

Clean Architecture per feature under
`lib/src/features/super_navigation_page/`. **Dependencies point inward only:
Presentation → Application → Domain.** Never import a widget from the domain, and
never let the controller import Flutter widgets.

```
domain/
  entities/
    nav_result.dart        # sealed NavResult: NavSuccess | NavCancelled | NavError
    retention_policy.dart  # RetentionPolicy enum (the memory knob)
    nav_presentation.dart  # NavPresentation + NavPresentations registry + modes
    nav_options.dart       # NavOptions (resolved per-view) + NavCloseGuard
    nav_entry.dart         # NavEntry (one stack frame + result Completer)
    nav_events.dart        # NavEvent + NavEventData + NavEventListener
  usecases/
    nav_stack.dart         # NavStack — pure, immutable stack algebra
presentation/
  controllers/
    navigation_controller.dart  # SuperNavigationController (ChangeNotifier = Model)
    navigation_hub.dart         # NavigationHub (active-container coordinator)
  widgets/
    navigation_page.dart        # NavigationPage (View) + SuperNavigator + scopes
    nav_overlay.dart            # one overlay: scrim + animated, gesture-driven panel
```

Layer responsibilities:

- **Domain** — pure Dart, unit-testable with no binding. `NavStack` has **no
  timers, events or mutation** — every method returns a new list. `NavResult` is
  a sealed class; use exhaustive `switch` / `when`.
- **Application** — `SuperNavigationController` is a `ChangeNotifier` owning ONE
  container's stack, the single-transition lock (`_transitioning`), the dedupe
  guard, close-guards, the event bus, timers, the queue, and disposal. It
  imports `dart:async`, `dart:ui` (Size) and `package:flutter/foundation.dart`
  only — **no widgets**.
- **Coordination** — `NavigationHub` is a singleton `ChangeNotifier`; the single
  source of truth for `activeId` and `handleBack()`.
- **Presentation** — `NavigationPage` renders the controller's logical stack as
  an animated overlay stack, reconciling logical pops with animated exits
  (`_RenderItem.dismissing`). `NavOverlay` interprets a `NavPresentation`
  **generically** (position/transition/swipe/heights) — a new mode must not need
  a new `NavOverlay` branch beyond the declared enums.

## 3. Invariants you must not break

1. **Every `open()` resolves exactly once.** The `NavEntry.settle()` guard makes
   this safe; never complete a `Completer` directly. Unexpected teardown must
   settle pending entries as `cancelled('disposed')` — see `dispose()`.
2. **One transition per container.** Guard every mutation with `_transitioning`;
   schedule unlocks through `_later(...)` so `dispose()` can cancel them.
3. **Isolation.** A controller touches only its own `_entries`. Cross-container
   coordination goes through `NavigationHub` and nothing else.
4. **The active container owns back.** `handleBack()` and the widget's
   `BackButtonListener` must no-op when the container is not active.
5. **Retention is presentation-only.** The controller never unmounts a covered
   view; `NavigationPage.build` decides mounting from `retention` + `maxRetained`.
   Keep the memory logic in the widget.
6. **Purity of `NavStack`.** No side effects; return new lists. Tests depend on
   this.

## 4. Clean-Code conventions

- Small, single-purpose methods; the controller's public API is verbs
  (`open`/`back`/`replace`/`popToRoot`), each doing one thing.
- Doc-comment every public member (`///`) — the package is documented pub.dev
  style; new public API without a doc comment is incomplete.
- Prefer immutability: `@immutable` value objects, `copyWith`, `final` fields.
- No `print` — use `debugPrint` (see `analysis_options.yaml`, which also enables
  `strict-casts`/`strict-raw-types`). Run `flutter analyze` clean.
- Reuse `super_core` for anything visual (`SuperTokens`, `SuperText`,
  `SuperButton`, `context.superTheme`); never hard-code hex or text styles.

## 5. Available components (public surface)

Exported from `package:super_naviagtion_page/super_naviagtion_page.dart`:

- Widget: `NavigationPage` (+ `NavigationPage.of` / `.paramsOf`), `SuperNavigator`.
- Controllers: `SuperNavigationController`, `NavigationHub` (`.I`).
- Domain: `NavResult` (`NavSuccess`/`NavCancelled`/`NavError`), `RetentionPolicy`,
  `NavPresentation` / `NavPresentations` / `NavPresentationMode` / `NavPosition` /
  `NavTransitionKind` / `NavSwipe`, `NavOptions` / `NavCloseGuard`, `NavEntry`,
  `NavEvent` / `NavEventData`, `NavStack`, `NavConcurrency`, `NavStackSnapshot`.

## 6. How to add or change a feature (process)

Follow this order every time:

1. **Locate the layer.** Stack behaviour → `nav_stack.dart` (pure). Runtime
   behaviour → `SuperNavigationController`. Active/back → `NavigationHub`.
   Rendering/gesture → `NavOverlay`. Mounting/retention → `NavigationPage`.
2. **Add a presentation mode** — register in `NavPresentations._map` (or via
   `NavPresentations.register` at runtime) and, if it introduces a new
   position/transition/swipe, extend the `NavPosition` / `NavTransitionKind` /
   `NavSwipe` enums AND the corresponding `switch` in `nav_overlay.dart`
   (`_align`, `_radius`, `_applyTransition`, size logic). Add a matching
   `NavPresentationMode` value. No controller change needed.
3. **Add a controller capability** — add a verb method, guard it with
   `_disposed` + `_transitioning`, emit the right `NavEvent`, schedule unlocks
   with `_later`, and call `_safeNotify()`. Mirror it on `SuperNavigator` so
   views can call it.
4. **Add a lifecycle event** — extend `NavEvent`, emit it from the controller,
   and handle it in the example `EventLogPanel` mapping.
5. **Add a retention policy** — extend `RetentionPolicy`, update `keepsState` /
   `keepsMounted`, and the mounting branch in `NavigationPage.build`.
6. **Update docs** — README (feature table + a usage section), CHANGELOG (a new
   version entry, Keep-a-Changelog + SemVer), and this skill if the process
   changes. Every new public member needs a `///` doc comment.
7. **Add tests** (see below) and run `flutter analyze` + `flutter test`.
8. **Add/extend an example** if the feature is user-visible.

## 7. Testing strategy

Tests live in `test/`:

- `domain_logic_test.dart` — pure domain. Add cases here for `NavStack`,
  `NavResult`, `RetentionPolicy`, `NavPresentations`, `NavEntry`. No binding.
- `controller_test.dart` — `SuperNavigationController` + `NavigationHub`.
  Transitions run on real `Timer`s, so **pass `duration: Duration.zero` to
  `open`** and `await` the `_tick()` helper (2 ms) to let the unlock fire. Reset
  the hub with `NavigationHub.I.resetForTest()` in `setUp`.
- `navigation_page_widget_test.dart` — the View. Use `pumpAndSettle` after
  `open`/`back`; assert overlays mount/unmount and retention keeps the covered
  root.

Every new behaviour needs a test in the matching file. Prefer testing the
controller/domain over the widget where possible — it is faster and clearer.

## 8. Common mistakes

- Adding widget imports to the controller or domain → breaks the dependency
  rule. Keep them framework-light.
- Completing a `Completer` directly instead of `NavEntry.settle` → double-resolve
  or dangling futures.
- Forgetting `_later` for an unlock → the lock leaks and `dispose()` can't cancel
  it (memory/settle bug).
- Putting retention/unmount logic in the controller → it belongs in the widget;
  the controller keeps the full logical stack.
- A new mode that special-cases `NavOverlay` with an ad-hoc branch instead of
  going through the declared position/transition/swipe enums → violates
  open/closed.
- Shipping public API without a `///` doc comment, a CHANGELOG entry, or a test.
- Hard-coding colors/text styles instead of `super_core` tokens.
