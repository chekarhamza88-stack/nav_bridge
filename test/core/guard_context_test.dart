import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('GuardContext', () {
    test('creates context with required parameters', () {
      final destination = RouteDefinition(
        path: '/test',
        builder: (_, __) => const SizedBox(),
      );

      final context = GuardContext(destination: destination);

      expect(context.destination, equals(destination));
      expect(context.navigationExtra, isNull);
      expect(context.pathParameters, isEmpty);
      expect(context.queryParameters, isEmpty);
      expect(context.matchedLocation, isEmpty);
      expect(context.extras, isEmpty);
    });

    test('creates context with all parameters', () {
      final destination = RouteDefinition(
        path: '/users/:id',
        builder: (_, __) => const SizedBox(),
      );

      final context = GuardContext(
        destination: destination,
        navigationExtra: {'key': 'value'},
        pathParameters: {'id': '42'},
        queryParameters: {'sort': 'name'},
        matchedLocation: '/users/42?sort=name',
        extras: {'customKey': 'customValue'},
      );

      expect(context.destination, equals(destination));
      expect(context.navigationExtra, {'key': 'value'});
      expect(context.pathParameters, {'id': '42'});
      expect(context.queryParameters, {'sort': 'name'});
      expect(context.matchedLocation, '/users/42?sort=name');
      expect(context.extras, {'customKey': 'customValue'});
    });

    group('get<T>()', () {
      test('returns value when type matches', () {
        final context = GuardContext(
          destination: RouteDefinition(
            path: '/test',
            builder: (_, __) => const SizedBox(),
          ),
          extras: {'stringKey': 'stringValue', 'intKey': 42},
        );

        expect(context.get<String>('stringKey'), equals('stringValue'));
        expect(context.get<int>('intKey'), equals(42));
      });

      test('returns null when key does not exist', () {
        final context = GuardContext(
          destination: RouteDefinition(
            path: '/test',
            builder: (_, __) => const SizedBox(),
          ),
        );

        expect(context.get<String>('nonexistent'), isNull);
      });

      test('returns null when type does not match', () {
        final context = GuardContext(
          destination: RouteDefinition(
            path: '/test',
            builder: (_, __) => const SizedBox(),
          ),
          extras: {'key': 'stringValue'},
        );

        expect(context.get<int>('key'), isNull);
      });
    });

    group('convenience getters', () {
      test('ref getter returns value from extras', () {
        final mockRef = Object(); // Simulate Ref
        final context = GuardContext(
          destination: RouteDefinition(
            path: '/test',
            builder: (_, __) => const SizedBox(),
          ),
          extras: {'ref': mockRef},
        );

        expect(context.ref, equals(mockRef));
      });

      test('goRouterState getter returns value from extras', () {
        final mockState = Object(); // Simulate GoRouterState
        final context = GuardContext(
          destination: RouteDefinition(
            path: '/test',
            builder: (_, __) => const SizedBox(),
          ),
          extras: {'goRouterState': mockState},
        );

        expect(context.goRouterState, equals(mockState));
      });

      test('context getter returns BuildContext from extras', () {
        // Note: Can't easily test BuildContext without widget tree
        final context = GuardContext(
          destination: RouteDefinition(
            path: '/test',
            builder: (_, __) => const SizedBox(),
          ),
        );

        expect(context.context, isNull);
      });
    });

    group('copyWith()', () {
      test('creates copy with modified destination', () {
        final original = GuardContext(
          destination: RouteDefinition(
            path: '/original',
            builder: (_, __) => const SizedBox(),
          ),
          matchedLocation: '/original',
        );

        final newDestination = RouteDefinition(
          path: '/new',
          builder: (_, __) => const SizedBox(),
        );

        final copy = original.copyWith(destination: newDestination);

        expect(copy.destination, equals(newDestination));
        expect(copy.matchedLocation, equals('/original')); // Unchanged
      });

      test('creates copy with all fields preserved when not specified', () {
        final destination = RouteDefinition(
          path: '/test',
          builder: (_, __) => const SizedBox(),
        );

        final original = GuardContext(
          destination: destination,
          navigationExtra: {'key': 'value'},
          pathParameters: {'id': '42'},
          queryParameters: {'sort': 'name'},
          matchedLocation: '/test/42',
          extras: {'extra': 'data'},
        );

        final copy = original.copyWith();

        expect(copy.destination, equals(original.destination));
        expect(copy.navigationExtra, equals(original.navigationExtra));
        expect(copy.pathParameters, equals(original.pathParameters));
        expect(copy.queryParameters, equals(original.queryParameters));
        expect(copy.matchedLocation, equals(original.matchedLocation));
        expect(copy.extras, equals(original.extras));
      });
    });

    test('toString returns readable format', () {
      final context = GuardContext(
        destination: RouteDefinition(
          path: '/test',
          name: 'test',
          builder: (_, __) => const SizedBox(),
        ),
        matchedLocation: '/test',
      );

      expect(
        context.toString(),
        contains('GuardContext'),
      );
      expect(
        context.toString(),
        contains('/test'),
      );
    });
  });
}
