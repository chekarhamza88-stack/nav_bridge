import '../core/guard_context.dart';
import '../core/guard_result.dart';
import '../core/route_guard.dart';

/// Base class for route guards that use Riverpod for dependency injection.
/// 
/// Extend this class when your guard needs access to Riverpod providers.
/// 
/// ## Example
/// ```dart
/// class AuthGuard extends RiverpodRouteGuard {
///   @override
///   int get priority => 100;
///   
///   @override
///   Future<GuardResult> canActivateWithRef(
///     GuardContext context,
///     Ref ref,
///   ) async {
///     final authState = ref.read(authProvider);
///     
///     if (!authState.isAuthenticated) {
///       return GuardResult.redirect('/login');
///     }
///     
///     return GuardResult.allow();
///   }
/// }
/// ```
/// 
/// ## Setup
/// Make sure to provide the Ref in your GoRouterAdapter:
/// ```dart
/// adapter.contextBuilder = (state) => {
///   'ref': ref,
///   'goRouterState': state,
/// };
/// ```
abstract class RiverpodRouteGuard extends RouteGuard {
  const RiverpodRouteGuard();

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    final ref = context.ref;
    if (ref == null) {
      throw StateError(
        'RiverpodRouteGuard requires a Ref in GuardContext.extras. '
        'Make sure to set adapter.contextBuilder = (state) => {"ref": ref, ...}',
      );
    }
    return canActivateWithRef(context, ref);
  }

  /// Override this method to implement your guard logic.
  /// 
  /// [context] - The guard context with route information.
  /// [ref] - The Riverpod Ref for reading/watching providers.
  /// 
  /// ## Example
  /// ```dart
  /// @override
  /// Future<GuardResult> canActivateWithRef(
  ///   GuardContext context,
  ///   Ref ref,
  /// ) async {
  ///   final user = ref.read(userProvider);
  ///   final requiredRole = context.destination.metadata['role'];
  ///   
  ///   if (user.role != requiredRole) {
  ///     return GuardResult.redirect('/unauthorized');
  ///   }
  ///   return GuardResult.allow();
  /// }
  /// ```
  Future<GuardResult> canActivateWithRef(GuardContext context, dynamic ref);
}

/// A Riverpod guard that checks if user is authenticated.
/// 
/// Requires an auth provider that exposes `isAuthenticated` property.
/// 
/// ## Example
/// ```dart
/// // Your auth provider
/// final authProvider = StateProvider<AuthState>((ref) => AuthState());
/// 
/// // Use the guard
/// final guard = AuthenticationGuard(
///   authProviderReader: (ref) => ref.read(authProvider).isAuthenticated,
///   redirectTo: '/login',
/// );
/// ```
class AuthenticationGuard extends RiverpodRouteGuard {
  /// Function to read auth state from Ref.
  final bool Function(dynamic ref) authProviderReader;
  
  /// Path to redirect to when not authenticated.
  final String redirectTo;
  
  /// Paths that don't require authentication.
  final List<String> publicPaths;

  const AuthenticationGuard({
    required this.authProviderReader,
    this.redirectTo = '/login',
    this.publicPaths = const ['/login', '/register', '/forgot-password'],
  });

  @override
  int get priority => 100;

  @override
  List<String>? get excludes => publicPaths;

  @override
  Future<GuardResult> canActivateWithRef(
    GuardContext context,
    dynamic ref,
  ) async {
    final isAuthenticated = authProviderReader(ref);
    
    if (!isAuthenticated) {
      return GuardResult.redirect(
        redirectTo,
        extra: {'returnTo': context.matchedLocation},
      );
    }
    
    return GuardResult.allow();
  }
}

/// A Riverpod guard that checks user roles/permissions.
/// 
/// ## Example
/// ```dart
/// final guard = RoleGuard(
///   userRoleReader: (ref) => ref.read(userProvider).role,
///   requiredRoles: ['admin', 'manager'],
///   redirectTo: '/unauthorized',
/// );
/// 
/// // Or use route metadata
/// final guard = RoleGuard.fromMetadata(
///   userRoleReader: (ref) => ref.read(userProvider).role,
///   metadataKey: 'requiredRole',
/// );
/// ```
class RoleGuard extends RiverpodRouteGuard {
  /// Function to read user's role from Ref.
  final String? Function(dynamic ref) userRoleReader;
  
  /// Roles allowed to access the route (OR logic).
  final List<String>? requiredRoles;
  
  /// Metadata key for required role (if using route metadata).
  final String? metadataKey;
  
  /// Path to redirect to when unauthorized.
  final String redirectTo;

  const RoleGuard({
    required this.userRoleReader,
    this.requiredRoles,
    this.metadataKey,
    this.redirectTo = '/unauthorized',
  }) : assert(requiredRoles != null || metadataKey != null,
            'Either requiredRoles or metadataKey must be provided');

  /// Create a role guard that reads required role from route metadata.
  const RoleGuard.fromMetadata({
    required this.userRoleReader,
    required this.metadataKey,
    this.redirectTo = '/unauthorized',
  })  : requiredRoles = null;

  @override
  int get priority => 50; // Lower than auth guard

  @override
  Future<GuardResult> canActivateWithRef(
    GuardContext context,
    dynamic ref,
  ) async {
    final userRole = userRoleReader(ref);
    if (userRole == null) {
      return GuardResult.redirect(redirectTo);
    }

    // Get required roles
    final roles = requiredRoles ??
        (metadataKey != null
            ? [context.destination.metadata[metadataKey] as String?]
                .whereType<String>()
                .toList()
            : <String>[]);

    if (roles.isEmpty) {
      return GuardResult.allow(); // No role requirement
    }

    if (roles.contains(userRole)) {
      return GuardResult.allow();
    }

    return GuardResult.redirect(redirectTo);
  }
}
