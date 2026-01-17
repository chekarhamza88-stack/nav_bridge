import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/guard_context.dart';
import '../core/guard_result.dart';
import '../core/route_guard.dart';

/// Bridge adapter for existing GoRouter guards.
/// 
/// Allows you to use your existing guard functions with Nav Bridge
/// without any modifications.
/// 
/// ## Example
/// ```dart
/// // Your existing guard function
/// FutureOr<GuardResult> myLegacyGuard(
///   BuildContext context,
///   GoRouterState state,
///   Ref ref,
/// ) async {
///   final isAuthenticated = ref.read(authProvider).isAuthenticated;
///   if (!isAuthenticated) {
///     return GuardResult.redirect('/login');
///   }
///   return GuardResult.allow();
/// }
/// 
/// // Bridge it to Nav Bridge
/// final bridgedGuard = GoRouterGuardBridge(myLegacyGuard);
/// 
/// // Use in adapter
/// final adapter = GoRouterAdapter.wrap(
///   existingRouter,
///   additionalGuards: [bridgedGuard],
/// );
/// ```
/// 
/// ## Migration Path
/// 1. Initially bridge all existing guards (zero changes)
/// 2. Gradually refactor to RiverpodRouteGuard (when convenient)
/// 3. Remove bridges as guards are modernized
class GoRouterGuardBridge extends RouteGuard {
  /// The legacy guard function to bridge.
  final FutureOr<GuardResult> Function(
    BuildContext context,
    GoRouterState state,
    dynamic ref,
  ) legacyGuard;

  /// Priority for this guard (higher runs first).
  final int _priority;

  /// Routes this guard applies to (null = all routes).
  final List<String>? _appliesTo;

  /// Routes this guard excludes.
  final List<String>? _excludes;

  GoRouterGuardBridge(
    this.legacyGuard, {
    int priority = 0,
    List<String>? appliesTo,
    List<String>? excludes,
  })  : _priority = priority,
        _appliesTo = appliesTo,
        _excludes = excludes;

  @override
  int get priority => _priority;

  @override
  List<String>? get appliesTo => _appliesTo;

  @override
  List<String>? get excludes => _excludes;

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    final buildContext = context.context;
    final goRouterState = context.goRouterState;
    final ref = context.ref;

    if (buildContext == null) {
      throw StateError(
        'GoRouterGuardBridge requires BuildContext in GuardContext.extras. '
        'Make sure to set adapter.contextBuilder = (state) => {"context": context, ...}',
      );
    }

    if (goRouterState == null) {
      throw StateError(
        'GoRouterGuardBridge requires GoRouterState in GuardContext.extras. '
        'Make sure to set adapter.contextBuilder = (state) => {"goRouterState": state, ...}',
      );
    }

    return legacyGuard(buildContext, goRouterState as GoRouterState, ref);
  }
}

/// Bridge for guards that only need BuildContext and GoRouterState.
/// 
/// Use this when your legacy guards don't use Riverpod.
class SimpleGoRouterGuardBridge extends RouteGuard {
  /// The legacy guard function to bridge.
  final FutureOr<GuardResult> Function(
    BuildContext context,
    GoRouterState state,
  ) legacyGuard;

  final int _priority;
  final List<String>? _appliesTo;
  final List<String>? _excludes;

  SimpleGoRouterGuardBridge(
    this.legacyGuard, {
    int priority = 0,
    List<String>? appliesTo,
    List<String>? excludes,
  })  : _priority = priority,
        _appliesTo = appliesTo,
        _excludes = excludes;

  @override
  int get priority => _priority;

  @override
  List<String>? get appliesTo => _appliesTo;

  @override
  List<String>? get excludes => _excludes;

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    final buildContext = context.context;
    final goRouterState = context.goRouterState;

    if (buildContext == null || goRouterState == null) {
      throw StateError(
        'SimpleGoRouterGuardBridge requires BuildContext and GoRouterState in extras.',
      );
    }

    return legacyGuard(buildContext, goRouterState as GoRouterState);
  }
}

/// Convert a GoRouter redirect function to a RouteGuard.
/// 
/// This is useful when you have existing redirect logic that returns
/// a path string (or null to allow).
/// 
/// ## Example
/// ```dart
/// // Your existing redirect function
/// String? myRedirectLogic(BuildContext context, GoRouterState state) {
///   if (!isLoggedIn && state.matchedLocation.startsWith('/protected')) {
///     return '/login';
///   }
///   return null;
/// }
/// 
/// // Convert to guard
/// final guard = GoRouterRedirectBridge(myRedirectLogic);
/// ```
class GoRouterRedirectBridge extends RouteGuard {
  /// The legacy redirect function.
  final FutureOr<String?> Function(
    BuildContext context,
    GoRouterState state,
  ) redirectFunction;

  final int _priority;

  GoRouterRedirectBridge(
    this.redirectFunction, {
    int priority = 0,
  }) : _priority = priority;

  @override
  int get priority => _priority;

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    final buildContext = context.context;
    final goRouterState = context.goRouterState;

    if (buildContext == null || goRouterState == null) {
      throw StateError(
        'GoRouterRedirectBridge requires BuildContext and GoRouterState in extras.',
      );
    }

    final redirect = await redirectFunction(
      buildContext,
      goRouterState as GoRouterState,
    );

    if (redirect != null) {
      return GuardResult.redirect(redirect);
    }

    return GuardResult.allow();
  }
}

/// Bridge for guards that use the GuardManager pattern.
/// 
/// If you have a GuardManager class that orchestrates multiple guards,
/// you can bridge the entire manager.
class GuardManagerBridge extends RouteGuard {
  /// Function that checks all guards and returns redirect path or null.
  final FutureOr<String?> Function(
    BuildContext context,
    GoRouterState state,
    dynamic ref,
  ) checkAllGuards;

  final int _priority;

  GuardManagerBridge(
    this.checkAllGuards, {
    int priority = 1000, // High priority since it wraps multiple guards
  }) : _priority = priority;

  @override
  int get priority => _priority;

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    final buildContext = context.context;
    final goRouterState = context.goRouterState;
    final ref = context.ref;

    if (buildContext == null || goRouterState == null) {
      throw StateError(
        'GuardManagerBridge requires BuildContext and GoRouterState in extras.',
      );
    }

    final redirect = await checkAllGuards(
      buildContext,
      goRouterState as GoRouterState,
      ref,
    );

    if (redirect != null) {
      return GuardResult.redirect(redirect);
    }

    return GuardResult.allow();
  }
}
