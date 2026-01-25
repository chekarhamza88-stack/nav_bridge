import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('InMemoryAdapter named navigation', () {
    late InMemoryAdapter adapter;
    late List<NavBridgeRoute> routes;

    setUp(() {
      routes = [
        NavBridgeRoute(
          path: '/',
          name: 'home',
          builder: (_, __) => const SizedBox(),
        ),
        NavBridgeRoute(
          path: '/users/:userId',
          name: 'userDetails',
          builder: (_, __) => const SizedBox(),
        ),
        NavBridgeRoute(
          path: '/search',
          name: 'search',
          builder: (_, __) => const SizedBox(),
        ),
        NavBridgeRoute(
          path: '/settings',
          name: 'settings',
          builder: (_, __) => const SizedBox(),
          children: [
            NavBridgeRoute(
              path: 'profile',
              name: 'settingsProfile',
              builder: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ];

      adapter = InMemoryAdapter(routes: routes);
    });

    group('goNamed', () {
      test('navigates to named route', () async {
        await adapter.goNamed('home');

        expect(adapter.currentLocation, '/');
      });

      test('navigates to named route with path parameters', () async {
        await adapter.goNamed('userDetails', pathParameters: {'userId': '123'});

        expect(adapter.currentLocation, '/users/123');
      });

      test('navigates to named route with query parameters', () async {
        await adapter.goNamed(
          'search',
          queryParameters: {'q': 'flutter', 'sort': 'recent'},
        );

        expect(adapter.currentLocation, contains('/search'));
        expect(adapter.currentLocation, contains('q=flutter'));
        expect(adapter.currentLocation, contains('sort=recent'));
      });

      test('throws exception for unknown route name', () async {
        expect(
          () => adapter.goNamed('unknown'),
          throwsException,
        );
      });

      test('sets current route name', () async {
        await adapter.goNamed('home');

        expect(adapter.currentRouteName, 'home');
      });

      test('clears navigation stack', () async {
        await adapter.push('/other');
        await adapter.goNamed('home');

        expect(adapter.stack.length, 1);
      });
    });

    group('pushNamed', () {
      test('pushes named route onto stack', () async {
        await adapter
            .pushNamed('userDetails', pathParameters: {'userId': '123'});

        expect(adapter.currentLocation, '/users/123');
        expect(adapter.stack.length, 2);
      });

      test('preserves navigation stack', () async {
        await adapter.pushNamed('home');
        await adapter
            .pushNamed('userDetails', pathParameters: {'userId': '123'});

        expect(adapter.stack.length, 3);
        expect(adapter.canPop(), isTrue);
      });
    });

    group('replaceNamed', () {
      test('replaces current location with named route', () async {
        await adapter.push('/other');
        await adapter.replaceNamed('home');

        expect(adapter.currentLocation, '/');
        expect(adapter.stack.length, 2);
      });
    });

    group('typed route navigation', () {
      test('goToRoute navigates using typed route', () async {
        await adapter.goToRoute(_UserRoute(userId: '123'));

        expect(adapter.currentLocation, '/users/123');
      });

      test('pushRoute pushes typed route', () async {
        await adapter.pushRoute(_UserRoute(userId: '456'));

        expect(adapter.currentLocation, '/users/456');
        expect(adapter.stack.length, 2);
      });

      test('replaceRoute replaces with typed route', () async {
        await adapter.push('/other');
        await adapter.replaceRoute(_UserRoute(userId: '789'));

        expect(adapter.currentLocation, '/users/789');
        expect(adapter.stack.length, 2);
      });

      test('typed route with query parameters', () async {
        await adapter.goToRoute(_SearchRoute(query: 'dart'));

        expect(adapter.currentLocation, contains('search'));
        expect(adapter.currentLocation, contains('q=dart'));
      });
    });

    group('route registration', () {
      test('registerRoutes adds new routes', () async {
        final newAdapter = InMemoryAdapter();

        newAdapter.registerRoutes([
          NavBridgeRoute(
            path: '/new',
            name: 'newRoute',
            builder: (_, __) => const SizedBox(),
          ),
        ]);

        await newAdapter.goNamed('newRoute');
        expect(newAdapter.currentLocation, '/new');
      });

      test('clearRoutes removes all routes', () async {
        adapter.clearRoutes();

        expect(
          () => adapter.goNamed('home'),
          throwsException,
        );
      });
    });

    group('nested route navigation', () {
      test('finds nested routes by name', () async {
        await adapter.goNamed('settingsProfile');

        // Note: nested routes have relative paths in the route definition
        // The path 'profile' is relative to the parent '/settings'
        expect(adapter.currentLocation, 'profile');
      });
    });

    group('path building', () {
      test('encodes query parameter values', () async {
        await adapter.goNamed(
          'search',
          queryParameters: {'q': 'hello world'},
        );

        expect(adapter.currentLocation, contains('hello%20world'));
      });

      test('handles multiple path parameters', () async {
        final routesWithMultipleParams = [
          NavBridgeRoute(
            path: '/users/:userId/posts/:postId',
            name: 'post',
            builder: (_, __) => const SizedBox(),
          ),
        ];

        final multiAdapter = InMemoryAdapter(routes: routesWithMultipleParams);

        await multiAdapter.goNamed(
          'post',
          pathParameters: {'userId': '123', 'postId': '456'},
        );

        expect(multiAdapter.currentLocation, '/users/123/posts/456');
      });
    });
  });
}

class _UserRoute extends TypedRoute {
  final String userId;

  const _UserRoute({required this.userId});

  @override
  String get name => 'userDetails';

  @override
  Map<String, String> get pathParameters => {'userId': userId};
}

class _SearchRoute extends TypedRoute {
  final String query;

  const _SearchRoute({required this.query});

  @override
  String get name => 'search';

  @override
  Map<String, String> get queryParameters => {'q': query};
}
