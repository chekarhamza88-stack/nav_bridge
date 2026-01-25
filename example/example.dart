// Example: Integrating Nav Bridge with mybrandbeta-app
//
// This shows how to progressively adopt Nav Bridge
// in your existing GoRouter + Riverpod application.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import nav_bridge
import 'package:nav_bridge/nav_bridge.dart';

// ============================================================================
// PHASE 1: WRAP EXISTING ROUTER (Day 1 - Zero Changes)
// ============================================================================

/// Your existing GoRouter setup (unchanged)
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Your existing routes...
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      // StatefulShellRoute preserved...
    ],
    redirect: (context, state) {
      // Your existing redirect logic...
      return null;
    },
  );
});

/// NEW: Wrap with Nav Bridge
final routerAdapterProvider = Provider<GoRouterAdapter>((ref) {
  final goRouter = ref.watch(goRouterProvider);
  return GoRouterAdapter.wrap(goRouter);
});

// ============================================================================
// PHASE 2: BRIDGE EXISTING GUARDS (Week 1)
// ============================================================================

/// Your existing guard signature (use dynamic for ref to match bridge signature)
FutureOr<GuardResult> existingAuthGuard(
  BuildContext context,
  GoRouterState state,
  dynamic ref,
) async {
  // Your existing logic - cast ref to Ref when using
  final isAuthenticated = (ref as Ref).read(authStateProvider).isAuthenticated;

  if (!isAuthenticated && !state.matchedLocation.startsWith('/login')) {
    return GuardResult.redirect('/login');
  }

  return GuardResult.allow();
}

/// Bridge it to Nav Bridge (zero changes to existing guard)
final bridgedAuthGuard = GoRouterGuardBridge(
  existingAuthGuard,
  priority: 100,
  excludes: ['/login', '/register', '/forgot-password'],
);

/// Updated adapter with bridged guards
final routerAdapterWithGuardsProvider = Provider<GoRouterAdapter>((ref) {
  final goRouter = ref.watch(goRouterProvider);

  final adapter = GoRouterAdapter.wrap(
    goRouter,
    additionalGuards: [bridgedAuthGuard],
  );

  // Inject Riverpod Ref for guards
  adapter.contextBuilder = (state) => {
        'ref': ref,
        'goRouterState': state,
      };

  return adapter;
});

// ============================================================================
// PHASE 3: CREATE APP ROUTER INTERFACE (Week 2)
// ============================================================================

/// Type-safe navigation interface
abstract class AppRouter {
  Future<void> goToHome();
  Future<void> goToLogin({String? returnTo});
  Future<void> goToProfile(String userId);
  Future<void> goToSettings();
  Future<void> goToCarDetails(String carId);
  void pop();
  bool canPop();
}

/// Implementation using GoRouterAdapter
class MyBrandAppRouter implements AppRouter {
  final GoRouterAdapter _adapter;

  MyBrandAppRouter(this._adapter);

  @override
  Future<void> goToHome() => _adapter.go('/');

  @override
  Future<void> goToLogin({String? returnTo}) {
    final extra = returnTo != null ? {'returnTo': returnTo} : null;
    return _adapter.go('/login', extra: extra);
  }

  @override
  Future<void> goToProfile(String userId) => _adapter.go('/profile/$userId');

  @override
  Future<void> goToSettings() => _adapter.go('/settings');

  @override
  Future<void> goToCarDetails(String carId) => _adapter.go('/car/$carId');

  @override
  void pop() => _adapter.pop();

  @override
  bool canPop() => _adapter.canPop();
}

/// Provider for AppRouter
final appRouterProvider = Provider<AppRouter>((ref) {
  final adapter = ref.watch(routerAdapterWithGuardsProvider);
  return MyBrandAppRouter(adapter);
});

// ============================================================================
// PHASE 4: NEW GUARDS USING RIVERPOD PATTERN
// ============================================================================

/// Modern guard using RiverpodRouteGuard
class ModernAuthGuard extends RiverpodRouteGuard {
  @override
  int get priority => 100;

  @override
  List<String>? get excludes => ['/login', '/register', '/forgot-password'];

  @override
  Future<GuardResult> canActivateWithRef(
    GuardContext context,
    dynamic ref,
  ) async {
    final authState = (ref as Ref).read(authStateProvider);

    if (!authState.isAuthenticated) {
      return GuardResult.redirect(
        '/login',
        extra: {'returnTo': context.matchedLocation},
      );
    }

    return GuardResult.allow();
  }
}

/// Role-based guard (custom implementation for mybrandbeta)
class MyBrandRoleGuard extends RiverpodRouteGuard {
  final List<String> allowedRoles;

  MyBrandRoleGuard({required this.allowedRoles});

  @override
  int get priority => 50;

  @override
  Future<GuardResult> canActivateWithRef(
    GuardContext context,
    dynamic ref,
  ) async {
    final userRole = (ref as Ref).read(userRoleProvider);

    if (!allowedRoles.contains(userRole)) {
      return GuardResult.redirect('/unauthorized');
    }

    return GuardResult.allow();
  }
}

// ============================================================================
// USAGE IN WIDGETS
// ============================================================================

/// OLD WAY (still works)
class OldStyleWidget extends ConsumerWidget {
  const OldStyleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => context.go('/profile/42'), // Still works!
      child: const Text('Go to Profile'),
    );
  }
}

/// NEW WAY (type-safe, testable)
class NewStyleWidget extends ConsumerWidget {
  const NewStyleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(appRouterProvider);

    return ElevatedButton(
      onPressed: () => router.goToProfile('42'),
      child: const Text('Go to Profile'),
    );
  }
}

// ============================================================================
// UNIT TESTING EXAMPLE
// ============================================================================

/*
void main() {
  group('Navigation Tests', () {
    test('navigates to profile when authenticated', () async {
      final mockAuthGuard = MockAuthGuard(isAuthenticated: true);
      final router = InMemoryAdapter(guards: [mockAuthGuard]);
      
      await router.go('/profile/42');
      
      expect(router.currentLocation, '/profile/42');
    });
    
    test('redirects to login when not authenticated', () async {
      final mockAuthGuard = MockAuthGuard(isAuthenticated: false);
      final router = InMemoryAdapter(guards: [mockAuthGuard]);
      
      await router.go('/profile/42');
      
      expect(router.currentLocation, '/login');
    });
    
    test('tracks navigation history', () async {
      final router = InMemoryAdapter();
      
      await router.go('/');
      await router.push('/profile/42');
      await router.push('/settings');
      
      expect(router.navigationHistory, ['/', '/profile/42', '/settings']);
      expect(router.canPop(), true);
      
      router.pop();
      expect(router.currentLocation, '/profile/42');
    });
  });
}

class MockAuthGuard extends RouteGuard {
  final bool isAuthenticated;
  MockAuthGuard({required this.isAuthenticated});
  
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    if (!isAuthenticated && !context.matchedLocation.startsWith('/login')) {
      return GuardResult.redirect('/login');
    }
    return GuardResult.allow();
  }
}
*/

// ============================================================================
// PLACEHOLDER WIDGETS (for compilation)
// ============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home')));
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Login')));
}

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Profile $userId')));
}

// Placeholder providers
final authStateProvider = StateProvider<AuthState>((ref) => AuthState());
final userRoleProvider = StateProvider<String>((ref) => 'user');

class AuthState {
  final bool isAuthenticated;
  AuthState({this.isAuthenticated = false});
}
