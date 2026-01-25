/// Parameters extracted from navigation.
///
/// Provides type-safe access to path parameters, query parameters,
/// and extra data passed during navigation.
///
/// ## Example
/// ```dart
/// NavBridgeRoute(
///   path: '/users/:userId',
///   name: 'userDetails',
///   builder: (context, params) {
///     final userId = params.get('userId');
///     final sortOrder = params.query('sort');
///     final userData = params.getExtra<UserData>();
///     return UserScreen(userId: userId, sort: sortOrder, data: userData);
///   },
/// )
/// ```
class RouteParams {
  /// Path parameters extracted from the route (e.g., `:userId` from `/users/:userId`).
  final Map<String, String> pathParams;

  /// Query parameters from the URL (e.g., `?sort=name&order=asc`).
  final Map<String, String> queryParams;

  /// Extra data passed during navigation.
  final Object? extra;

  /// Creates a new RouteParams instance.
  const RouteParams({
    this.pathParams = const {},
    this.queryParams = const {},
    this.extra,
  });

  /// Gets a required path parameter by key.
  ///
  /// Returns an empty string if the parameter is not found.
  /// Use [getOptional] if the parameter might not exist.
  String get(String key) => pathParams[key] ?? '';

  /// Gets an optional path parameter by key.
  ///
  /// Returns null if the parameter is not found.
  String? getOptional(String key) => pathParams[key];

  /// Gets a query parameter by key.
  ///
  /// Returns null if the parameter is not found.
  String? query(String key) => queryParams[key];

  /// Gets a required query parameter by key.
  ///
  /// Returns an empty string if the parameter is not found.
  String queryRequired(String key) => queryParams[key] ?? '';

  /// Gets the extra data cast to the specified type.
  ///
  /// Returns null if extra is null or not of the expected type.
  ///
  /// ## Example
  /// ```dart
  /// final userData = params.getExtra<UserData>();
  /// if (userData != null) {
  ///   // Use userData
  /// }
  /// ```
  T? getExtra<T>() => extra is T ? extra as T : null;

  /// Gets a path parameter parsed as an integer.
  ///
  /// Returns null if the parameter doesn't exist or can't be parsed.
  int? getInt(String key) {
    final value = pathParams[key];
    return value != null ? int.tryParse(value) : null;
  }

  /// Gets a query parameter parsed as an integer.
  ///
  /// Returns null if the parameter doesn't exist or can't be parsed.
  int? queryInt(String key) {
    final value = queryParams[key];
    return value != null ? int.tryParse(value) : null;
  }

  /// Gets a query parameter parsed as a boolean.
  ///
  /// Returns true for 'true', '1', 'yes'; false otherwise.
  bool queryBool(String key, {bool defaultValue = false}) {
    final value = queryParams[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Gets all query parameters with a given prefix.
  ///
  /// Useful for filter parameters like `?filter.name=John&filter.age=30`.
  Map<String, String> queryWithPrefix(String prefix) {
    final result = <String, String>{};
    final prefixWithDot = '$prefix.';
    for (final entry in queryParams.entries) {
      if (entry.key.startsWith(prefixWithDot)) {
        result[entry.key.substring(prefixWithDot.length)] = entry.value;
      }
    }
    return result;
  }

  /// Creates a copy of this RouteParams with the given fields replaced.
  RouteParams copyWith({
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    return RouteParams(
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      extra: extra ?? this.extra,
    );
  }

  @override
  String toString() =>
      'RouteParams(pathParams: $pathParams, queryParams: $queryParams, extra: $extra)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RouteParams) return false;
    return _mapsEqual(pathParams, other.pathParams) &&
        _mapsEqual(queryParams, other.queryParams) &&
        extra == other.extra;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(pathParams.entries),
        Object.hashAll(queryParams.entries),
        extra,
      );

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
