/// Nav Bridge - Enterprise-Ready Progressive Navigation Architecture
///
/// A router-agnostic navigation layer for Flutter that allows you to wrap
/// existing GoRouter apps and migrate to a clean, testable, decoupled
/// architecture without rewriting your routes.
///
/// ## Key Features
/// - Router-agnostic route definitions (no GoRouter types in your code)
/// - Automatic guard orchestration with priority ordering
/// - Named and type-safe navigation
/// - Shell route support for tab-based navigation
/// - Default NavigationService with modal/dialog support
///
/// ## Quick Start
/// ```dart
/// // Define routes without GoRouter
/// final routes = [
///   NavBridgeRoute(
///     path: '/',
///     name: 'home',
///     builder: (context, params) => const HomeScreen(),
///   ),
///   NavBridgeRoute(
///     path: '/users/:userId',
///     name: 'userDetails',
///     builder: (context, params) => UserScreen(userId: params.get('userId')),
///   ),
/// ];
///
/// // Create adapter with automatic guard integration
/// final adapter = GoRouterAdapter.fromRoutes(
///   routes: routes,
///   guards: [AuthGuard()],
///   contextBuilder: (state) => {'ref': ref},
/// );
///
/// // Navigate type-safely
/// nav.goNamed('userDetails', pathParams: {'userId': '123'});
/// ```
library;

// Core types
export 'src/core/guard_context.dart';
export 'src/core/guard_orchestrator.dart';
export 'src/core/guard_result.dart';
export 'src/core/nav_bridge_route.dart';
export 'src/core/nav_bridge_shell_route.dart';
export 'src/core/route_definition.dart';
export 'src/core/route_guard.dart';
export 'src/core/route_params.dart';
export 'src/core/router_adapter.dart';
export 'src/core/typed_route.dart';

// Adapters
export 'src/adapters/go_router_adapter.dart';
export 'src/adapters/in_memory_adapter.dart';

// Guards
export 'src/guards/riverpod_route_guard.dart';
export 'src/guards/go_router_guard_bridge.dart';

// Services
export 'src/services/navigation_service.dart';

// Shell (for advanced shell route configuration)
export 'src/shell/shell_route_definition.dart';
export 'src/shell/shell_config.dart';
