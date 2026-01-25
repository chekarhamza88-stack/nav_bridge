import 'package:flutter/widgets.dart';

import 'route_params.dart';

/// Transition types for route animations.
enum TransitionType {
  /// Material Design transition (Android-style).
  material,

  /// Cupertino transition (iOS-style).
  cupertino,

  /// Fade transition.
  fade,

  /// Slide transition (left to right).
  slide,

  /// Slide up transition (bottom to top).
  slideUp,

  /// Scale transition.
  scale,

  /// No transition (instant).
  none,
}

/// Router-agnostic route definition.
///
/// Use this class to define routes without depending on GoRouter types.
/// Nav Bridge will convert these to the appropriate router-specific
/// route types when building the router.
///
/// ## Example
/// ```dart
/// final routes = [
///   NavBridgeRoute(
///     path: '/',
///     name: 'home',
///     builder: (context, params) => const HomeScreen(),
///   ),
///   NavBridgeRoute(
///     path: '/users/:userId',
///     name: 'userDetails',
///     guards: [AuthGuard],
///     builder: (context, params) => UserDetailsScreen(
///       userId: params.get('userId'),
///     ),
///   ),
/// ];
/// ```
class NavBridgeRoute<T> {
  /// The path pattern for this route.
  ///
  /// Supports path parameters with `:` prefix (e.g., `/users/:userId`).
  final String path;

  /// Optional name for named navigation.
  ///
  /// If provided, this route can be navigated to using
  /// [RouterAdapter.goNamed] and similar methods.
  final String? name;

  /// Builder function that creates the widget for this route.
  final Widget Function(BuildContext context, RouteParams params) builder;

  /// Child routes nested under this route.
  final List<NavBridgeRoute> children;

  /// Guard types that should protect this route.
  ///
  /// These guards will be evaluated before allowing navigation
  /// to this route.
  final List<Type> guards;

  /// Arbitrary metadata associated with this route.
  ///
  /// Can be used by guards or builders to make decisions.
  final Map<String, dynamic> metadata;

  /// Transition animation to use for this route.
  final TransitionType? transitionType;

  /// Custom transition duration.
  final Duration? transitionDuration;

  /// Whether this is a full-screen dialog route.
  final bool fullscreenDialog;

  /// Whether this route can be maintained in memory when not visible.
  final bool maintainState;

  /// Creates a new NavBridgeRoute.
  const NavBridgeRoute({
    required this.path,
    this.name,
    required this.builder,
    this.children = const [],
    this.guards = const [],
    this.metadata = const {},
    this.transitionType,
    this.transitionDuration,
    this.fullscreenDialog = false,
    this.maintainState = true,
  });

  /// Creates a redirect route.
  ///
  /// When this route is matched, navigation will be redirected
  /// to the specified destination.
  ///
  /// ## Example
  /// ```dart
  /// NavBridgeRoute.redirect(
  ///   from: '/old-path',
  ///   to: '/new-path',
  /// )
  /// ```
  factory NavBridgeRoute.redirect({
    required String from,
    required String to,
    String? name,
  }) {
    return NavBridgeRedirectRoute(
      path: from,
      redirectTo: to,
      name: name,
    );
  }

  /// Creates a parent route that only contains child routes.
  ///
  /// This is useful for route grouping without a visible page.
  ///
  /// ## Example
  /// ```dart
  /// NavBridgeRoute.parent(
  ///   path: '/settings',
  ///   children: [
  ///     NavBridgeRoute(path: 'profile', ...),
  ///     NavBridgeRoute(path: 'security', ...),
  ///   ],
  /// )
  /// ```
  factory NavBridgeRoute.parent({
    required String path,
    String? name,
    required List<NavBridgeRoute> children,
    List<Type> guards = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return NavBridgeRoute(
      path: path,
      name: name,
      // Parent routes redirect to first child by default
      builder: (_, __) => const SizedBox.shrink(),
      children: children,
      guards: guards,
      metadata: metadata,
    );
  }

  /// Checks if this route matches the given path.
  bool matches(String location) {
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final locationSegments = location
        .split('?')
        .first
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    if (pathSegments.length != locationSegments.length) {
      return false;
    }

    for (var i = 0; i < pathSegments.length; i++) {
      final pathSegment = pathSegments[i];
      final locationSegment = locationSegments[i];

      // Parameter segment (matches any value)
      if (pathSegment.startsWith(':')) continue;

      // Wildcard segment
      if (pathSegment == '*') continue;

      // Exact match required
      if (pathSegment != locationSegment) return false;
    }

    return true;
  }

  /// Extracts path parameters from a location that matches this route.
  Map<String, String> extractParams(String location) {
    final params = <String, String>{};
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final locationSegments = location
        .split('?')
        .first
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    for (var i = 0;
        i < pathSegments.length && i < locationSegments.length;
        i++) {
      final pathSegment = pathSegments[i];
      if (pathSegment.startsWith(':')) {
        params[pathSegment.substring(1)] = locationSegments[i];
      }
    }

    return params;
  }

  /// Creates a copy of this route with the given fields replaced.
  NavBridgeRoute<T> copyWith({
    String? path,
    String? name,
    Widget Function(BuildContext, RouteParams)? builder,
    List<NavBridgeRoute>? children,
    List<Type>? guards,
    Map<String, dynamic>? metadata,
    TransitionType? transitionType,
    Duration? transitionDuration,
    bool? fullscreenDialog,
    bool? maintainState,
  }) {
    return NavBridgeRoute<T>(
      path: path ?? this.path,
      name: name ?? this.name,
      builder: builder ?? this.builder,
      children: children ?? this.children,
      guards: guards ?? this.guards,
      metadata: metadata ?? this.metadata,
      transitionType: transitionType ?? this.transitionType,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      maintainState: maintainState ?? this.maintainState,
    );
  }

  @override
  String toString() => 'NavBridgeRoute(path: $path, name: $name)';
}

/// A route that redirects to another location.
class NavBridgeRedirectRoute<T> extends NavBridgeRoute<T> {
  /// The destination path to redirect to.
  final String redirectTo;

  /// Creates a redirect route.
  NavBridgeRedirectRoute({
    required super.path,
    required this.redirectTo,
    super.name,
  }) : super(
          builder: (_, __) => const SizedBox.shrink(),
        );

  @override
  String toString() =>
      'NavBridgeRedirectRoute(path: $path, redirectTo: $redirectTo)';
}
