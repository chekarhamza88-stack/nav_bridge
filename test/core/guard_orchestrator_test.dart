import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('GuardOrchestrator', () {
    test('creates with empty guards', () {
      final orchestrator = GuardOrchestrator();

      expect(orchestrator.globalGuards, isEmpty);
      expect(orchestrator.routeGuards, isEmpty);
    });

    test('creates with initial global guards', () {
      final guard = _AllowGuard();
      final orchestrator = GuardOrchestrator(globalGuards: [guard]);

      expect(orchestrator.globalGuards.length, 1);
    });

    test('adds global guard', () {
      final orchestrator = GuardOrchestrator();
      final guard = _AllowGuard();

      orchestrator.addGlobalGuard(guard);

      expect(orchestrator.globalGuards.length, 1);
    });

    test('removes global guard', () {
      final guard = _AllowGuard();
      final orchestrator = GuardOrchestrator(globalGuards: [guard]);

      orchestrator.removeGlobalGuard(guard);

      expect(orchestrator.globalGuards, isEmpty);
    });

    test('adds route-specific guard', () {
      final orchestrator = GuardOrchestrator();
      final guard = _AllowGuard();

      orchestrator.addRouteGuard('admin', guard);

      expect(orchestrator.routeGuards['admin']?.length, 1);
    });

    test('removes route-specific guard', () {
      final orchestrator = GuardOrchestrator();
      final guard = _AllowGuard();
      orchestrator.addRouteGuard('admin', guard);

      orchestrator.removeRouteGuard('admin', guard);

      expect(orchestrator.routeGuards['admin'], isEmpty);
    });

    test('clears route-specific guards', () {
      final orchestrator = GuardOrchestrator();
      orchestrator.addRouteGuard('admin', _AllowGuard());
      orchestrator.addRouteGuard('admin', _AllowGuard());

      orchestrator.clearRouteGuards('admin');

      expect(orchestrator.routeGuards['admin'], isNull);
    });

    group('evaluate', () {
      test('returns allow when no guards', () async {
        final orchestrator = GuardOrchestrator();

        final result = await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(result, isA<GuardAllow>());
      });

      test('returns allow when guard allows', () async {
        final orchestrator = GuardOrchestrator(
          globalGuards: [_AllowGuard()],
        );

        final result = await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(result, isA<GuardAllow>());
      });

      test('returns redirect when guard redirects', () async {
        final orchestrator = GuardOrchestrator(
          globalGuards: [_RedirectGuard('/login')],
        );

        final result = await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(result, isA<GuardRedirect>());
        expect((result as GuardRedirect).path, '/login');
      });

      test('returns reject when guard rejects', () async {
        final orchestrator = GuardOrchestrator(
          globalGuards: [_RejectGuard('Not allowed')],
        );

        final result = await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(result, isA<GuardReject>());
        expect((result as GuardReject).reason, 'Not allowed');
      });

      test('evaluates guards in priority order', () async {
        final executionOrder = <String>[];

        final orchestrator = GuardOrchestrator(
          globalGuards: [
            _OrderedGuard('low', priority: 10, executionOrder: executionOrder),
            _OrderedGuard('high',
                priority: 100, executionOrder: executionOrder),
            _OrderedGuard('medium',
                priority: 50, executionOrder: executionOrder),
          ],
        );

        await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(executionOrder, ['high', 'medium', 'low']);
      });

      test('stops at first non-allow result', () async {
        final executionOrder = <String>[];

        final orchestrator = GuardOrchestrator(
          globalGuards: [
            _OrderedGuard('first',
                priority: 100, executionOrder: executionOrder),
            _OrderedRedirectGuard('redirect',
                priority: 50, executionOrder: executionOrder),
            _OrderedGuard('last', priority: 10, executionOrder: executionOrder),
          ],
        );

        await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(executionOrder, ['first', 'redirect']);
      });

      test('includes route-specific guards', () async {
        final executionOrder = <String>[];

        final orchestrator = GuardOrchestrator(
          globalGuards: [
            _OrderedGuard('global',
                priority: 100, executionOrder: executionOrder)
          ],
        );
        orchestrator.addRouteGuard(
          'admin',
          _OrderedGuard('route', priority: 50, executionOrder: executionOrder),
        );

        await orchestrator.evaluate(
          destination: '/admin',
          routeName: 'admin',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(executionOrder, ['global', 'route']);
      });

      test('skips guards based on shouldActivateFor', () async {
        final executionOrder = <String>[];

        final orchestrator = GuardOrchestrator(
          globalGuards: [
            _ExcludesGuard('skipped',
                priority: 100, executionOrder: executionOrder),
            _OrderedGuard('executed',
                priority: 50, executionOrder: executionOrder),
          ],
        );

        await orchestrator.evaluate(
          destination: '/public',
          routeName: 'public',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(executionOrder, ['executed']);
      });

      test('handles guard exceptions gracefully', () async {
        final orchestrator = GuardOrchestrator(
          globalGuards: [_ThrowingGuard()],
        );

        final result = await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {},
        );

        expect(result, isA<GuardReject>());
        expect((result as GuardReject).reason, contains('Guard error'));
      });

      test('passes context to guards', () async {
        String? receivedValue;

        final orchestrator = GuardOrchestrator(
          globalGuards: [
            _ContextCheckGuard((ctx) {
              receivedValue = ctx.extras['testKey'] as String?;
            })
          ],
        );

        await orchestrator.evaluate(
          destination: '/test',
          routeName: 'test',
          pathParams: {},
          queryParams: {},
          extra: null,
          context: {'testKey': 'testValue'},
        );

        expect(receivedValue, 'testValue');
      });
    });

    group('createRedirectHandler', () {
      test('creates handler for GoRouter', () {
        final orchestrator = GuardOrchestrator();

        final handler = orchestrator.createRedirectHandler(
          contextBuilder: (state) => {},
        );

        expect(handler, isNotNull);
      });
    });
  });
}

class _AllowGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _RedirectGuard extends RouteGuard {
  final String redirectTo;

  _RedirectGuard(this.redirectTo);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.redirect(redirectTo);
  }
}

class _RejectGuard extends RouteGuard {
  final String reason;

  _RejectGuard(this.reason);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.reject(reason: reason);
  }
}

class _OrderedGuard extends RouteGuard {
  final String name;
  @override
  final int priority;
  final List<String> executionOrder;

  _OrderedGuard(this.name,
      {required this.priority, required this.executionOrder});

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    executionOrder.add(name);
    return GuardResult.allow();
  }
}

class _OrderedRedirectGuard extends RouteGuard {
  final String name;
  @override
  final int priority;
  final List<String> executionOrder;

  _OrderedRedirectGuard(this.name,
      {required this.priority, required this.executionOrder});

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    executionOrder.add(name);
    return GuardResult.redirect('/redirect');
  }
}

class _ExcludesGuard extends RouteGuard {
  final String name;
  @override
  final int priority;
  final List<String> executionOrder;

  _ExcludesGuard(this.name,
      {required this.priority, required this.executionOrder});

  @override
  List<String>? get excludes => ['/public'];

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    executionOrder.add(name);
    return GuardResult.allow();
  }
}

class _ThrowingGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    throw Exception('Test error');
  }
}

class _ContextCheckGuard extends RouteGuard {
  final void Function(GuardContext) onActivate;

  _ContextCheckGuard(this.onActivate);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    onActivate(context);
    return GuardResult.allow();
  }
}
