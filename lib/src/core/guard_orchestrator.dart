import 'guard_context.dart';
import 'guard_result.dart';
import 'route_definition.dart';
import 'route_guard.dart';

/// Manages guard execution automatically with priority ordering.
///
/// The GuardOrchestrator collects both global guards and route-specific guards,
/// sorts them by priority, and evaluates them in order.
///
/// ## Example
/// ```dart
/// final orchestrator = GuardOrchestrator(
///   globalGuards: [AuthGuard(), LoggingGuard()],
/// );
///
/// // Add route-specific guards
/// orchestrator.addRouteGuard('admin', AdminRoleGuard());
///
/// // Evaluate guards for a navigation
/// final result = await orchestrator.evaluate(
///   destination: '/admin/dashboard',
///   routeName: 'admin',
///   pathParams: {},
///   queryParams: {},
///   extra: null,
///   context: {'ref': ref},
/// );
///
/// if (result.isAllowed) {
///   // Proceed with navigation
/// } else if (result.isRedirect) {
///   // Redirect to the guard's specified path
/// }
/// ```
class GuardOrchestrator {
  final List<RouteGuard> _globalGuards;
  final Map<String, List<RouteGuard>> _routeGuards;

  /// Creates a GuardOrchestrator with optional global guards.
  GuardOrchestrator({
    List<RouteGuard> globalGuards = const [],
  })  : _globalGuards = List.from(globalGuards),
        _routeGuards = {};

  /// Gets a copy of all global guards.
  List<RouteGuard> get globalGuards => List.unmodifiable(_globalGuards);

  /// Gets a copy of all route-specific guards.
  Map<String, List<RouteGuard>> get routeGuards =>
      Map.unmodifiable(_routeGuards);

  /// Registers a global guard that applies to all routes.
  ///
  /// Global guards are evaluated before route-specific guards.
  void addGlobalGuard(RouteGuard guard) {
    _globalGuards.add(guard);
  }

  /// Removes a global guard.
  void removeGlobalGuard(RouteGuard guard) {
    _globalGuards.remove(guard);
  }

  /// Registers a guard that only applies to a specific route.
  ///
  /// Route-specific guards are evaluated after global guards
  /// but still respect priority ordering within their group.
  void addRouteGuard(String routeName, RouteGuard guard) {
    _routeGuards.putIfAbsent(routeName, () => []).add(guard);
  }

  /// Removes a route-specific guard.
  void removeRouteGuard(String routeName, RouteGuard guard) {
    _routeGuards[routeName]?.remove(guard);
  }

  /// Clears all route-specific guards for a route.
  void clearRouteGuards(String routeName) {
    _routeGuards.remove(routeName);
  }

  /// Collects all applicable guards for the given destination.
  List<RouteGuard> _collectGuards(String destination, String? routeName) {
    final guards = <RouteGuard>[];

    // Add global guards
    guards.addAll(_globalGuards);

    // Add route-specific guards
    if (routeName != null && _routeGuards.containsKey(routeName)) {
      guards.addAll(_routeGuards[routeName]!);
    }

    return guards;
  }

  /// Evaluates all applicable guards for a navigation attempt.
  ///
  /// Guards are evaluated in priority order (highest first).
  /// Evaluation stops at the first non-allow result.
  ///
  /// Returns [GuardResult.allow] if all guards allow the navigation,
  /// otherwise returns the first redirect or reject result.
  Future<GuardResult> evaluate({
    required String destination,
    required String? routeName,
    required Map<String, String> pathParams,
    required Map<String, String> queryParams,
    required Object? extra,
    required Map<String, Object?> context,
  }) async {
    final guards = _collectGuards(destination, routeName);

    // Sort by priority (highest first)
    guards.sort((a, b) => b.priority.compareTo(a.priority));

    for (final guard in guards) {
      // Check if guard should activate for this path
      if (!guard.shouldActivateFor(destination)) continue;

      final guardContext = GuardContext(
        destination: RouteDefinition.stub(destination),
        matchedLocation: destination,
        pathParameters: pathParams,
        queryParameters: queryParams,
        navigationExtra: extra,
        extras: context,
      );

      try {
        final result = await guard.canActivate(guardContext);

        switch (result) {
          case GuardAllow():
            continue;
          case GuardRedirect():
          case GuardReject():
            return result;
        }
      } catch (e) {
        // On guard error, reject with the error message
        return GuardResult.reject(reason: 'Guard error: $e');
      }
    }

    return GuardResult.allow();
  }

  /// Creates a redirect function compatible with GoRouter.
  ///
  /// This can be passed directly to GoRouter's `redirect` parameter.
  ///
  /// ## Example
  /// ```dart
  /// final router = GoRouter(
  ///   routes: [...],
  ///   redirect: orchestrator.createRedirectHandler(
  ///     contextBuilder: (state) => {'ref': ref, 'goRouterState': state},
  ///   ),
  /// );
  /// ```
  Future<String?> Function(dynamic context, dynamic state)
      createRedirectHandler({
    required Map<String, Object?> Function(dynamic state) contextBuilder,
  }) {
    return (context, state) async {
      // Extract location and parameters from GoRouterState
      final matchedLocation = _getMatchedLocation(state);
      final pathParams = _getPathParameters(state);
      final queryParams = _getQueryParameters(state);
      final extra = _getExtra(state);
      final routeName = _getRouteName(state);

      final result = await evaluate(
        destination: matchedLocation,
        routeName: routeName,
        pathParams: pathParams,
        queryParams: queryParams,
        extra: extra,
        context: contextBuilder(state),
      );

      return result.when(
        allow: () => null,
        redirect: (path, _, __) => path,
        reject: (_, __) => null, // Could redirect to error page
      );
    };
  }

  // Helper methods to extract data from GoRouterState without importing go_router
  String _getMatchedLocation(dynamic state) {
    try {
      return (state as dynamic).matchedLocation as String;
    } catch (_) {
      return '/';
    }
  }

  Map<String, String> _getPathParameters(dynamic state) {
    try {
      return Map<String, String>.from((state as dynamic).pathParameters as Map);
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _getQueryParameters(dynamic state) {
    try {
      return Map<String, String>.from(
          (state as dynamic).uri.queryParameters as Map);
    } catch (_) {
      return {};
    }
  }

  Object? _getExtra(dynamic state) {
    try {
      return (state as dynamic).extra;
    } catch (_) {
      return null;
    }
  }

  String? _getRouteName(dynamic state) {
    try {
      return (state as dynamic).name as String?;
    } catch (_) {
      return null;
    }
  }
}
