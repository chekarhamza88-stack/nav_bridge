import 'dart:async';

import '../core/guard_context.dart';
import '../core/guard_result.dart';
import '../core/nav_bridge_route.dart';
import '../core/route_definition.dart';
import '../core/route_guard.dart';
import '../core/router_adapter.dart';
import '../core/typed_route.dart';

/// In-memory router adapter for unit testing.
///
/// Allows testing navigation logic without Flutter widgets or BuildContext.
///
/// ## Example
/// ```dart
/// void main() {
///   test('navigates to profile after login', () async {
///     final router = InMemoryAdapter();
///
///     await router.go('/login');
///     expect(router.currentLocation, '/login');
///
///     await router.go('/profile/42');
///     expect(router.currentLocation, '/profile/42');
///     expect(router.navigationHistory, ['/login', '/profile/42']);
///   });
///
///   test('auth guard redirects', () async {
///     final router = InMemoryAdapter(
///       guards: [MockAuthGuard(isAuthenticated: false)],
///     );
///
///     await router.go('/protected');
///     expect(router.currentLocation, '/login');
///   });
/// }
/// ```
class InMemoryAdapter implements RouterAdapter {
  final List<RouteGuard> _guards;
  final List<String> _navigationStack = [];
  final List<NavigationEvent> _history = [];
  final StreamController<String> _locationController =
      StreamController.broadcast();

  /// Registered routes for named navigation.
  final List<NavBridgeRoute> _routes;

  /// DI context passed to guards.
  Map<String, Object?> guardContext;

  String _currentLocation;
  Map<String, String> _currentPathParams = {};
  Map<String, String> _currentQueryParams = {};
  String? _currentRouteName;

  InMemoryAdapter({
    String initialLocation = '/',
    List<RouteGuard>? guards,
    List<NavBridgeRoute>? routes,
    this.guardContext = const {},
  })  : _currentLocation = initialLocation,
        _guards = guards ?? [],
        _routes = routes ?? [] {
    _navigationStack.add(initialLocation);
  }

  /// All navigation events (useful for detailed testing).
  List<NavigationEvent> get history => List.unmodifiable(_history);

  /// Just the locations navigated to.
  List<String> get navigationHistory => _history.map((e) => e.to).toList();

  /// The navigation stack (for push/pop testing).
  List<String> get stack => List.unmodifiable(_navigationStack);

  /// Reset the adapter to initial state.
  void reset({String initialLocation = '/'}) {
    _currentLocation = initialLocation;
    _currentPathParams = {};
    _currentQueryParams = {};
    _currentRouteName = null;
    _navigationStack.clear();
    _navigationStack.add(initialLocation);
    _history.clear();
    _locationController.add(initialLocation);
  }

  /// Simulate a redirect from guards.
  /// Returns a record with (redirect path or null, was rejected).
  Future<({String? redirect, bool rejected})> _runGuards(String to) async {
    final sortedGuards = List<RouteGuard>.from(_guards)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    for (final guard in sortedGuards) {
      if (!guard.shouldActivateFor(to)) continue;

      final context = GuardContext(
        destination: RouteDefinition.stub(to),
        matchedLocation: to,
        pathParameters: _extractPathParams(to),
        queryParameters: _extractQueryParams(to),
        extras: guardContext,
      );

      final result = await guard.canActivate(context);

      switch (result) {
        case GuardAllow():
          continue;
        case GuardRedirect(:final path):
          return (redirect: path, rejected: false);
        case GuardReject():
          // For testing, we might want to track this
          _history.add(NavigationEvent(
            from: _currentLocation,
            to: to,
            type: NavigationType.rejected,
          ));
          return (redirect: null, rejected: true);
      }
    }

    return (
      redirect: null,
      rejected: false
    ); // No redirect needed, not rejected
  }

