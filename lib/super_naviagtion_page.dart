/// Super Naviagtion Page — a GeniusLink design-system Flutter package providing
/// **NavigationPage**, an independent, self-contained navigation container that
/// lives inside a bounded area of the screen.
///
/// Any view can open another view above it as a popup / overlay clipped to its
/// parent NavigationPage. Each container owns a private navigation stack with
/// back / back-to-root, replace, close-all; passes typed data down and returns
/// typed [NavResult]s up; nests without limit; and presents each level in a
/// configurable mode — bottom sheet, drawer, full-screen overlay or dialog.
///
/// Multiple NavigationPages coexist on one screen as isolated mini-apps: each
/// keeps its own stack, active view, lifecycle events, back handling and
/// pending results, and the system-back action routes only to the active one
/// via [NavigationHub]. A per-container retention policy (preserve / suspend /
/// recreate / dispose) plus an optional `maxRetained` cap keeps deep stacks
/// memory-conscious.
///
/// Architecture: Clean Architecture per feature
///   domain/       — entities (NavResult, NavPresentation, NavEntry, NavOptions,
///                   RetentionPolicy, NavEvent) + usecases (NavStack) — pure Dart
///   presentation/ — controllers (SuperNavigationController = the Model/state,
///                   NavigationHub = active-container coordinator) + widgets
///                   (NavigationPage = the View, the overlay + transitions)
///
/// Shared, cross-feature code lives in `lib/src/core/` (a facade over
/// `super_core`).
///
/// Import this single barrel to get everything:
///   `import 'package:super_naviagtion_page/super_naviagtion_page.dart';`
library super_naviagtion_page;

// ── Core (theme tokens, shared widgets, utils) ──────────────────────────────
export 'src/core/core.dart';

// ── Feature: NavigationPage ─────────────────────────────────────────────────
export 'src/features/super_navigation_page/super_navigation_page.dart';
