import 'package:flutter/widgets.dart';
import 'route_definition.dart';

/// Context passed to route guards during navigation.
///
/// Supports dependency injection through the [extras] map, allowing guards
/// to access Riverpod Ref, GoRouterState, BuildContext, or any custom services.
///
/// ## Example
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   Future<GuardResult> canActivate(GuardContext context) async {
///     final ref = context.ref;
///     if (ref == null) return GuardResult.reject('No Ref available');
///
///     final isAuthenticated = ref.read(authProvider).isAuthenticated;
///     if (!isAuthenticated) {
///       return GuardResult.redirect('/login');
///     }
///     return GuardResult.allow();
///   }
/// }
/// ```
class GuardContext {
  /// The route being navigated to.
  final RouteDefinition destination;

  /// Extra data passed with the navigation.
  final Object? navigationExtra;

  /// Parameters extracted from the route path (e.g., /users/:id -> {'id': '42'}).
  final Map<String, String> pathParameters;

  /// Query parameters from the URI (e.g., ?sort=name -> {'sort': 'name'}).
  final Map<String, String> queryParameters;

  /// The full matched location (e.g., '/users/42?sort=name').
  final String matchedLocation;

  /// Dependency injection container.
  ///
  /// Use this to pass:
  /// - Riverpod `Ref` (key: 'ref')
  /// - `GoRouterState` (key: 'goRouterState')
  /// - `BuildContext` (key: 'context')
  /// - Any custom services your guards need
  final Map<String, Object?> extras;

  GuardContext({
    required this.destination,
    this.navigationExtra,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.matchedLocation = '',
    this.extras = const {},
  });

  /// Type-safe accessor for extras.
  ///
  /// Returns null if key doesn't exist or value is wrong type.
  T? get<T>(String key) {
    final value = extras[key];
    if (value is T) return value;
    return null;
  }

  /// Convenience getter for Riverpod Ref.
  ///
  /// Expects extras to contain `'ref': ref` where ref is a Riverpod Ref.
  ///
  /// ## Example
  /// ```dart
  /// // In your GoRouterAdapter redirect:
  /// final context = GuardContext(
  ///   destination: route,
  ///   extras: {'ref': ref},
  /// );
  /// ```
  dynamic get ref => get<dynamic>('ref');

  /// Convenience getter for GoRouterState.
  ///
  /// Useful when you need access to GoRouter-specific features in guards.
  dynamic get goRouterState => get<dynamic>('goRouterState');

  /// Convenience getter for BuildContext.
  ///
  /// Use sparingly - prefer dependency injection over context.
  BuildContext? get context => get<BuildContext>('context');

  /// Creates a copy with modified fields.
  GuardContext copyWith({
    RouteDefinition? destination,
    Object? navigationExtra,
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
    String? matchedLocation,
    Map<String, Object?>? extras,
  }) {
    return GuardContext(
      destination: destination ?? this.destination,
      navigationExtra: navigationExtra ?? this.navigationExtra,
      pathParameters: pathParameters ?? this.pathParameters,
      queryParameters: queryParameters ?? this.queryParameters,
      matchedLocation: matchedLocation ?? this.matchedLocation,
      extras: extras ?? this.extras,
    );
  }

  @override
  String toString() {
    return 'GuardContext(destination: $destination, matchedLocation: $matchedLocation)';
  }
}
