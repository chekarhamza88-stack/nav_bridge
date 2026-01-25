import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('GoRouterAdapter', () {
    group('_runGuards', () {
      testWidgets('does not throw assertion error when evaluating guards',
          (tester) async {
        // This test verifies the fix for the RouteDefinition assertion error
        // in _runGuards() where RouteDefinition(path: location) was causing
        // assertion failures because it lacked a builder/pageBuilder/redirectTo/children.
        //
        // The fix uses RouteDefinition.stub(location) which provides a no-op builder.

        final adapter = GoRouterAdapter.withGuards(
          routes: [
            GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('Home'))),
            GoRoute(
                path: '/protected',
                builder: (_, __) => const Scaffold(body: Text('Protected'))),
          ],
          guards: [
            _TestGuard(),
          ],
          contextBuilder: (state) => {},
        );

        await tester.pumpWidget(MaterialApp.router(
          routerConfig: adapter.router,
        ));

        // Navigate to protected route - should not throw assertion error
        adapter.go('/protected');
        await tester.pumpAndSettle();

        // Verify navigation succeeded
        expect(find.text('Protected'), findsOneWidget);
      });

      testWidgets('runs guards in priority order', (tester) async {
        final callOrder = <String>[];

        final adapter = GoRouterAdapter.withGuards(
          routes: [
            GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('Home'))),
            GoRoute(
                path: '/test',
                builder: (_, __) => const Scaffold(body: Text('Test'))),
          ],
          guards: [
            _OrderTrackingGuard('low', 0, callOrder),
            _OrderTrackingGuard('high', 100, callOrder),
            _OrderTrackingGuard('medium', 50, callOrder),
          ],
          contextBuilder: (state) => {},
        );

        await tester.pumpWidget(MaterialApp.router(
          routerConfig: adapter.router,
        ));
        await tester.pumpAndSettle();

        // Clear call order from initial route navigation
        callOrder.clear();

        adapter.go('/test');
        await tester.pumpAndSettle();

        // Guards should be sorted by priority (highest first)
        expect(callOrder, equals(['high', 'medium', 'low']));
      });

      testWidgets('guard receives correct path in context', (tester) async {
        String? receivedPath;

        final adapter = GoRouterAdapter.withGuards(
          routes: [
            GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('Home'))),
            GoRoute(
                path: '/users/:id',
                builder: (_, __) => const Scaffold(body: Text('User'))),
          ],
          guards: [
            _PathCapturingGuard((path) => receivedPath = path),
          ],
          contextBuilder: (state) => {},
        );

        await tester.pumpWidget(MaterialApp.router(
          routerConfig: adapter.router,
        ));
        await tester.pumpAndSettle();

        // Reset after initial route
        receivedPath = null;

        adapter.go('/users/123');
        await tester.pumpAndSettle();

        expect(receivedPath, equals('/users/123'));
      });
    });

    group('fromRoutes', () {
      testWidgets(
          'converts NavBridgeRoutes and runs guards without assertion error',
          (tester) async {
        final routes = [
          NavBridgeRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          NavBridgeRoute(
            path: '/protected',
            name: 'protected',
            builder: (_, __) => const Scaffold(body: Text('Protected')),
          ),
        ];

        final adapter = GoRouterAdapter.fromRoutes(
          routes: routes,
          guards: [_TestGuard()],
          contextBuilder: (state) => {},
        );

        await tester.pumpWidget(MaterialApp.router(
          routerConfig: adapter.router,
        ));

        // Navigate to protected route - should not throw
        adapter.go('/protected');
        await tester.pumpAndSettle();

        // Verify navigation succeeded
        expect(find.text('Protected'), findsOneWidget);
      });
    });
  });
}

// Test helpers

class _TestGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _OrderTrackingGuard extends RouteGuard {
  final String name;
  @override
  final int priority;
  final List<String> callOrder;

  _OrderTrackingGuard(this.name, this.priority, this.callOrder);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    callOrder.add(name);
    return GuardResult.allow();
  }
}

class _PathCapturingGuard extends RouteGuard {
  final void Function(String) onPath;

  _PathCapturingGuard(this.onPath);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    onPath(context.matchedLocation);
    return GuardResult.allow();
  }
}
