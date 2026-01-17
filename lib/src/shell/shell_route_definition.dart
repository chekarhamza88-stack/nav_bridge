import 'package:flutter/widgets.dart';

import '../core/route_definition.dart';

/// Defines a shell route for nested navigation (tabs, bottom nav, etc.).
///
/// This maps to GoRouter's StatefulShellRoute pattern while remaining
/// router-agnostic.
///
/// ## Example
/// ```dart
/// final shellRoute = ShellRouteDefinition(
///   builder: (context, state, child) => MainShell(child: child),
///   branches: [
///     ShellBranch(
///       routes: [
///         RouteDefinition(path: '/home', builder: (_, __) => HomeScreen()),
///       ],
///     ),
///     ShellBranch(
///       routes: [
///         RouteDefinition(path: '/profile', builder: (_, __) => ProfileScreen()),
///       ],
///     ),
///   ],
/// );
/// ```
class ShellRouteDefinition extends RouteDefinition {
  /// Builder for the shell widget (contains bottom nav, drawer, etc.).
  final Widget Function(
    BuildContext context,
    dynamic state,
    Widget child,
  ) shellBuilder;

  /// Navigation branches (each branch is a tab or navigation section).
  final List<ShellBranch> branches;

  /// Whether to preserve state when switching branches.
  final bool preserveState;

  /// Custom page builder for the shell.
  final dynamic Function(
    BuildContext context,
    dynamic state,
    Widget child,
  )? shellPageBuilder;

  /// Navigator keys for each branch (for advanced navigation control).
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  ShellRouteDefinition({
    required this.shellBuilder,
    required this.branches,
    this.preserveState = true,
    this.shellPageBuilder,
    this.navigatorKeys,
    super.name,
    super.guardTypes,
    super.metadata,
  }) : super(
          path: '', // Shell routes don't have a path
          children: branches.expand((b) => b.routes).toList(),
        );

  /// Get routes for a specific branch index.
  List<RouteDefinition> getRoutesForBranch(int index) {
    if (index < 0 || index >= branches.length) return [];
    return branches[index].routes;
  }

  /// Find which branch a path belongs to.
  int? findBranchForPath(String path) {
    for (var i = 0; i < branches.length; i++) {
      for (final route in branches[i].routes) {
        if (route.matches(path)) return i;
      }
    }
    return null;
  }
}

/// A navigation branch within a shell (represents a tab or section).
///
/// ## Example
/// ```dart
/// ShellBranch(
///   initialLocation: '/home',
///   routes: [
///     RouteDefinition(path: '/home', builder: (_, __) => HomeScreen()),
///     RouteDefinition(path: '/home/details/:id', builder: (_, p) => DetailsScreen(p['id']!)),
///   ],
/// )
/// ```
class ShellBranch {
  /// Routes in this branch.
  final List<RouteDefinition> routes;

  /// Initial location when this branch is selected.
  final String? initialLocation;

  /// Navigator key for this branch (optional).
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Whether to restore state when returning to this branch.
  final bool restorationEnabled;

  /// Observers for this branch's navigator.
  final List<NavigatorObserver>? observers;

  ShellBranch({
    required this.routes,
    this.initialLocation,
    this.navigatorKey,
    this.restorationEnabled = true,
    this.observers,
  });

  /// Get the initial location for this branch.
  String get effectiveInitialLocation {
    if (initialLocation != null) return initialLocation!;
    if (routes.isNotEmpty) return routes.first.path;
    return '/';
  }
}

/// Configuration for nested navigation within shells.
///
/// ## Example
/// ```dart
/// NestedNavigationConfig(
///   parentPath: '/dashboard',
///   children: [
///     RouteDefinition(path: 'overview', builder: ...),
///     RouteDefinition(path: 'analytics', builder: ...),
///   ],
/// )
/// ```
class NestedNavigationConfig {
  /// Parent path for nested routes.
  final String parentPath;

  /// Child routes (paths are relative to parent).
  final List<RouteDefinition> children;

  /// Builder for the nested navigation container.
  final Widget Function(BuildContext context, Widget child)? containerBuilder;

  NestedNavigationConfig({
    required this.parentPath,
    required this.children,
    this.containerBuilder,
  });

  /// Get full paths for all children.
  List<String> get fullPaths {
    return children.map((c) {
      final childPath = c.path.startsWith('/') ? c.path.substring(1) : c.path;
      return '$parentPath/$childPath';
    }).toList();
  }
}
