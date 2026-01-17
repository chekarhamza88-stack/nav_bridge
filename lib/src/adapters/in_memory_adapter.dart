import 'dart:async';

import '../core/guard_context.dart';
import '../core/guard_result.dart';
import '../core/route_definition.dart';
import '../core/route_guard.dart';
import '../core/router_adapter.dart';

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
  final StreamController<String> _locationController = StreamController.broadcast();
  
  /// DI context passed to guards.
  Map<String, Object?> guardContext;
  
  String _currentLocation;
  Map<String, String> _currentPathParams = {};
  Map<String, String> _currentQueryParams = {};
  String? _currentRouteName;

  InMemoryAdapter({
    String initialLocation = '/',
    List<RouteGuard>? guards,
    this.guardContext = const {},
  })  : _currentLocation = initialLocation,
        _guards = guards ?? [] {
    _navigationStack.add(initialLocation);
  }

  /// All navigation events (useful for detailed testing).
  List<NavigationEvent> get history => List.unmodifiable(_history);

  /// Just the locations navigated to.
  List<String> get navigationHistory =>
      _history.map((e) => e.to).toList();

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
  Future<String?> _runGuards(String to) async {
    final sortedGuards = List<RouteGuard>.from(_guards)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    for (final guard in sortedGuards) {
      if (!guard.shouldActivateFor(to)) continue;

      final context = GuardContext(
        destination: RouteDefinition(path: to),
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
          return path;
        case GuardReject():
          // For testing, we might want to track this
          _history.add(NavigationEvent(
            from: _currentLocation,
            to: to,
            type: NavigationType.rejected,
          ));
          return null; // Stay on current location
      }
    }

    return null; // No redirect needed
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
    
    final redirect = await _runGuards(location);
    final finalLocation = redirect ?? location;
    
    _currentLocation = finalLocation;
    _currentPathParams = _extractPathParams(finalLocation);
    _currentQueryParams = _extractQueryParams(finalLocation);
    _navigationStack.clear();
    _navigationStack.add(finalLocation);
    
    _history.add(NavigationEvent(
      from: from,
      to: finalLocation,
      type: redirect != null ? NavigationType.redirected : NavigationType.go,
      redirectedFrom: redirect != null ? location : null,
    ));
    
    _locationController.add(finalLocation);
  }

  @override
  Future<void> push(String location, {Object? extra}) async {
    final from = _currentLocation;
    
    final redirect = await _runGuards(location);
    final finalLocation = redirect ?? location;
    
    _currentLocation = finalLocation;
    _currentPathParams = _extractPathParams(finalLocation);
    _currentQueryParams = _extractQueryParams(finalLocation);
    _navigationStack.add(finalLocation);
    
    _history.add(NavigationEvent(
      from: from,
      to: finalLocation,
      type: redirect != null ? NavigationType.redirected : NavigationType.push,
      redirectedFrom: redirect != null ? location : null,
    ));
    
    _locationController.add(finalLocation);
  }

  @override
  Future<void> replace(String location, {Object? extra}) async {
    final from = _currentLocation;
    
    final redirect = await _runGuards(location);
    final finalLocation = redirect ?? location;
    
    _currentLocation = finalLocation;
    _currentPathParams = _extractPathParams(finalLocation);
    _currentQueryParams = _extractQueryParams(finalLocation);
    if (_navigationStack.isNotEmpty) {
      _navigationStack[_navigationStack.length - 1] = finalLocation;
    }
    
    _history.add(NavigationEvent(
      from: from,
      to: finalLocation,
      type: redirect != null ? NavigationType.redirected : NavigationType.replace,
      redirectedFrom: redirect != null ? location : null,
    ));
    
    _locationController.add(finalLocation);
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
    while (_navigationStack.length > 1 && !predicate(_currentLocation) && iterations < maxIterations) {
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
  Map<String, String> get currentPathParameters => Map.unmodifiable(_currentPathParams);

  @override
  Map<String, String> get currentQueryParameters => Map.unmodifiable(_currentQueryParams);

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
