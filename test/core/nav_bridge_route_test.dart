import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('NavBridgeRoute', () {
    test('creates route with required parameters', () {
      final route = NavBridgeRoute(
        path: '/users',
        builder: (context, params) => const SizedBox(),
      );

      expect(route.path, '/users');
      expect(route.name, isNull);
      expect(route.children, isEmpty);
      expect(route.guards, isEmpty);
      expect(route.metadata, isEmpty);
    });

    test('creates route with all parameters', () {
      final route = NavBridgeRoute(
        path: '/users/:userId',
        name: 'userDetails',
        builder: (context, params) => const SizedBox(),
        guards: [TestGuard],
        metadata: {'requiresAuth': true},
        transitionType: TransitionType.fade,
        fullscreenDialog: true,
      );

      expect(route.path, '/users/:userId');
      expect(route.name, 'userDetails');
      expect(route.guards, [TestGuard]);
      expect(route.metadata, {'requiresAuth': true});
      expect(route.transitionType, TransitionType.fade);
      expect(route.fullscreenDialog, isTrue);
    });

    test('creates route with children', () {
      final route = NavBridgeRoute(
        path: '/users',
        builder: (context, params) => const SizedBox(),
        children: [
          NavBridgeRoute(
            path: ':userId',
            name: 'userDetails',
            builder: (context, params) => const SizedBox(),
          ),
          NavBridgeRoute(
            path: 'new',
            name: 'newUser',
            builder: (context, params) => const SizedBox(),
          ),
        ],
      );

      expect(route.children.length, 2);
      expect(route.children[0].name, 'userDetails');
      expect(route.children[1].name, 'newUser');
    });

    group('matches', () {
      test('matches exact path', () {
        final route = NavBridgeRoute(
          path: '/users',
          builder: (context, params) => const SizedBox(),
        );

        expect(route.matches('/users'), isTrue);
        expect(route.matches('/users/123'), isFalse);
        expect(route.matches('/other'), isFalse);
      });

      test('matches path with parameters', () {
        final route = NavBridgeRoute(
          path: '/users/:userId',
          builder: (context, params) => const SizedBox(),
        );

        expect(route.matches('/users/123'), isTrue);
        expect(route.matches('/users/abc'), isTrue);
        expect(route.matches('/users'), isFalse);
        expect(route.matches('/users/123/posts'), isFalse);
      });

      test('matches path with multiple parameters', () {
        final route = NavBridgeRoute(
          path: '/users/:userId/posts/:postId',
          builder: (context, params) => const SizedBox(),
        );

        expect(route.matches('/users/123/posts/456'), isTrue);
        expect(route.matches('/users/123/posts'), isFalse);
      });

      test('ignores query parameters when matching', () {
        final route = NavBridgeRoute(
          path: '/users/:userId',
          builder: (context, params) => const SizedBox(),
        );

        expect(route.matches('/users/123?sort=name'), isTrue);
      });
    });

    group('extractParams', () {
      test('extracts single parameter', () {
        final route = NavBridgeRoute(
          path: '/users/:userId',
          builder: (context, params) => const SizedBox(),
        );

        final params = route.extractParams('/users/123');

        expect(params, {'userId': '123'});
      });

      test('extracts multiple parameters', () {
        final route = NavBridgeRoute(
          path: '/users/:userId/posts/:postId',
          builder: (context, params) => const SizedBox(),
        );

        final params = route.extractParams('/users/123/posts/456');

        expect(params, {'userId': '123', 'postId': '456'});
      });

      test('returns empty map for path without parameters', () {
        final route = NavBridgeRoute(
          path: '/users',
          builder: (context, params) => const SizedBox(),
        );

        final params = route.extractParams('/users');

        expect(params, isEmpty);
      });
    });

    test('copyWith creates modified copy', () {
      final original = NavBridgeRoute(
        path: '/users',
        name: 'users',
        builder: (context, params) => const SizedBox(),
      );

      final modified = original.copyWith(
        name: 'allUsers',
        fullscreenDialog: true,
      );

      expect(modified.path, '/users');
      expect(modified.name, 'allUsers');
      expect(modified.fullscreenDialog, isTrue);
    });

    test('toString returns readable format', () {
      final route = NavBridgeRoute(
        path: '/users',
        name: 'users',
        builder: (context, params) => const SizedBox(),
      );

      expect(route.toString(), contains('NavBridgeRoute'));
      expect(route.toString(), contains('/users'));
    });
  });

  group('NavBridgeRedirectRoute', () {
    test('creates redirect route', () {
      final route = NavBridgeRoute.redirect(
        from: '/old-path',
        to: '/new-path',
      );

      expect(route, isA<NavBridgeRedirectRoute>());
      expect(route.path, '/old-path');
      expect((route as NavBridgeRedirectRoute).redirectTo, '/new-path');
    });

    test('toString returns readable format', () {
      final route = NavBridgeRoute.redirect(
        from: '/old',
        to: '/new',
      );

      expect(route.toString(), contains('NavBridgeRedirectRoute'));
      expect(route.toString(), contains('/old'));
      expect(route.toString(), contains('/new'));
    });
  });

  group('NavBridgeRoute.parent', () {
    test('creates parent route with children', () {
      final route = NavBridgeRoute.parent(
        path: '/settings',
        children: [
          NavBridgeRoute(
            path: 'profile',
            builder: (_, __) => const SizedBox(),
          ),
        ],
      );

      expect(route.path, '/settings');
      expect(route.children.length, 1);
    });
  });

  group('TransitionType', () {
    test('has all expected values', () {
      expect(TransitionType.values, contains(TransitionType.material));
      expect(TransitionType.values, contains(TransitionType.cupertino));
      expect(TransitionType.values, contains(TransitionType.fade));
      expect(TransitionType.values, contains(TransitionType.slide));
      expect(TransitionType.values, contains(TransitionType.none));
    });
  });
}

class TestGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}
