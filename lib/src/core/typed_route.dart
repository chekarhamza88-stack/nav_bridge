/// Base class for type-safe route definitions.
///
/// Extend this class to create type-safe routes that can be used
/// with [RouterAdapter.goToRoute], [RouterAdapter.pushRoute], etc.
///
/// ## Example
/// ```dart
/// class UserDetailsRoute extends TypedRoute {
///   final String userId;
///
///   UserDetailsRoute({required this.userId});
///
///   @override
///   String get name => 'userDetails';
///
///   @override
///   Map<String, String> get pathParameters => {'userId': userId};
/// }
///
/// // Usage
/// nav.goToRoute(UserDetailsRoute(userId: '123'));
/// ```
abstract class TypedRoute {
  /// Creates a new typed route.
  const TypedRoute();

  /// The route name for named navigation.
  ///
  /// This must match the name defined in your route configuration.
  String get name;

  /// Path parameters to substitute in the route path.
  ///
  /// For example, if the route path is `/users/:userId`,
  /// this would return `{'userId': '123'}`.
  Map<String, String> get pathParameters => const {};

  /// Query parameters to append to the URL.
  ///
  /// For example, `{'sort': 'name', 'order': 'asc'}` would
  /// result in `?sort=name&order=asc`.
  Map<String, String> get queryParameters => const {};

  /// Extra data to pass to the destination.
  ///
  /// This data is not encoded in the URL and is only available
  /// during the same navigation session.
  Object? get extra => null;

  @override
  String toString() {
    return 'TypedRoute($name, pathParams: $pathParameters, '
        'queryParams: $queryParameters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TypedRoute) return false;
    return name == other.name &&
        _mapsEqual(pathParameters, other.pathParameters) &&
        _mapsEqual(queryParameters, other.queryParameters);
  }

  @override
  int get hashCode {
    // Sort entries to ensure consistent hash regardless of map iteration order
    final pathEntries = pathParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryEntries = queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Object.hash(
      name,
      Object.hashAll(pathEntries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAll(queryEntries.map((e) => Object.hash(e.key, e.value))),
    );
  }

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
