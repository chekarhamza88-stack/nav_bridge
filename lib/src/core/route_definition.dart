import 'package:flutter/widgets.dart';

/// Defines a route in the application.
/// 
/// This is a router-agnostic representation of a route that can be
/// converted to GoRouter, AutoRoute, or any other routing solution.
/// 
/// ## Example
/// ```dart
/// final profileRoute = RouteDefinition(
///   path: '/profile/:userId',
///   name: 'profile',
///   builder: (context, params) => ProfileScreen(
///     userId: params['userId']!,
///   ),
/// );
/// ```
class RouteDefinition {
  /// The path pattern for this route (e.g., '/users/:id').
  final String path;

  /// Optional name for named navigation.
  final String? name;

  /// Widget builder for this route.
  final Widget Function(BuildContext context, Map<String, String> params)? builder;

  /// Page builder for custom transitions.
  final Page<dynamic> Function(BuildContext context, Map<String, String> params)? pageBuilder;

  /// Nested child routes.
  final List<RouteDefinition> children;

  /// Route-specific guard types (in addition to global guards).
  /// These are type references that can be resolved at runtime.
  final List<Type> guardTypes;

  /// Metadata for this route.
  final Map<String, dynamic> metadata;

  /// If true, this route should redirect rather than render.
  final String? redirectTo;

  RouteDefinition({
    required this.path,
    this.name,
    this.builder,
    this.pageBuilder,
    this.children = const [],
    this.guardTypes = const [],
    this.metadata = const {},
    this.redirectTo,
  }) : assert(
         builder != null || pageBuilder != null || redirectTo != null || children.isNotEmpty,
         'Route must have a builder, pageBuilder, redirectTo, or children',
       );

  /// Creates a redirect route.
  factory RouteDefinition.redirect({
    required String from,
    required String to,
  }) {
    return RouteDefinition(
      path: from,
      redirectTo: to,
    );
  }

  /// Creates a route with children (for nested navigation).
  factory RouteDefinition.parent({
    required String path,
    String? name,
    required List<RouteDefinition> children,
    Widget Function(BuildContext context, Widget child)? shellBuilder,
  }) {
    return RouteDefinition(
      path: path,
      name: name,
      children: children,
      builder: shellBuilder != null
          ? (context, params) => shellBuilder(context, const SizedBox())
          : null,
    );
  }

  /// Checks if this route matches a given path.
  bool matches(String location) {
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final locationSegments = location.split('/').where((s) => s.isNotEmpty).toList();

    if (pathSegments.length != locationSegments.length) {
      return false;
    }

    for (var i = 0; i < pathSegments.length; i++) {
      final pathSegment = pathSegments[i];
      final locationSegment = locationSegments[i];

      if (pathSegment.startsWith(':')) {
        continue; // Parameter segment matches anything
      }

      if (pathSegment != locationSegment) {
        return false;
      }
    }

    return true;
  }

  /// Extracts parameters from a location.
  Map<String, String> extractParams(String location) {
    final params = <String, String>{};
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final locationSegments = location.split('/').where((s) => s.isNotEmpty).toList();

    for (var i = 0; i < pathSegments.length && i < locationSegments.length; i++) {
      final pathSegment = pathSegments[i];
      if (pathSegment.startsWith(':')) {
        final paramName = pathSegment.substring(1);
        params[paramName] = locationSegments[i];
      }
    }

    return params;
  }

  @override
  String toString() => 'RouteDefinition(path: $path, name: $name)';
}