  Map<String, String> _extractPathParams(String location) {
    // Simple extraction - in real use, you'd match against route definitions
    final params = <String, String>{};
    final parts = location.split('/');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty && i > 0) {
        // Assume numeric parts are IDs
        if (RegExp(r'^\d+$').hasMatch(parts[i])) {
          params['id'] = parts[i];
        }
      }
    }
    return params;
  }

  Map<String, String> _extractQueryParams(String location) {
    final uri = Uri.tryParse(location);
    return uri?.queryParameters ?? {};
  }

  @override
  Future<void> go(String location, {Object? extra}) async {
    final from = _currentLocation;

    final guardResult = await _runGuards(location);

    // If rejected, stay at current location
    if (guardResult.rejected) return;

    final finalLocation = guardResult.redirect ?? location;

    _currentLocation = finalLocation;
    _currentPathParams = _extractPathParams(finalLocation);
    _currentQueryParams = _extractQueryParams(finalLocation);
    _navigationStack.clear();
    _navigationStack.add(finalLocation);

    _history.add(NavigationEvent(
      from: from,
      to: finalLocation,
      type: guardResult.redirect != null
          ? NavigationType.redirected
          : NavigationType.go,
      redirectedFrom: guardResult.redirect != null ? location : null,
    ));

    _locationController.add(finalLocation);
  }

  @override
  Future<void> push(String location, {Object? extra}) async {
    final from = _currentLocation;

    final guardResult = await _runGuards(location);

    // If rejected, stay at current location
    if (guardResult.rejected) return;

    final finalLocation = guardResult.redirect ?? location;

    _currentLocation = finalLocation;
    _currentPathParams = _extractPathParams(finalLocation);
    _currentQueryParams = _extractQueryParams(finalLocation);
    _navigationStack.add(finalLocation);

    _history.add(NavigationEvent(
      from: from,
      to: finalLocation,
      type: guardResult.redirect != null
          ? NavigationType.redirected
          : NavigationType.push,
      redirectedFrom: guardResult.redirect != null ? location : null,
    ));

    _locationController.add(finalLocation);
  }

  @override
  Future<void> replace(String location, {Object? extra}) async {
    final from = _currentLocation;

    final guardResult = await _runGuards(location);

    // If rejected, stay at current location
    if (guardResult.rejected) return;

    final finalLocation = guardResult.redirect ?? location;

    _currentLocation = finalLocation;
    _currentPathParams = _extractPathParams(finalLocation);
    _currentQueryParams = _extractQueryParams(finalLocation);
    if (_navigationStack.isNotEmpty) {
      _navigationStack[_navigationStack.length - 1] = finalLocation;
    }

    _history.add(NavigationEvent(
      from: from,
      to: finalLocation,
      type: guardResult.redirect != null
          ? NavigationType.redirected
          : NavigationType.replace,
      redirectedFrom: guardResult.redirect != null ? location : null,
    ));

    _locationController.add(finalLocation);
  }

  // Named navigation methods

  @override
  Future<void> goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) async {
    final route = _findRouteByName(name);
    if (route == null) {
      throw Exception('Route not found: $name');
    }

    final path = _buildPath(route.path, pathParameters, queryParameters);
    _currentRouteName = name;
    return go(path, extra: extra);
  }

  @override
  Future<void> pushNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) async {
    final route = _findRouteByName(name);
    if (route == null) {
      throw Exception('Route not found: $name');
    }

    final path = _buildPath(route.path, pathParameters, queryParameters);
    _currentRouteName = name;
    return push(path, extra: extra);
  }

  @override
  Future<void> replaceNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) async {
    final route = _findRouteByName(name);
    if (route == null) {
      throw Exception('Route not found: $name');
    }

    final path = _buildPath(route.path, pathParameters, queryParameters);
    _currentRouteName = name;
    return replace(path, extra: extra);
  }

  // Type-safe navigation methods

  @override
  Future<void> goToRoute(TypedRoute route) => goNamed(
        route.name,
        pathParameters: route.pathParameters,
        queryParameters: route.queryParameters,
        extra: route.extra,
      );

  @override
  Future<void> pushRoute(TypedRoute route) => pushNamed(
        route.name,
        pathParameters: route.pathParameters,
        queryParameters: route.queryParameters,
        extra: route.extra,
      );

  @override
  Future<void> replaceRoute(TypedRoute route) => replaceNamed(
        route.name,
        pathParameters: route.pathParameters,
        queryParameters: route.queryParameters,
        extra: route.extra,
      );

  /// Finds a route by name, searching recursively through all routes.
  NavBridgeRoute? _findRouteByName(String name) {
    return _searchRouteByName(_routes, name);
  }

  NavBridgeRoute? _searchRouteByName(List<NavBridgeRoute> routes, String name) {
    for (final route in routes) {
      if (route.name == name) return route;

      // Search children recursively
      final childResult = _searchRouteByName(route.children, name);
      if (childResult != null) return childResult;
    }
    return null;
  }

  /// Builds a path from a template and parameters.
  String _buildPath(
    String template,
    Map<String, String> pathParams,
    Map<String, String> queryParams,
  ) {
    var path = template;

    // Replace path parameters
    pathParams.forEach((key, value) {
      path = path.replaceAll(':$key', value);
    });

    // Add query parameters
    if (queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path = '$path?$query';
    }

    return path;
  }

  /// Registers routes for named navigation.
  ///
  /// This is useful when you want to add routes after construction.
  void registerRoutes(List<NavBridgeRoute> routes) {
    _routes.addAll(routes);
  }

  /// Clears all registered routes.
  void clearRoutes() {
    _routes.clear();
  }

  @override
  void pop<T>([T? result]) {
    if (_navigationStack.length <= 1) return;

    final from = _currentLocation;
    _navigationStack.removeLast();
    _currentLocation = _navigationStack.last;
    _currentPathParams = _extractPathParams(_currentLocation);
    _currentQueryParams = _extractQueryParams(_currentLocation);

    _history.add(NavigationEvent(
      from: from,
      to: _currentLocation,
      type: NavigationType.pop,
    ));

    _locationController.add(_currentLocation);
  }

  @override
  void popUntil(bool Function(String path) predicate) {
    // Add safety limit to prevent infinite loops
    var iterations = 0;
    const maxIterations = 100;
    while (_navigationStack.length > 1 &&
        !predicate(_currentLocation) &&
        iterations < maxIterations) {
      pop();
      iterations++;
    }
  }

  @override
  bool canPop() => _navigationStack.length > 1;

  @override
  String get currentLocation => _currentLocation;

  @override
  String? get currentRouteName => _currentRouteName;

  @override
  Map<String, String> get currentPathParameters =>
      Map.unmodifiable(_currentPathParams);

  @override
  Map<String, String> get currentQueryParameters =>
      Map.unmodifiable(_currentQueryParams);

  @override
  Stream<String> get locationStream => _locationController.stream;

  @override
  void addGuard(RouteGuard guard) => _guards.add(guard);

  @override
  void removeGuard(RouteGuard guard) => _guards.remove(guard);

  @override
  List<RouteGuard> get guards => List.unmodifiable(_guards);

  @override
  void refresh() {
    // Re-run guards for current location
    go(_currentLocation);
  }

  @override
  void dispose() {
    _locationController.close();
  }
}

/// Type of navigation event.
enum NavigationType {
  go,
  push,
  replace,
  pop,
  redirected,
  rejected,
}

/// A recorded navigation event.
class NavigationEvent {
  final String from;
  final String to;
  final NavigationType type;
  final String? redirectedFrom;
  final DateTime timestamp;

  NavigationEvent({
    required this.from,
    required this.to,
    required this.type,
    this.redirectedFrom,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      'NavigationEvent($type: $from → $to${redirectedFrom != null ? ' (redirected from $redirectedFrom)' : ''})';
}
