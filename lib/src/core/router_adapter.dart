import 'route_definition.dart';
import 'route_guard.dart';
import 'typed_route.dart';

/// Abstract interface for router adapters.
///
/// This is the contract that all router implementations must follow,
/// enabling router-agnostic navigation in your application.
///
/// ## Available Implementations
/// - [GoRouterAdapter] - For GoRouter
/// - [InMemoryAdapter] - For unit testing
///
/// ## Example
/// ```dart
/// abstract class AppRouter {
///   RouterAdapter get adapter;
///
///   Future<void> goToHome() => adapter.go('/');
///   Future<void> goToProfile(String userId) => adapter.go('/profile/$userId');
/// }
/// ```
abstract class RouterAdapter {
  /// Navigate to a new location, replacing the current history.
  Future<void> go(String location, {Object? extra});

  /// Push a new location onto the navigation stack.
  Future<void> push(String location, {Object? extra});

  /// Replace the current location without adding to history.
  Future<void> replace(String location, {Object? extra});

  // Named navigation methods

  /// Navigate to a named route, replacing the current history.
  Future<void> goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  });

  /// Push a named route onto the navigation stack.
  Future<void> pushNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  });

  /// Replace the current location with a named route.
  Future<void> replaceNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  });

  // Type-safe navigation methods

  /// Navigate to a typed route, replacing the current history.
  Future<void> goToRoute(TypedRoute route);

  /// Push a typed route onto the navigation stack.
  Future<void> pushRoute(TypedRoute route);

  /// Replace the current location with a typed route.
  Future<void> replaceRoute(TypedRoute route);

  /// Pop the current location from the stack.
  void pop<T>([T? result]);

  /// Pop until a condition is met.
  void popUntil(bool Function(String path) predicate);

  /// Check if we can pop.
  bool canPop();

  /// Get the current location.
  String get currentLocation;

  /// Get the current route name (if available).
  String? get currentRouteName;

  /// Get the current path parameters.
  Map<String, String> get currentPathParameters;

  /// Get the current query parameters.
  Map<String, String> get currentQueryParameters;

  /// Stream of location changes.
  Stream<String> get locationStream;

  /// Register a route guard.
  void addGuard(RouteGuard guard);

  /// Remove a route guard.
  void removeGuard(RouteGuard guard);

  /// Get all registered guards.
  List<RouteGuard> get guards;

  /// Refresh the router (re-evaluate guards).
  void refresh();

  /// Dispose of resources.
  void dispose();
}

/// Configuration for router adapters.
class ComposerRouterConfig {
  /// Initial location when the app starts.
  final String initialLocation;

  /// Route definitions.
  final List<RouteDefinition> routes;

  /// Global route guards.
  final List<RouteGuard> guards;

  /// Error page builder.
  final Function(Exception error)? errorBuilder;

  /// Enable debug logging.
  final bool debugLogNavigation;

  /// Observer for navigation events.
  final NavigationObserver? observer;

  const ComposerRouterConfig({
    this.initialLocation = '/',
    this.routes = const [],
    this.guards = const [],
    this.errorBuilder,
    this.debugLogNavigation = false,
    this.observer,
  });

  ComposerRouterConfig copyWith({
    String? initialLocation,
    List<RouteDefinition>? routes,
    List<RouteGuard>? guards,
    Function(Exception error)? errorBuilder,
    bool? debugLogNavigation,
    NavigationObserver? observer,
  }) {
    return ComposerRouterConfig(
      initialLocation: initialLocation ?? this.initialLocation,
      routes: routes ?? this.routes,
      guards: guards ?? this.guards,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      debugLogNavigation: debugLogNavigation ?? this.debugLogNavigation,
      observer: observer ?? this.observer,
    );
  }
}

/// Observer for navigation events.
abstract class NavigationObserver {
  /// Called before navigation occurs.
  void onNavigating(String from, String to) {}

  /// Called after navigation completes.
  void onNavigated(String from, String to) {}

  /// Called when a guard redirects navigation.
  void onGuardRedirect(String from, String to, String redirectTo) {}

  /// Called when a guard rejects navigation.
  void onGuardReject(String from, String to, String? reason) {}

  /// Called when navigation fails.
  void onNavigationError(String to, Object error) {}
}

/// A simple logging navigation observer.
class LoggingNavigationObserver extends NavigationObserver {
  final void Function(String message)? logger;

  LoggingNavigationObserver({this.logger});

  void _log(String message) {
    if (logger != null) {
      logger!(message);
    } else {
      // ignore: avoid_print
      print('[Navigation] $message');
    }
  }

  @override
  void onNavigating(String from, String to) {
    _log('Navigating: $from → $to');
  }

  @override
  void onNavigated(String from, String to) {
    _log('Navigated: $from → $to');
  }

  @override
  void onGuardRedirect(String from, String to, String redirectTo) {
    _log('Guard redirect: $to → $redirectTo');
  }

  @override
  void onGuardReject(String from, String to, String? reason) {
    _log('Guard rejected: $to (reason: $reason)');
  }

  @override
  void onNavigationError(String to, Object error) {
    _log('Navigation error to $to: $error');
  }
}
