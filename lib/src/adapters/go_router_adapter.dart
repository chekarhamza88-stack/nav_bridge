import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/guard_context.dart';
import '../core/guard_result.dart';
import '../core/route_definition.dart';
import '../core/route_guard.dart';
import '../core/router_adapter.dart';
import '../shell/shell_config.dart';

/// GoRouter adapter for Routing Composer.
/// 
/// Supports two modes:
/// 
/// ## Wrap Mode (Recommended for existing apps)
/// ```dart
/// final existingRouter = GoRouter(routes: [...], redirect: ...);
/// final adapter = GoRouterAdapter.wrap(existingRouter);
/// ```
/// 
/// ## Create Mode (For new apps)
/// ```dart
/// final adapter = GoRouterAdapter.create(
///   config: ComposerRouterConfig(
///     routes: [...],
///     guards: [...],
///   ),
/// );
/// ```
class GoRouterAdapter implements RouterAdapter {
  final GoRouter _router;
  final List<RouteGuard> _guards;
  final NavigationObserver? _observer;
  final bool _isWrapped;
  final StreamController<String> _locationController = StreamController.broadcast();
  
  /// Function to get DI context (Ref, BuildContext, etc.) during redirect.
  /// 
  /// Set this to inject dependencies into guards:
  /// ```dart
  /// adapter.contextBuilder = (state) => {
  ///   'ref': ref,
  ///   'goRouterState': state,
  ///   'context': navigatorKey.currentContext,
  /// };
  /// ```
  Map<String, Object?> Function(GoRouterState state)? contextBuilder;

  GoRouterAdapter._({
    required GoRouter router,
    required List<RouteGuard> guards,
    required bool isWrapped,
    NavigationObserver? observer,
  })  : _router = router,
        _guards = guards,
        _isWrapped = isWrapped,
        _observer = observer {
    _setupLocationListener();
  }

  /// Wrap an existing GoRouter instance.
  /// 
  /// This is the recommended approach for existing applications.
  /// Your existing routes, guards, and navigation continue to work.
  /// 
  /// ```dart
  /// // Your existing router
  /// final goRouter = GoRouter(
  ///   routes: [...],
  ///   redirect: myRedirectLogic,
  /// );
  /// 
  /// // Wrap it
  /// final adapter = GoRouterAdapter.wrap(
  ///   goRouter,
  ///   additionalGuards: [AuthGuard(), PermissionGuard()],
  /// );
  /// 
  /// // Set context builder for DI
  /// adapter.contextBuilder = (state) => {'ref': ref};
  /// ```
  factory GoRouterAdapter.wrap(
    GoRouter router, {
    List<RouteGuard>? additionalGuards,
    NavigationObserver? observer,
    ShellConfig? shellConfig,
  }) {
    return GoRouterAdapter._(
      router: router,
      guards: additionalGuards ?? [],
      isWrapped: true,
      observer: observer,
    );
  }

