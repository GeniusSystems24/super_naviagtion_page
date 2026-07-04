# AGENTS.md — super_naviagtion_page (ChatGPT / Codex)

Development guide for AI agents maintaining and extending the
**super_naviagtion_page** Flutter package. Read this before editing any file in
the package. It defines the architecture, conventions, components, testing, and
the required process for changing code.

## Package summary

`NavigationPage` is an independent, bounded **in-widget navigation container**. A
view opens another view above it as a mode-configurable overlay clipped to the
parent container. Each container owns a **private stack** (open / back / replace
/ popToRoot), passes typed data **down** (`params`) and returns typed results
**up** (`NavResult`), **nests without limit**, and supports **multiple
independent containers** on one screen with the global back routed only to the
**active** one (`NavigationHub`). A per-container **retention policy**
(preserve / suspend / recreate / dispose) plus `maxRetained` bounds memory.

It is a Dart port of the React `super-navigation-page` tool
(`react/src/tools/super-navigation-page/`); consult that source for intended
semantics.

## Golden rules (do not violate)

1. **Dependency direction:** Presentation → Application → Domain. Domain and the
   controller import **no Flutter widgets**. The controller may import
   `dart:async`, `dart:ui` (`Size`) and `package:flutter/foundation.dart` only.
2. **Every `open()` resolves once.** Deliver results only through
   `NavEntry.settle(...)`; never touch a `Completer` directly. Disposal settles
   pending entries as `cancelled('disposed')`.
3. **One transition per container.** Every mutation checks `_transitioning`;
   every unlock is scheduled through `_later(...)` so `dispose()` cancels it.
4. **Isolation.** A controller mutates only its own `_entries`. All
   cross-container state lives in `NavigationHub`.
5. **Active owns back.** `NavigationHub.handleBack()` pops only the active
   container. System-back is opt-in at the host (a `PopScope` calling
   `handleBack()`); never wrap a `BackButtonListener` inside `NavigationPage` —
   it needs a `Router` ancestor and crashes under `MaterialApp(home:)`. Hub
   notifications during build (register/unregister run in initState/dispose) are
   deferred via `addPostFrameCallback` — keep that guard.
6. **Retention is a View concern.** The controller always keeps the full logical
   stack; `NavigationPage.build` decides which covered views stay mounted from
   `retention` + `maxRetained`. `NavStack` stays pure (returns new lists, no side
   effects).

## Directory map

```
lib/super_naviagtion_page.dart                     # public barrel
lib/src/core/core.dart                             # re-exports super_core
lib/src/features/super_navigation_page/
  domain/entities/    nav_result · retention_policy · nav_presentation ·
                      nav_options · nav_entry · nav_events
  domain/usecases/    nav_stack                     # pure immutable stack algebra
  presentation/controllers/  navigation_controller  # SuperNavigationController (Model)
                             navigation_hub          # NavigationHub (coordinator)
  presentation/widgets/      navigation_page         # NavigationPage (View) + SuperNavigator
                             nav_overlay             # scrim + animated gesture panel
test/               domain_logic_test · controller_test · navigation_page_widget_test
example/lib/        main + widgets/demo_kit + orders/containers/wizard/modes/nested demos
README.md · CHANGELOG.md · skill/{claude_code,chatgpt_codex}
```

## Public components

Exported from `package:super_naviagtion_page/super_naviagtion_page.dart`:

- `NavigationPage` (+ `.of(context)` → `SuperNavigator`, `.paramsOf(context)`).
- `SuperNavigationController`, `NavigationHub` (singleton `NavigationHub.I`).
- `NavResult` (`NavSuccess` / `NavCancelled` / `NavError`), `NavStackSnapshot`.
- `RetentionPolicy`, `NavConcurrency`.
- `NavPresentation`, `NavPresentations`, `NavPresentationMode`, `NavPosition`,
  `NavTransitionKind`, `NavSwipe`.
