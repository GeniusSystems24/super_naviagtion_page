// ============================================================
// features/super_navigation_page/super_navigation_page.dart
// ------------------------------------------------------------
// Public barrel for the NavigationPage feature.
//
// An independent, bounded navigation container. Any view opens another view
// above it as a mode-configurable overlay (bottom sheet · drawer · full-screen
// · dialog), with a private stack, typed results, unlimited nesting and a
// per-container retention policy. Multiple containers run in isolation; the
// system-back action routes only to the active one via `NavigationHub`.
// ============================================================

// Domain — entities
export 'domain/entities/nav_result.dart';
export 'domain/entities/retention_policy.dart';
export 'domain/entities/nav_presentation.dart';
export 'domain/entities/nav_options.dart';
export 'domain/entities/nav_entry.dart';
export 'domain/entities/nav_events.dart';

// Domain — usecases
export 'domain/usecases/nav_stack.dart';

// Presentation — controllers (the Model + coordinator)
export 'presentation/controllers/navigation_controller.dart';
export 'presentation/controllers/navigation_hub.dart';

// Presentation — widgets (the View)
export 'presentation/widgets/navigation_page.dart';
