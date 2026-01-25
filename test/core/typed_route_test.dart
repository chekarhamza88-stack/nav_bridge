import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

class UserRoute extends TypedRoute {
  final String userId;

  const UserRoute({required this.userId});

  @override
  String get name => 'user';

  @override
  Map<String, String> get pathParameters => {'userId': userId};
}

class SearchRoute extends TypedRoute {
  final String query;
  final String? filter;

  const SearchRoute({required this.query, this.filter});

  @override
  String get name => 'search';

  @override
  Map<String, String> get queryParameters => {
        'q': query,
        if (filter != null) 'filter': filter!,
      };
}

class DetailRoute extends TypedRoute {
  final String itemId;
  final Object? data;

  const DetailRoute({required this.itemId, this.data});

  @override
  String get name => 'detail';

  @override
  Map<String, String> get pathParameters => {'itemId': itemId};

  @override
  Object? get extra => data;
}

void main() {
  group('TypedRoute', () {
    test('creates route with path parameters', () {
      const route = UserRoute(userId: '123');

      expect(route.name, 'user');
      expect(route.pathParameters, {'userId': '123'});
      expect(route.queryParameters, isEmpty);
      expect(route.extra, isNull);
    });

    test('creates route with query parameters', () {
      const route = SearchRoute(query: 'flutter', filter: 'recent');

      expect(route.name, 'search');
      expect(route.pathParameters, isEmpty);
      expect(route.queryParameters, {'q': 'flutter', 'filter': 'recent'});
    });

    test('creates route with optional query parameters', () {
      const route = SearchRoute(query: 'dart');

      expect(route.queryParameters, {'q': 'dart'});
    });

    test('creates route with extra data', () {
      const data = {'key': 'value'};
      const route = DetailRoute(itemId: '456', data: data);

      expect(route.pathParameters, {'itemId': '456'});
      expect(route.extra, data);
    });

    test('equality works correctly', () {
      const route1 = UserRoute(userId: '123');
      const route2 = UserRoute(userId: '123');
      const route3 = UserRoute(userId: '456');

      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });

    test('hashCode is consistent', () {
      const route1 = UserRoute(userId: '123');
      const route2 = UserRoute(userId: '123');

      expect(route1.hashCode, equals(route2.hashCode));
    });

    test('toString returns readable format', () {
      const route = UserRoute(userId: '123');

      expect(
        route.toString(),
        contains('TypedRoute'),
      );
      expect(route.toString(), contains('user'));
    });
  });
}