- `NavOptions`, `NavCloseGuard`, `NavEntry`, `NavStack`, `NavEvent`,
  `NavEventData`, `NavEventListener`.

## The navigator API (what views call)

`NavigationPage.of(context)` returns a `SuperNavigator` bound to the calling
view's entry:
`open(view, {params, mode, presentation, size, key})`, `back`/`close`,
`replace`, `popToRoot`/`closeAll`, `submit`/`cancel`/`fail`,
`setGuard`/`clearGuard`/`forceClose`, and `params`/`paramsAs<T>()`/`isTop`/
`canGoBack`.

## Conventions

- Doc-comment (`///`) every public member — pub.dev documentation style. New
  public API without a doc comment is incomplete.
- `@immutable` value objects with `copyWith`; `final` fields; small
  single-purpose methods.
- No `print`; use `debugPrint`. Keep `flutter analyze` clean under the strict
  `analysis_options.yaml` (`strict-casts`, `strict-raw-types`).
- All visuals come from `super_core` (`SuperTokens`, `SuperText`, `SuperButton`,
  `StatusPill`, `context.superTheme`). Do not hard-code hex or `TextStyle`.
- Support light/dark and LTR/RTL — use `PositionedDirectional` / inline-aware
  positions, never left/right literals for drawers.

## Task recipes

**Add a presentation mode**
1. Add an entry to `NavPresentations._map` (name → `NavPresentation`).
2. Add a `NavPresentationMode` enum value with the same name.
3. If it needs a new position/transition/swipe, extend the `NavPosition` /
   `NavTransitionKind` / `NavSwipe` enum AND the matching `switch` in
   `nav_overlay.dart` (`_align`, `_radius`, `_applyTransition`, size logic).
4. No controller change. Add a test asserting the registry resolves it.

**Add a controller capability**
1. Add a verb method to `SuperNavigationController`; guard with `_disposed` and
   `_transitioning`; emit the correct `NavEvent`; schedule unlocks via `_later`;
   call `_safeNotify()`.
2. Expose it on `SuperNavigator` in `navigation_page.dart`.
3. Add a `controller_test.dart` case (use `duration: Duration.zero` + `_tick()`).

**Add a lifecycle event**
1. Extend `NavEvent`; emit from the controller with a `NavEventData`.
2. Map it in the example `EventLogPanel`.

**Add a retention policy**
1. Extend `RetentionPolicy`; update `keepsState` / `keepsMounted`.
2. Update the mounting branch in `NavigationPage.build`.

**Every change also:** updates README (feature table + usage), adds a CHANGELOG
entry (Keep a Changelog + SemVer), adds/updates tests, and runs
`flutter analyze && flutter test`.

## Testing strategy

- `test/domain_logic_test.dart` — pure domain (`NavStack`, `NavResult`,
  `RetentionPolicy`, `NavPresentations`, `NavEntry`); no binding.
- `test/controller_test.dart` — controller + hub. Transitions use real `Timer`s:
  pass `duration: Duration.zero` to `open` and `await _tick()` (2 ms) before
  asserting; call `NavigationHub.I.resetForTest()` in `setUp`.
- `test/navigation_page_widget_test.dart` — the widget; `pumpAndSettle` after
  navigation; assert mount/unmount + retention.

Add a test in the matching file for every behavioural change. Prefer
domain/controller tests over widget tests where possible.

## Anti-patterns (reject these in review)

- Widget imports in the controller/domain.
- Completing a `Completer` outside `NavEntry.settle`.
- An unlock scheduled without `_later` (leaks the lock; `dispose` can't cancel).
- Retention/unmount logic inside the controller.
- A mode that special-cases `NavOverlay` instead of going through the declared
  position/transition/swipe enums.
- Public API with no `///` doc comment, no CHANGELOG entry, or no test.
- Hard-coded colors/text styles instead of `super_core` tokens.
- Left/right literals that break RTL.