  /// Create a new GoRouter instance from configuration.
  /// 
  /// Use this for new applications or when you want Routing Composer
  /// to manage the entire routing configuration.
  /// 
  /// ```dart
  /// final adapter = GoRouterAdapter.create(
  ///   config: ComposerRouterConfig(
  ///     initialLocation: '/',
  ///     routes: [
  ///       RouteDefinition(path: '/', builder: (_, __) => HomeScreen()),
  ///       RouteDefinition(path: '/profile/:id', builder: (_, p) => ProfileScreen(p['id']!)),
  ///     ],
  ///     guards: [AuthGuard()],
  ///   ),
  /// );
  /// ```
  factory GoRouterAdapter.create({
    required ComposerRouterConfig config,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final guards = List<RouteGuard>.from(config.guards);
    
    final router = GoRouter(
      initialLocation: config.initialLocation,
      navigatorKey: navigatorKey,
      routes: _buildRoutes(config.routes),
      debugLogDiagnostics: config.debugLogNavigation,
    );

    return GoRouterAdapter._(
      router: router,
      guards: guards,
      isWrapped: false,
      observer: config.observer,
    );
  }

  /// Create a redirect-enabled GoRouter with Routing Composer guards.
  /// 
  /// This factory creates a new GoRouter but integrates Routing Composer's
  /// guard system into GoRouter's redirect mechanism.
  /// 
  /// ```dart
  /// final adapter = GoRouterAdapter.withGuards(
  ///   routes: myRoutes,
  ///   guards: [AuthGuard(), RoleGuard()],
  ///   contextBuilder: (state) => {'ref': ref},
  /// );
  /// ```
  factory GoRouterAdapter.withGuards({
    required List<RouteBase> routes,
    required List<RouteGuard> guards,
    required Map<String, Object?> Function(GoRouterState state) contextBuilder,
    String initialLocation = '/',
    GlobalKey<NavigatorState>? navigatorKey,
    Listenable? refreshListenable,
    NavigationObserver? observer,
  }) {
    late final GoRouterAdapter adapter;
    
    final router = GoRouter(
      initialLocation: initialLocation,
      navigatorKey: navigatorKey,
      routes: routes,
      refreshListenable: refreshListenable,
      redirect: (context, state) async {
        return adapter._runGuards(context, state);
      },
    );

    adapter = GoRouterAdapter._(
      router: router,
      guards: guards,
      isWrapped: false,
      observer: observer,
    );
    
    adapter.contextBuilder = contextBuilder;
    
    return adapter;
  }

  void _setupLocationListener() {
    _router.routerDelegate.addListener(() {
      final location = _router.routerDelegate.currentConfiguration.uri.toString();
      _locationController.add(location);
    });
  }

  /// Run guards and return redirect path if needed.
  Future<String?> _runGuards(BuildContext context, GoRouterState state) async {
    final sortedGuards = List<RouteGuard>.from(_guards)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final location = state.matchedLocation;

    for (final guard in sortedGuards) {
      if (!guard.shouldActivateFor(location)) continue;

      final guardContext = GuardContext(
        destination: RouteDefinition(path: location),
        matchedLocation: location,
        pathParameters: state.pathParameters,
        queryParameters: state.uri.queryParameters,
        navigationExtra: state.extra,
        extras: contextBuilder?.call(state) ?? {
          'goRouterState': state,
          'context': context,
        },
      );

      try {
        final result = await guard.canActivate(guardContext);

        switch (result) {
          case GuardAllow():
            continue;
          case GuardRedirect(:final path):
            _observer?.onGuardRedirect(location, location, path);
            return path;
          case GuardReject(:final reason):
            _observer?.onGuardReject(location, location, reason);
            // For rejects, you might want to redirect to an error page
            return null;
        }
      } catch (e) {
        _observer?.onNavigationError(location, e);
        rethrow;
      }
    }

    return null;
  }

  /// The underlying GoRouter instance.
  GoRouter get router => _router;

  /// Whether this adapter is wrapping an existing router.
  bool get isWrapped => _isWrapped;

  // RouterAdapter implementation

  @override
  Future<void> go(String location, {Object? extra}) async {
    final from = currentLocation;
    _observer?.onNavigating(from, location);
    _router.go(location, extra: extra);
    _observer?.onNavigated(from, location);
  }

  @override
  Future<void> push(String location, {Object? extra}) async {
    final from = currentLocation;
    _observer?.onNavigating(from, location);
    _router.push(location, extra: extra);
    _observer?.onNavigated(from, location);
  }

  @override
  Future<void> replace(String location, {Object? extra}) async {
    final from = currentLocation;
    _observer?.onNavigating(from, location);
    _router.replace(location, extra: extra);
    _observer?.onNavigated(from, location);
  }

  @override
  void pop<T>([T? result]) {
    _router.pop(result);
  }

  @override
  void popUntil(bool Function(String path) predicate) {
    // GoRouter doesn't have built-in popUntil, we need to implement it
    // Add safety limit to prevent infinite loops
    var iterations = 0;
    const maxIterations = 100;
    while (canPop() && !predicate(currentLocation) && iterations < maxIterations) {
      pop();
      iterations++;
    }
  }

  @override
  bool canPop() => _router.canPop();

  @override
  String get currentLocation =>
      _router.routerDelegate.currentConfiguration.uri.toString();

  @override
  String? get currentRouteName =>
      _router.routerDelegate.currentConfiguration.last.route.name;

  @override
  Map<String, String> get currentPathParameters =>
      _router.routerDelegate.currentConfiguration.pathParameters;

  @override
  Map<String, String> get currentQueryParameters =>
      _router.routerDelegate.currentConfiguration.uri.queryParameters;

  @override
  Stream<String> get locationStream => _locationController.stream;

  @override
  void addGuard(RouteGuard guard) {
    _guards.add(guard);
  }

  @override
  void removeGuard(RouteGuard guard) {
    _guards.remove(guard);
  }

  @override
  List<RouteGuard> get guards => List.unmodifiable(_guards);

  @override
  void refresh() {
    _router.refresh();
  }

  @override
  void dispose() {
    _locationController.close();
  }

  // Helper to build GoRoutes from RouteDefinitions
  static List<RouteBase> _buildRoutes(List<RouteDefinition> definitions) {
    return definitions.map((def) {
      if (def.redirectTo != null) {
        return GoRoute(
          path: def.path,
          name: def.name,
          redirect: (_, __) => def.redirectTo,
        );
      }

      return GoRoute(
        path: def.path,
        name: def.name,
        builder: def.builder != null
            ? (context, state) => def.builder!(context, state.pathParameters)
            : null,
        pageBuilder: def.pageBuilder != null
            ? (context, state) => def.pageBuilder!(context, state.pathParameters)
            : null,
        routes: _buildRoutes(def.children),
      );
    }).toList();
  }
}
