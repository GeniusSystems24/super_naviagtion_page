# Changelog

All notable changes to **super_naviagtion_page** are documented here. Format
follows [Keep a Changelog](https://keepachangelog.com/); versioning is
[SemVer](https://semver.org/).

## [0.2.0] — 2026-07-16

### Changed

- Upgraded to **super_core 1.1.0**. No source changes required — surfaces are
  read via `SuperThemeData.of(context)`, which `SuperMaterialThemeData` (now a
  `ThemeData` subclass) registers automatically, so palette, brightness **and**
  the responsive `SuperDeviceMode` (mobile / tablet / desktop) tokens flow
  through with no extra wiring:

  ```dart
  MaterialApp(
    theme:     SuperMaterialThemeData.light(mode: SuperDeviceMode.desktop),
    darkTheme: SuperMaterialThemeData.dark(mode: SuperDeviceMode.desktop),
  );
  ```
- Minimum raised to `dart >=3.8.0`, `flutter >=3.32.0`.

---

## [0.1.1] — 2026-07-14

### Changed

- Upgraded to **super_core 1.0.0**. No source changes required — all overlay
  and sheet surfaces are read via `SuperThemeData.of(context)`, which is now
  auto-registered by `SuperMaterialThemeData`. Palette switching and light/dark
  mode work without any extra wiring:

  ```dart
  MaterialApp(
    theme:     SuperMaterialThemeData.light(palette: SuperPalette.purplePalette),
    darkTheme: SuperMaterialThemeData.dark(palette: SuperPalette.purplePalette),
    // NavigationPage overlays (dialog, bottom sheet, drawer, full-screen)
    // adapt automatically to the active palette and brightness.
  );
  ```

---

## [0.1.0] — 2026-07-04

### Added

- Initial release, ported from the React `super-navigation-page` tool as a
  focused GeniusLink design-system package built on `super_core`.
- **`NavigationPage`** — an independent, bounded in-widget navigation container.
  Renders a root view plus a stack of animated overlays clipped to its own
  bounds, registers itself with `NavigationHub`, marks itself active on pointer
  interaction, and routes the global back to the active container via
  `NavigationHub.handleBack()` (opt-in at the host — no `Router` dependency).
  Configurable `retention`, `maxRetained`,
  `defaultMode`, `concurrency`, `height` and `onEvent`. Accepts an external
  `controller` or owns one internally.
- **`SuperNavigator`** (`NavigationPage.of(context)`) — the navigator API bound
  to the calling view's entry: `open`, `back` / `close`, `replace`, `popToRoot`
  / `closeAll`, `submit` / `cancel` / `fail`, `setGuard` / `clearGuard` /
  `forceClose`, plus `params` / `paramsAs<T>()` / `isTop` / `canGoBack`.
  `NavigationPage.paramsOf(context)` reads the current view's input.
- **`SuperNavigationController`** — the `ChangeNotifier` Model owning one
  container's private stack, single-transition lock, duplicate-open guard,
  close-guards, lifecycle events and deterministic disposal. Typed results via
  `NavResult`; `serialize()` / `restore()` for screen recreation; `ignore` /
  `queue` concurrency.
- **`NavigationHub`** — the singleton coordinator tracking the active container
  and routing the global back action (`handleBack()`) to it, and only it.
  `setActive`, `activeId`, `isActive`, `register` / `unregister`.
- **Six presentation modes** via `NavPresentationMode` over the open
  `NavPresentations` registry: `dialog`, `bottomSheet` (drag-to-expand ·
  swipe-down), `drawer` / `drawerStart` (edge-swipe), `drawerTop`, `fullScreen`.
  Per-open `mode:` / `presentation:` overrides, container `defaultMode:`, and a
  process-wide `NavPresentations.setGlobalDefault(...)`. Register custom modes
  with `NavPresentations.register(...)` — no controller/widget changes.
- **Unlimited nesting** — the stack is a plain list with no depth cap; any view
  can open children indefinitely, each level in a different mode.
- **Retention strategies** (the memory knob) — `RetentionPolicy.preserve` /
  `suspend` / `recreate` / `dispose` plus an optional `maxRetained` cap governing
  how covered views are held. Back-compatible with a plain keep-alive default.
- **Close-guards** — a view can veto its own dismissal (unsaved changes); a
  blocked back emits `closeBlocked`, and `forceClose` bypasses the guard.
- **Lifecycle events** — `navigationStarted` · `navigationCompleted` ·
  `navigatingBack` · `viewClosed` · `navigationRejected` · `closeBlocked`, via
  `onEvent:` or `controller.addEventListener`.
- **Domain layer** (pure Dart): `NavResult` (sealed `success` / `cancelled` /
  `error` with `when`), `NavStack` (immutable stack algebra), `NavPresentation` /
  `NavPresentations`, `NavOptions`, `NavEntry`, `NavEvent` / `NavEventData`,
  `RetentionPolicy`.
- **`SuperThemeData` `ThemeExtension`** parity (light + dark) through
  `super_core`; full LTR + RTL, with inline-aware drawer positions and swipe
  directions.
- **Automated tests** — `test/domain_logic_test.dart` (domain), 
  `test/controller_test.dart` (controller + hub), and
  `test/navigation_page_widget_test.dart` (the View + retention).
- **Runnable `example/` gallery** with light/dark + LTR/RTL toggles and five
  demos on one widget: Sequential navigation, Independent containers, Multi-step
  workflow, Presentation modes, and Deep nesting & retention.
- **`README.md`** and AI development skills under `skill/claude_code/` and
  `skill/chatgpt_codex/`.
