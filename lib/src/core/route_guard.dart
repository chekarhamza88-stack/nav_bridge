import 'dart:async';

import 'guard_context.dart';
import 'guard_result.dart';

/// Base class for route guards.
/// 
/// Implement this class to create guards that control navigation access.
/// Guards are executed in order of priority (higher priority first).
/// 
/// ## Example
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   int get priority => 100; // Higher = runs first
///   
///   @override
///   Future<GuardResult> canActivate(GuardContext context) async {
///     final ref = context.ref;
///     if (ref == null) return GuardResult.allow();
///     
///     final isAuthenticated = ref.read(authProvider).isAuthenticated;
///     if (!isAuthenticated) {
///       return GuardResult.redirect('/login');
///     }
///     return GuardResult.allow();
///   }
/// }
/// ```
abstract class RouteGuard {
  const RouteGuard();

  /// Priority for guard execution order.
  /// 
  /// Higher priority guards run first. Default is 0.
  /// 
  /// Common convention:
  /// - 1000+ : Critical guards (maintenance mode, etc.)
  /// - 100-999 : Auth guards
  /// - 10-99 : Permission guards
  /// - 0-9 : Feature guards
  int get priority => 0;

  /// Determines if navigation should be allowed.
  /// 
  /// Return:
  /// - [GuardResult.allow] to proceed
  /// - [GuardResult.redirect] to redirect
  /// - [GuardResult.reject] to block navigation
  Future<GuardResult> canActivate(GuardContext context);

  /// Optional: Called when leaving a route.
  /// 
  /// Return false to prevent navigation away from the current route.
  Future<bool> canDeactivate(GuardContext context) async => true;

  /// Optional: Routes this guard applies to.
  /// 
  /// If null, guard applies to all routes.
  /// If non-null, only applies to routes matching these patterns.
  List<String>? get appliesTo => null;

  /// Optional: Routes this guard excludes.
  /// 
  /// These routes bypass this guard even if they match [appliesTo].
  List<String>? get excludes => null;

  /// Checks if this guard should run for the given path.
  bool shouldActivateFor(String path) {
    // Check excludes first
    if (excludes != null) {
      for (final pattern in excludes!) {
        if (_matchesPattern(path, pattern)) {
          return false;
        }
      }
    }

    // If no appliesTo, guard applies to all routes
    if (appliesTo == null) {
      return true;
    }

    // Check if path matches any appliesTo pattern
    for (final pattern in appliesTo!) {
      if (_matchesPattern(path, pattern)) {
        return true;
      }
    }

    return false;
  }

  bool _matchesPattern(String path, String pattern) {
    // Exact match
    if (pattern == path) return true;

    // Wildcard match (e.g., '/admin/*')
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return path.startsWith(prefix);
    }

    // Parameter match (e.g., '/users/:id')
    final patternSegments = pattern.split('/');
    final pathSegments = path.split('/');

    if (patternSegments.length != pathSegments.length) {
      return false;
    }

    for (var i = 0; i < patternSegments.length; i++) {
      final patternSeg = patternSegments[i];
      final pathSeg = pathSegments[i];

      if (patternSeg.startsWith(':')) continue;
      if (patternSeg != pathSeg) return false;
    }

    return true;
  }
}

/// A guard that combines multiple guards with AND logic.
/// 
/// All guards must allow for navigation to proceed.
class CompositeGuard extends RouteGuard {
  final List<RouteGuard> guards;

  CompositeGuard(this.guards);

  @override
  int get priority => guards.map((g) => g.priority).fold(0, (a, b) => a > b ? a : b);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    for (final guard in guards) {
      final result = await guard.canActivate(context);
      if (!result.isAllowed) {
        return result;
      }
    }
    return GuardResult.allow();
  }
}

/// A guard that combines multiple guards with OR logic.
/// 
/// At least one guard must allow for navigation to proceed.
class AnyGuard extends RouteGuard {
  final List<RouteGuard> guards;

  AnyGuard(this.guards);

  @override
  int get priority => guards.map((g) => g.priority).fold(0, (a, b) => a > b ? a : b);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    GuardResult? lastReject;
    
    for (final guard in guards) {
      final result = await guard.canActivate(context);
      if (result.isAllowed) {
        return result;
      }
      lastReject = result;
    }
    
    return lastReject ?? GuardResult.reject(reason: 'No guards allowed');
  }
}
