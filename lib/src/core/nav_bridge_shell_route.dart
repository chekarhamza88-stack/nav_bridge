import 'package:flutter/widgets.dart';

import 'nav_bridge_route.dart';
import 'route_params.dart';

/// Shell route for tab-based or nested navigation.
///
/// Use this class to create shell routes that contain multiple branches,
/// typically used for bottom navigation bars, side navigation, or tab bars.
///
/// ## Example
/// ```dart
/// NavBridgeShellRoute(
///   path: '/dashboard',
///   shellBuilder: (context, child) => DashboardShell(child: child),
///   branches: [
///     NavBridgeBranch(
///       initialLocation: '/dashboard/home',
///       routes: [
///         NavBridgeRoute(
///           path: 'home',
///           name: 'dashboardHome',
///           builder: (_, __) => const HomeTab(),
///         ),
///       ],
///     ),
///     NavBridgeBranch(
///       initialLocation: '/dashboard/settings',
///       routes: [
///         NavBridgeRoute(
///           path: 'settings',
///           name: 'dashboardSettings',
///           builder: (_, __) => const SettingsTab(),
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class NavBridgeShellRoute extends NavBridgeRoute {
  /// The branches in this shell route.
  final List<NavBridgeBranch> branches;

  /// Builder for the shell wrapper widget.
  ///
  /// The `child` parameter is the currently active branch's widget.
  final Widget Function(BuildContext context, Widget child) shellBuilder;

  /// Whether to preserve the state of inactive branches.
  final bool preserveState;

  /// Index of the initially selected branch.
  final int initialBranchIndex;

  /// Creates a NavBridgeShellRoute.
  NavBridgeShellRoute({
    required super.path,
    super.name,
    required this.branches,
    required this.shellBuilder,
    this.preserveState = true,
    this.initialBranchIndex = 0,
    super.guards = const [],
    super.metadata = const {},
  }) : super(
          builder: _defaultBuilder,
        );

  /// Default builder (shell routes use shellBuilder instead).
  static Widget _defaultBuilder(BuildContext context, RouteParams params) {
    return const SizedBox.shrink();
  }

  /// Gets the current branch index based on location.
  int getBranchIndex(String location) {
    for (var i = 0; i < branches.length; i++) {
      if (location.startsWith(branches[i].initialLocation)) {
        return i;
      }
    }
    return initialBranchIndex;
  }

  /// Gets the initial location for a branch index.
  String getInitialLocationForBranch(int index) {
    if (index < 0 || index >= branches.length) {
      return branches[initialBranchIndex].initialLocation;
    }
    return branches[index].initialLocation;
  }

  @override
  String toString() =>
      'NavBridgeShellRoute(path: $path, branches: ${branches.length})';
}

/// Represents a branch in a shell route.
///
/// Each branch typically corresponds to a tab or section in the navigation.
class NavBridgeBranch {
  /// Optional navigator key for this branch.
  ///
  /// If provided, each branch will have its own navigation stack.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The initial location when this branch is selected.
  final String initialLocation;

  /// The routes in this branch.
  final List<NavBridgeRoute> routes;

  /// Whether to restore the last location when returning to this branch.
  final bool restorationEnabled;

  /// Optional label for this branch (useful for accessibility).
  final String? label;

  /// Creates a NavBridgeBranch.
  const NavBridgeBranch({
    this.navigatorKey,
    required this.initialLocation,
    required this.routes,
    this.restorationEnabled = true,
    this.label,
  });

  @override
  String toString() =>
      'NavBridgeBranch(initialLocation: $initialLocation, routes: ${routes.length})';
}

/// A shell route that uses an indexed stack for branch management.
///
/// This is the most common type of shell route, where branches
/// are displayed one at a time based on an index.
class NavBridgeIndexedShellRoute extends NavBridgeShellRoute {
  /// Creates an indexed shell route.
  NavBridgeIndexedShellRoute({
    required super.path,
    super.name,
    required super.branches,
    required super.shellBuilder,
    super.preserveState = true,
    super.initialBranchIndex = 0,
    super.guards = const [],
    super.metadata = const {},
  });
}

/// A shell route that uses a navigator for each branch.
///
/// Each branch has its own navigation stack, allowing for
/// independent navigation within each branch.
class NavBridgeNavigatingShellRoute extends NavBridgeShellRoute {
  /// Observer for navigation events within branches.
  final NavigatorObserver? observer;

  /// Creates a navigating shell route.
  NavBridgeNavigatingShellRoute({
    required super.path,
    super.name,
    required super.branches,
    required super.shellBuilder,
    super.preserveState = true,
    super.initialBranchIndex = 0,
    super.guards = const [],
    super.metadata = const {},
    this.observer,
  });
}
