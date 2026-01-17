# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Routing Composer is a Flutter package that provides a router-agnostic navigation layer. It wraps existing GoRouter implementations to enable testable, decoupled navigation without rewriting routes.

## Build and Development Commands

```bash
# Get dependencies
flutter-perso pub get

# Run static analysis
flutter-perso analyze

# Run tests
flutter-perso test

# Run a single test file
flutter-perso test test/path/to/test_file.dart

# Format code
dart format lib test
```

## Architecture

### Core Layer (`lib/src/core/`)
- **RouterAdapter** - Abstract interface all router implementations must follow. Defines navigation methods (`go`, `push`, `pop`, `replace`) and guard management.
- **RouteGuard** - Base class for navigation guards. Guards have priority ordering (higher runs first), pattern-based route matching via `appliesTo`/`excludes`, and return `GuardResult` (allow/redirect/reject).
- **GuardContext** - Passed to guards during navigation. Contains route info and DI container (`extras` map) for injecting Riverpod Ref, BuildContext, or custom services.
- **GuardResult** - Sealed class with three outcomes: `GuardAllow`, `GuardRedirect`, `GuardReject`.

### Adapters (`lib/src/adapters/`)
- **GoRouterAdapter** - Three factory modes:
  - `wrap()` - Wraps existing GoRouter (recommended for migration)
  - `create()` - Creates new GoRouter from ComposerRouterConfig
  - `withGuards()` - Creates GoRouter with integrated guard system
- **InMemoryAdapter** - For unit testing navigation without Flutter widgets. Tracks navigation history and simulates guard behavior.

### Guards (`lib/src/guards/`)
- **RiverpodRouteGuard** - Base for guards needing Riverpod Ref. Override `canActivateWithRef()` instead of `canActivate()`.
- **GoRouterGuardBridge** - Bridges legacy guard functions `(BuildContext, GoRouterState, Ref) -> GuardResult` to RouteGuard.
- **SimpleGoRouterGuardBridge** - For guards without Riverpod dependency.
- **GoRouterRedirectBridge** - Converts GoRouter redirect functions to guards.

### Key Patterns

**Dependency Injection in Guards:**
```dart
adapter.contextBuilder = (state) => {
  'ref': ref,
  'goRouterState': state,
  'context': navigatorKey.currentContext,
};
```

**Guard Priority Convention:**
- 1000+: Critical guards (maintenance mode)
- 100-999: Auth guards
- 10-99: Permission guards
- 0-9: Feature guards

**Route Pattern Matching:**
- Exact: `/users`
- Wildcard: `/admin/*`
- Parameters: `/users/:id`

## Dependencies

- Flutter SDK >=3.10.0
- go_router ^15.0.0
- flutter_riverpod ^2.4.0 (optional, for Riverpod guards)
