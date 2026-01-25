import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('RouteParams', () {
    test('creates with default values', () {
      const params = RouteParams();

      expect(params.pathParams, isEmpty);
      expect(params.queryParams, isEmpty);
      expect(params.extra, isNull);
    });

    test('creates with path parameters', () {
      const params = RouteParams(
        pathParams: {'userId': '123', 'postId': '456'},
      );

      expect(params.get('userId'), '123');
      expect(params.get('postId'), '456');
      expect(params.get('missing'), '');
    });

    test('get returns empty string for missing keys', () {
      const params = RouteParams();

      expect(params.get('nonexistent'), '');
    });

    test('getOptional returns null for missing keys', () {
      const params = RouteParams(pathParams: {'id': '123'});

      expect(params.getOptional('id'), '123');
      expect(params.getOptional('missing'), isNull);
    });

    test('query returns query parameters', () {
      const params = RouteParams(
        queryParams: {'sort': 'name', 'order': 'asc'},
      );

      expect(params.query('sort'), 'name');
      expect(params.query('order'), 'asc');
      expect(params.query('missing'), isNull);
    });

    test('queryRequired returns empty string for missing keys', () {
      const params = RouteParams(queryParams: {'sort': 'name'});

      expect(params.queryRequired('sort'), 'name');
      expect(params.queryRequired('missing'), '');
    });

    test('getExtra casts to correct type', () {
      const data = {'key': 'value'};
      const params = RouteParams(extra: data);

      expect(params.getExtra<Map<String, String>>(), data);
      expect(params.getExtra<String>(), isNull);
    });

    test('getInt parses integer path parameters', () {
      const params = RouteParams(
        pathParams: {'id': '123', 'invalid': 'abc'},
      );

      expect(params.getInt('id'), 123);
      expect(params.getInt('invalid'), isNull);
      expect(params.getInt('missing'), isNull);
    });

    test('queryInt parses integer query parameters', () {
      const params = RouteParams(
        queryParams: {'page': '5', 'limit': 'abc'},
      );

      expect(params.queryInt('page'), 5);
      expect(params.queryInt('limit'), isNull);
      expect(params.queryInt('missing'), isNull);
    });

    test('queryBool parses boolean query parameters', () {
      const params = RouteParams(
        queryParams: {
          'enabled': 'true',
          'active': '1',
          'confirmed': 'yes',
          'disabled': 'false',
          'invalid': 'abc',
        },
      );

      expect(params.queryBool('enabled'), isTrue);
      expect(params.queryBool('active'), isTrue);
      expect(params.queryBool('confirmed'), isTrue);
      expect(params.queryBool('disabled'), isFalse);
      expect(params.queryBool('invalid'), isFalse);
      expect(params.queryBool('missing'), isFalse);
      expect(params.queryBool('missing', defaultValue: true), isTrue);
    });

    test('queryWithPrefix extracts prefixed parameters', () {
      const params = RouteParams(
        queryParams: {
          'filter.name': 'John',
          'filter.age': '30',
          'sort': 'asc',
        },
      );

      final filterParams = params.queryWithPrefix('filter');

      expect(filterParams, {'name': 'John', 'age': '30'});
    });

    test('copyWith creates modified copy', () {
      const original = RouteParams(
        pathParams: {'id': '123'},
        queryParams: {'sort': 'name'},
        extra: 'data',
      );

      final modified = original.copyWith(
        pathParams: {'id': '456'},
      );

      expect(modified.get('id'), '456');
      expect(modified.query('sort'), 'name');
      expect(modified.extra, 'data');
    });

    test('equality works correctly', () {
      const params1 = RouteParams(
        pathParams: {'id': '123'},
        queryParams: {'sort': 'name'},
      );
      const params2 = RouteParams(
        pathParams: {'id': '123'},
        queryParams: {'sort': 'name'},
      );
      const params3 = RouteParams(
        pathParams: {'id': '456'},
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('toString returns readable format', () {
      const params = RouteParams(
        pathParams: {'id': '123'},
      );

      expect(params.toString(), contains('RouteParams'));
      expect(params.toString(), contains('id'));
    });
  });
}
