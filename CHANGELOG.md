# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-17

### Major Release - Enterprise Ready

This release introduces **Wrap Mode** and **Progressive Migration**, making Nav Bridge
adoptable by existing enterprise applications without requiring a full rewrite.

### Added

#### Core Features
- **Wrap Mode**: `GoRouterAdapter.wrap()` - wrap existing GoRouter without changes
- **GuardContext with DI**: Full dependency injection support via `extras` map
- **Riverpod Support**: `RiverpodRouteGuard` base class with `Ref` access
- **Guard Bridges**: Adapt existing guards without modifications
  - `GoRouterGuardBridge` - for guards with `(BuildContext, GoRouterState, Ref)`
  - `SimpleGoRouterGuardBridge` - for guards without Ref
  - `GoRouterRedirectBridge` - for redirect functions
  - `GuardManagerBridge` - for guard manager patterns
- **InMemoryAdapter**: Unit test navigation without Flutter UI
- **Shell Navigation**: Full `StatefulShellRoute` support

#### Guard System
- `GuardResult` sealed class with `allow()`, `redirect()`, `reject()`
- Guard priority system (higher priority runs first)
- `appliesTo` and `excludes` pattern matching
- `CompositeGuard` (AND logic) and `AnyGuard` (OR logic)

#### Testing
- `InMemoryAdapter` with navigation history tracking
- `NavigationEvent` recording for detailed test assertions
- Mock-friendly guard interfaces

### Migration Guide

#### From v1.x
If you were using v1.x, the migration is straightforward:

```dart
// v1.x - Required creating new router
final adapter = GoRouterAdapter.create(routes: [...]);

// v2.0 - Can wrap existing router (recommended)
final adapter = GoRouterAdapter.wrap(existingGoRouter);
```

#### For New Adopters
See the [README](README.md) for the progressive migration guide.

### Breaking Changes
- `GuardResult` is now a sealed class (use pattern matching)
- `canActivate` now receives `GuardContext` instead of individual parameters

---

## [1.0.0] - 2025-01-01

### Added
- Initial release
- Basic `GoRouterAdapter` with create mode
- `RouteGuard` base class
- `RouteDefinition` for route configuration
- `InMemoryAdapter` for testing

---

## Upcoming

### [2.1.0] - Planned
- AutoRoute adapter
- Typed route code generation
- Analytics observers

### [2.2.0] - Planned
- Beamer adapter
- Transition abstraction
- Deep link validation

---

[2.0.0]: https://github.com/chekarhamza88-stack/nav_bridge/releases/tag/v2.0.0
[1.0.0]: https://github.com/chekarhamza88-stack/nav_bridge/releases/tag/v1.0.0
