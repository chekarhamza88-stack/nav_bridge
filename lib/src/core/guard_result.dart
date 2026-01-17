/// Result of a route guard check.
///
/// This is a sealed class with three possible outcomes:
/// - [GuardAllow]: Navigation proceeds
/// - [GuardRedirect]: Navigation redirects to a different path
/// - [GuardReject]: Navigation is blocked
///
/// ## Example
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   Future<GuardResult> canActivate(GuardContext context) async {
///     if (isAuthenticated) {
///       return GuardResult.allow();
///     }
///     return GuardResult.redirect('/login');
///   }
/// }
/// ```
sealed class GuardResult {
  const GuardResult();

  /// Allow navigation to proceed.
  static GuardAllow allow() => const GuardAllow();

  /// Redirect to a different path.
  ///
  /// [path] - The path to redirect to (e.g., '/login').
  /// [extra] - Optional extra data to pass with the redirect.
  /// [replace] - If true, replaces current route instead of pushing.
  static GuardRedirect redirect(
    String path, {
    Map<String, dynamic>? extra,
    bool replace = true,
  }) =>
      GuardRedirect(path: path, extra: extra, replace: replace);

  /// Reject navigation entirely.
  ///
  /// [reason] - Optional reason for rejection (useful for logging).
  /// [showError] - If true, display error to user.
  static GuardReject reject({String? reason, bool showError = false}) =>
      GuardReject(reason: reason, showError: showError);
}

/// Navigation is allowed to proceed.
class GuardAllow extends GuardResult {
  const GuardAllow();

  @override
  bool operator ==(Object other) => other is GuardAllow;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'GuardAllow()';
}

/// Navigation should redirect to a different path.
class GuardRedirect extends GuardResult {
  /// The path to redirect to.
  final String path;

  /// Optional extra data to pass with the redirect.
  final Map<String, dynamic>? extra;

  /// If true, replaces current route instead of pushing.
  final bool replace;

  const GuardRedirect({
    required this.path,
    this.extra,
    this.replace = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardRedirect && path == other.path && replace == other.replace;

  @override
  int get hashCode => Object.hash(path, replace);

  @override
  String toString() => 'GuardRedirect(path: $path, replace: $replace)';
}

/// Navigation is rejected.
class GuardReject extends GuardResult {
  /// Optional reason for rejection.
  final String? reason;

  /// If true, display error to user.
  final bool showError;

  const GuardReject({this.reason, this.showError = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardReject &&
          reason == other.reason &&
          showError == other.showError;

  @override
  int get hashCode => Object.hash(reason, showError);

  @override
  String toString() => 'GuardReject(reason: $reason)';
}

/// Extension methods for pattern matching on GuardResult.
extension GuardResultExtension on GuardResult {
  /// Pattern match on the result type.
  ///
  /// ## Example
  /// ```dart
  /// final result = await guard.canActivate(context);
  /// result.when(
  ///   allow: () => print('Allowed'),
  ///   redirect: (path, extra, replace) => print('Redirect to $path'),
  ///   reject: (reason, showError) => print('Rejected: $reason'),
  /// );
  /// ```
  T when<T>({
    required T Function() allow,
    required T Function(String path, Map<String, dynamic>? extra, bool replace)
        redirect,
    required T Function(String? reason, bool showError) reject,
  }) {
    return switch (this) {
      GuardAllow() => allow(),
      GuardRedirect(:final path, :final extra, :final replace) =>
        redirect(path, extra, replace),
      GuardReject(:final reason, :final showError) => reject(reason, showError),
    };
  }

  /// Returns true if this result allows navigation.
  bool get isAllowed => this is GuardAllow;

  /// Returns true if this result redirects navigation.
  bool get isRedirect => this is GuardRedirect;

  /// Returns true if this result rejects navigation.
  bool get isRejected => this is GuardReject;
}
