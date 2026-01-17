# Nav Bridge

[![pub package](https://img.shields.io/pub/v/nav_bridge.svg)](https://pub.dev/packages/nav_bridge)
[![pub points](https://img.shields.io/pub/points/nav_bridge)](https://pub.dev/packages/nav_bridge/score)
[![popularity](https://img.shields.io/pub/popularity/nav_bridge)](https://pub.dev/packages/nav_bridge/score)
[![likes](https://img.shields.io/pub/likes/nav_bridge)](https://pub.dev/packages/nav_bridge/score)
[![CI](https://github.com/chekarhamza88-stack/nav_bridge/actions/workflows/ci.yml/badge.svg)](https://github.com/chekarhamza88-stack/nav_bridge/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/chekarhamza88-stack/nav_bridge/branch/main/graph/badge.svg)](https://codecov.io/gh/chekarhamza88-stack/nav_bridge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A **progressive, router-agnostic navigation layer** for Flutter that allows you to wrap existing GoRouter apps and migrate to a clean, testable, decoupled architecture — **without rewriting your routes**.

<p align="center">
  <img src="https://raw.githubusercontent.com/chekarhamza88-stack/nav_bridge/main/assets/screenshots/architecture.png" alt="Architecture" width="600">
</p>

## Why Nav Bridge?

Flutter apps are usually tightly coupled to a routing library:

```dart
// ❌ Your business logic depends on GoRouter
context.go('/users/42');
context.push('/settings');
```

This creates several problems:
- **Vendor lock-in**: Business logic depends on GoRouter/AutoRoute
- **Untestable**: Navigation requires Flutter widgets
- **Expensive migrations**: Changing routers means rewriting navigation
- **Tight coupling**: UI and routing are inseparable

**Nav Bridge solves this** with a thin abstraction layer:

```dart
// ✅ Your app talks to AppRouter, not GoRouter
appRouter.goToUserProfile('42');
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Wrap Mode** | Use your existing GoRouter without any changes |
| **Progressive Migration** | Migrate one feature at a time, old & new coexist |
| **Full DI Support** | Riverpod `Ref` available in all guards |
| **Guard Bridges** | Keep existing guards working immediately |
| **InMemoryAdapter** | Unit test navigation without Flutter |
| **Shell Navigation** | Full `StatefulShellRoute` support |

## Installation

```yaml
dependencies:
  nav_bridge: ^2.0.0
  go_router: ^15.0.0

  # Optional - for Riverpod guards
  flutter_riverpod: ^2.4.0
```

```bash
flutter pub get
```

## Quick Start

### Step 1: Wrap Your Existing Router

Zero changes to your existing code:

```dart
import 'package:nav_bridge/nav_bridge.dart';

// Your existing GoRouter (unchanged)
final goRouter = GoRouter(
  routes: [...],
  redirect: myRedirectLogic,
);

// Wrap it with Nav Bridge
final adapter = GoRouterAdapter.wrap(goRouter);

// Everything still works!
context.go('/profile/42');  // ✅ Still works
```

### Step 2: Add Guards with DI Support

```dart
final adapter = GoRouterAdapter.wrap(
  goRouter,
  additionalGuards: [AuthGuard(), RoleGuard()],
);

// Inject dependencies (Riverpod Ref, etc.)
adapter.contextBuilder = (state) => {
  'ref': ref,
  'goRouterState': state,
  'context': navigatorKey.currentContext,
};
```

### Step 3: Create Type-Safe Navigation (Optional)

```dart
abstract class AppRouter {
  Future<void> goToHome();
  Future<void> goToUserProfile(String userId);
}

class MyAppRouter implements AppRouter {
  final GoRouterAdapter _adapter;

  MyAppRouter(this._adapter);

  @override
  Future<void> goToUserProfile(String userId) =>
      _adapter.go('/profile/$userId');
}
```

## Guards

### Modern Riverpod Guards

```dart
class AuthGuard extends RiverpodRouteGuard {
  @override
  int get priority => 100;  // Higher = runs first

  @override
  List<String>? get excludes => ['/login', '/register'];

  @override
  Future<GuardResult> canActivateWithRef(
    GuardContext context,
    Ref ref,
  ) async {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;

    if (!isAuthenticated) {
      return GuardResult.redirect('/login');
    }

    return GuardResult.allow();
  }
}
```

### Bridge Existing Guards (Zero Rewrite)

Already have guards? Bridge them without any changes:

```dart
// Your existing guard function
FutureOr<GuardResult> myExistingGuard(
  BuildContext context,
  GoRouterState state,
  Ref ref,
) async {
  // Your existing logic...
}

// Bridge it - zero changes needed!
final bridgedGuard = GoRouterGuardBridge(myExistingGuard);
```

### Guard Result Types

```dart
sealed class GuardResult {
  // Allow navigation
  static GuardAllow allow();

  // Redirect to another path
  static GuardRedirect redirect(String path, {Map<String, dynamic>? extra});

  // Block navigation
  static GuardReject reject({String? reason});
}
```

## Unit Testing

Test navigation without Flutter widgets:

```dart
void main() {
  group('Navigation', () {
    test('authenticated user can access profile', () async {
      final router = InMemoryAdapter(
        guards: [MockAuthGuard(isAuthenticated: true)],
      );

      await router.go('/profile/42');

      expect(router.currentLocation, '/profile/42');
    });

    test('unauthenticated user is redirected to login', () async {
      final router = InMemoryAdapter(
        guards: [MockAuthGuard(isAuthenticated: false)],
      );

      await router.go('/profile/42');

      expect(router.currentLocation, '/login');
    });

    test('tracks navigation history', () async {
      final router = InMemoryAdapter();

      await router.go('/');
      await router.push('/profile/42');
      await router.push('/settings');

      expect(router.navigationHistory, ['/', '/profile/42', '/settings']);

      router.pop();
      expect(router.currentLocation, '/profile/42');
    });
  });
}
```

## Progressive Migration Guide

### Phase 1: Wrap (Day 1)
```dart
// Just wrap, nothing else changes
final adapter = GoRouterAdapter.wrap(existingRouter);
```

### Phase 2: Bridge Guards (Week 1)
```dart
// Bridge existing guards
final bridged = GoRouterGuardBridge(existingGuard);
```

### Phase 3: Add AppRouter (Week 2)
```dart
// Create type-safe navigation
abstract class AppRouter {
  Future<void> goToProfile(String id);
}
```

### Phase 4: Migrate Features (Ongoing)
```dart
// Old and new coexist
context.go('/old');           // Old code ✅
appRouter.goToProfile('42');  // New code ✅
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Feature Code                          │
│              (Uses AppRouter interface)                  │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     AppRouter                            │
│            (Your type-safe abstraction)                  │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Nav Bridge                           │
│         (Guards, DI, Navigation abstraction)             │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              GoRouterAdapter.wrap()                      │
│            (Wraps your existing router)                  │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Your Existing GoRouter                      │
│          (Routes, Shell, everything intact)              │
└─────────────────────────────────────────────────────────┘
```

## API Reference

### Adapters

| Adapter | Use Case |
|---------|----------|
| `GoRouterAdapter.wrap()` | Existing GoRouter apps (recommended) |
| `GoRouterAdapter.create()` | New applications |
| `GoRouterAdapter.withGuards()` | New with integrated guard system |
| `InMemoryAdapter` | Unit testing |

### Guards

| Class | Description |
|-------|-------------|
| `RouteGuard` | Base class for all guards |
| `RiverpodRouteGuard` | Guard with Riverpod `Ref` access |
| `GoRouterGuardBridge` | Bridge for existing guards with Ref |
| `SimpleGoRouterGuardBridge` | Bridge for guards without Ref |
| `GoRouterRedirectBridge` | Bridge for redirect functions |
| `CompositeGuard` | Combine guards with AND logic |
| `AnyGuard` | Combine guards with OR logic |

### Core Classes

| Class | Description |
|-------|-------------|
| `GuardContext` | Context passed to guards with DI support |
| `GuardResult` | Sealed class: Allow, Redirect, Reject |
| `RouteDefinition` | Router-agnostic route definition |
| `ShellRouteDefinition` | Shell/tab navigation support |

## Roadmap

- [x] GoRouter wrap mode
- [x] Riverpod guard support
- [x] Guard bridge adapters
- [x] InMemoryAdapter for testing
- [x] Shell navigation support
- [ ] AutoRoute adapter
- [ ] Beamer adapter
- [ ] Typed route code generation
- [ ] Analytics observers
- [ ] Transition abstraction

## When Should You Use This?

| Scenario | Recommendation |
|----------|----------------|
| Existing GoRouter app | Perfect fit |
| Large team / enterprise | Highly recommended |
| Need navigation unit tests | Essential |
| Planning router migration | Future-proof |
| Small personal app | Optional |

## Community

- [Report bugs](https://github.com/chekarhamza88-stack/nav_bridge/issues)
- [Request features](https://github.com/chekarhamza88-stack/nav_bridge/issues)
- [Read the docs](https://github.com/chekarhamza88-stack/nav_bridge/wiki)
- [Discussions](https://github.com/chekarhamza88-stack/nav_bridge/discussions)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

```bash
# Clone the repo
git clone https://github.com/chekarhamza88-stack/nav_bridge.git

# Install dependencies
flutter pub get

# Run tests
flutter test

# Check analysis
flutter analyze
```

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Nav Bridge doesn't replace GoRouter.</b><br>
  It makes GoRouter <i>testable</i>, <i>replaceable</i>, <i>decoupled</i>, and <i>enterprise-ready</i>.
</p>

<p align="center">
  Made with love by <a href="https://github.com/chekarhamza88-stack">chekarhamza88-stack</a>
</p>
