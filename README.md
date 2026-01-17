# 🚀 Nav Bridge

[![pub package](https://img.shields.io/pub/v/nav_bridge.svg)](https://pub.dev/packages/nav_bridge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A **progressive, router-agnostic navigation layer** for Flutter that allows you to wrap existing GoRouter apps and migrate to a clean, testable, decoupled architecture — **without rewriting your routes**.

## 🎯 Why Nav Bridge?

Flutter apps are usually tightly coupled to a routing library:

```dart
// ❌ Your business logic depends on GoRouter
context.go('/users/42');
context.push('/settings');
```

This means:
- 🔒 Your business logic depends on GoRouter (or AutoRoute)
- 🧪 Navigation cannot be unit tested
- 💰 Migrating to another router is expensive
- 🔗 UI and routing are tightly coupled

**Nav Bridge solves this** by introducing a routing abstraction layer:

```dart
// ✅ Your app talks to AppRouter, not GoRouter
appRouter.goToUserProfile('42');
```

## ✨ What Makes Nav Bridge Different?

| Feature | Benefit |
|---------|---------|
| **Wrap Mode** | Use your existing GoRouter without changes |
| **Progressive Migration** | Migrate one feature at a time |
| **Full DI Support** | Riverpod Ref in guards |
| **Guard Bridge** | Keep existing guards working |
| **InMemoryAdapter** | Unit test navigation without Flutter |
| **Shell Navigation** | Full StatefulShellRoute support |

## 📦 Installation

```yaml
dependencies:
  nav_bridge: ^2.0.0
  go_router: ^15.0.0
  
  # Optional for Riverpod guards
  flutter_riverpod: ^2.4.0
```

## 🚀 Quick Start

### Option 1: Wrap Existing Router (Recommended)

Zero changes to your existing code:

```dart
// Your existing GoRouter
final goRouter = GoRouter(
  routes: [...],
  redirect: myRedirectLogic,
);

# Wrap it with Nav Bridge
final adapter = GoRouterAdapter.wrap(goRouter);

// Existing navigation still works!
context.go('/profile/42');  // ✅ Still works
```

### Option 2: Add Guards with DI

```dart
final adapter = GoRouterAdapter.wrap(
  goRouter,
  additionalGuards: [AuthGuard(), RoleGuard()],
);

// Inject Riverpod Ref into guards
adapter.contextBuilder = (state) => {
  'ref': ref,
  'goRouterState': state,
  'context': navigatorKey.currentContext,
};
```

### Option 3: Create Type-Safe Navigation

```dart
abstract class AppRouter {
  Future<void> goToHome();
  Future<void> goToUserProfile(String userId);
  Future<void> goToSettings();
}

class MyAppRouter implements AppRouter {
  final GoRouterAdapter _adapter;
  
  MyAppRouter(this._adapter);
  
  @override
  Future<void> goToUserProfile(String userId) {
    return _adapter.go('/profile/$userId');
  }
}
```

## 🛡️ Guards with Riverpod Support

### New Guard Pattern

```dart
class AuthGuard extends RiverpodRouteGuard {
  @override
  int get priority => 100;
  
  @override
  Future<GuardResult> canActivateWithRef(
    GuardContext context,
    Ref ref,
  ) async {
    final authState = ref.read(authProvider);
    
    if (!authState.isAuthenticated) {
      return GuardResult.redirect('/login');
    }
    
    return GuardResult.allow();
  }
}
```

### Bridge Existing Guards (Zero Rewrite)

```dart
// Your existing guard
FutureOr<GuardResult> myLegacyGuard(
  BuildContext context,
  GoRouterState state,
  Ref ref,
) {
  // Your existing logic...
}

// Bridge it - no changes needed!
final bridgedGuard = GoRouterGuardBridge(myLegacyGuard);
```

## 🧪 Unit Testing Navigation

Test navigation without Flutter widgets:

```dart
void main() {
  test('navigates to profile after login', () async {
    final router = InMemoryAdapter(
      guards: [MockAuthGuard(isAuthenticated: true)],
    );
    
    await router.go('/login');
    await router.go('/profile/42');
    
    expect(router.currentLocation, '/profile/42');
    expect(router.navigationHistory, ['/login', '/profile/42']);
  });
  
  test('auth guard redirects unauthenticated users', () async {
    final router = InMemoryAdapter(
      guards: [MockAuthGuard(isAuthenticated: false)],
    );
    
    await router.go('/protected');
    
    expect(router.currentLocation, '/login');
  });
}
```

## 🔄 Progressive Migration Guide

### Phase 1: Wrap (Day 1)
```dart
// Just wrap, no other changes
final adapter = GoRouterAdapter.wrap(existingRouter);
```

### Phase 2: Add AppRouter Interface (Week 1)
```dart
// Create type-safe navigation incrementally
abstract class AppRouter {
  Future<void> goToUserProfile(String userId);
}
```

### Phase 3: Migrate Guards (Week 2-4)
```dart
// Bridge existing, refactor gradually
final bridged = GoRouterGuardBridge(existingGuard);
// Later: convert to RiverpodRouteGuard
```

### Phase 4: Migrate Features (Ongoing)
```dart
// Old and new coexist
context.go('/old-path');           // Old code
appRouter.goToUserProfile('42');   // New code
```

## 📊 Architecture

```
Feature Code
    ↓
AppRouter (your abstraction)
    ↓
Routing Composer
    ↓
GoRouterAdapter.wrap()
    ↓
Your Existing GoRouter
```

## 🏗️ Shell Navigation Support

Full support for StatefulShellRoute patterns:

```dart
final shellRoute = ShellRouteDefinition(
  builder: (context, state, child) => MainShell(child: child),
  branches: [
    ShellBranch(
      routes: [
        RouteDefinition(path: '/home', builder: (_, __) => HomeScreen()),
      ],
    ),
    ShellBranch(
      routes: [
        RouteDefinition(path: '/profile', builder: (_, __) => ProfileScreen()),
      ],
    ),
  ],
);
```

## 📋 API Reference

### GuardResult

```dart
sealed class GuardResult {
  static GuardAllow allow();
  static GuardRedirect redirect(String path, {Map<String, dynamic>? extra});
  static GuardReject reject({String? reason});
}
```

### GuardContext

```dart
class GuardContext {
  final RouteDefinition destination;
  final Map<String, Object?> extras;
  
  // Convenience getters
  Ref? get ref;
  GoRouterState? get goRouterState;
  BuildContext? get context;
}
```

### Adapters

| Adapter | Use Case |
|---------|----------|
| `GoRouterAdapter.wrap()` | Existing GoRouter apps |
| `GoRouterAdapter.create()` | New apps |
| `GoRouterAdapter.withGuards()` | New with integrated guards |
| `InMemoryAdapter` | Unit testing |

### Guard Bridges

| Bridge | Use Case |
|--------|----------|
| `GoRouterGuardBridge` | Guards with Ref parameter |
| `SimpleGoRouterGuardBridge` | Guards without Ref |
| `GoRouterRedirectBridge` | Redirect functions |
| `GuardManagerBridge` | Guard manager patterns |

## 🗺️ Roadmap

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

## 🤝 When Should You Use Routing Composer?

| Scenario | Fit |
|----------|-----|
| Existing GoRouter app | ⭐⭐⭐⭐⭐ |
| Large team / enterprise | ⭐⭐⭐⭐⭐ |
| Need navigation unit tests | ⭐⭐⭐⭐⭐ |
| Future router migration | ⭐⭐⭐⭐⭐ |
| Small hobby app | ⭐⭐ (Optional) |

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

---

**Routing Composer doesn't replace GoRouter. It makes GoRouter testable, replaceable, decoupled, and enterprise-ready.**
