import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('RouteGuard', () {
    group('shouldActivateFor()', () {
      test('returns true for all paths when appliesTo is null', () {
        final guard = _SimpleGuard();

        expect(guard.shouldActivateFor('/'), isTrue);
        expect(guard.shouldActivateFor('/users'), isTrue);
        expect(guard.shouldActivateFor('/admin/dashboard'), isTrue);
      });

      test('returns true only for matching paths when appliesTo is set', () {
        final guard = _AppliesGuard(['/admin', '/admin/*']);

        expect(guard.shouldActivateFor('/admin'), isTrue);
        expect(guard.shouldActivateFor('/admin/users'), isTrue);
        expect(guard.shouldActivateFor('/users'), isFalse);
        expect(guard.shouldActivateFor('/'), isFalse);
      });

      test('returns false for excluded paths', () {
        final guard = _ExcludesGuard(['/public', '/login']);

        expect(guard.shouldActivateFor('/public'), isFalse);
        expect(guard.shouldActivateFor('/login'), isFalse);
        expect(guard.shouldActivateFor('/protected'), isTrue);
      });

      test('excludes take precedence over appliesTo', () {
        final guard = _AppliesAndExcludesGuard(
          appliesTo: ['/admin/*'],
          excludes: ['/admin/public'],
        );

        expect(guard.shouldActivateFor('/admin/users'), isTrue);
        expect(guard.shouldActivateFor('/admin/public'), isFalse);
      });

      test('matches parameter patterns', () {
        final guard = _AppliesGuard(['/users/:id', '/posts/:postId/comments']);

        expect(guard.shouldActivateFor('/users/42'), isTrue);
        expect(guard.shouldActivateFor('/users/abc'), isTrue);
        expect(guard.shouldActivateFor('/posts/123/comments'), isTrue);
        expect(guard.shouldActivateFor('/users'), isFalse);
      });

      test('matches wildcard patterns', () {
        final guard = _AppliesGuard(['/admin/*']);

        expect(guard.shouldActivateFor('/admin/users'), isTrue);
        expect(guard.shouldActivateFor('/admin/settings'), isTrue);
        expect(guard.shouldActivateFor('/admin/users/42'), isTrue);
        expect(guard.shouldActivateFor('/admin'), isFalse);
        expect(guard.shouldActivateFor('/user'), isFalse);
      });
    });

    group('priority', () {
      test('default priority is 0', () {
        final guard = _SimpleGuard();

        expect(guard.priority, equals(0));
      });

      test('can override priority', () {
        final guard = _PriorityGuard(100);

        expect(guard.priority, equals(100));
      });
    });

    group('canDeactivate()', () {
      test('returns true by default', () async {
        final guard = _SimpleGuard();
        final context = _createContext('/test');

        final result = await guard.canDeactivate(context);

        expect(result, isTrue);
      });
    });
  });

  group('CompositeGuard', () {
    test('allows when all guards allow', () async {
      final guard = CompositeGuard([
        _AllowGuard(),
        _AllowGuard(),
      ]);
      final context = _createContext('/test');

      final result = await guard.canActivate(context);

      expect(result, isA<GuardAllow>());
    });

    test('redirects when any guard redirects', () async {
      final guard = CompositeGuard([
        _AllowGuard(),
        _RedirectGuard('/login'),
        _AllowGuard(),
      ]);
      final context = _createContext('/test');

      final result = await guard.canActivate(context);

      expect(result, isA<GuardRedirect>());
      expect((result as GuardRedirect).path, equals('/login'));
    });

    test('stops at first non-allow result', () async {
      var secondGuardCalled = false;
      
      final guard = CompositeGuard([
        _RedirectGuard('/first'),
        _CallbackGuard(() {
          secondGuardCalled = true;
          return GuardResult.allow();
        }),
      ]);
      final context = _createContext('/test');

      await guard.canActivate(context);

      expect(secondGuardCalled, isFalse);
    });

    test('uses highest priority from contained guards', () {
      final guard = CompositeGuard([
        _PriorityGuard(10),
        _PriorityGuard(100),
        _PriorityGuard(50),
      ]);

      expect(guard.priority, equals(100));
    });
  });

  group('AnyGuard', () {
    test('allows when any guard allows', () async {
      final guard = AnyGuard([
        _RejectGuard(),
        _AllowGuard(),
        _RedirectGuard('/login'),
      ]);
      final context = _createContext('/test');

      final result = await guard.canActivate(context);

      expect(result, isA<GuardAllow>());
    });

    test('returns last reject when no guards allow', () async {
      final guard = AnyGuard([
        _RejectGuard(reason: 'First'),
        _RejectGuard(reason: 'Second'),
      ]);
      final context = _createContext('/test');

      final result = await guard.canActivate(context);

      expect(result, isA<GuardReject>());
      expect((result as GuardReject).reason, equals('Second'));
    });

    test('returns redirect when no guards allow but one redirects', () async {
      final guard = AnyGuard([
        _RejectGuard(),
        _RedirectGuard('/login'),
      ]);
      final context = _createContext('/test');

      final result = await guard.canActivate(context);

      expect(result, isA<GuardRedirect>());
    });
  });
}

// Test helpers

GuardContext _createContext(String path) {
  return GuardContext(
    destination: RouteDefinition(
      path: path,
      builder: (_, __) => const SizedBox(),
    ),
    matchedLocation: path,
  );
}

class _SimpleGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _AppliesGuard extends RouteGuard {
  @override
  final List<String> appliesTo;

  _AppliesGuard(this.appliesTo);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _ExcludesGuard extends RouteGuard {
  @override
  final List<String> excludes;

  _ExcludesGuard(this.excludes);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _AppliesAndExcludesGuard extends RouteGuard {
  @override
  final List<String> appliesTo;
  @override
  final List<String> excludes;

  _AppliesAndExcludesGuard({
    required this.appliesTo,
    required this.excludes,
  });

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _PriorityGuard extends RouteGuard {
  @override
  final int priority;

  _PriorityGuard(this.priority);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _AllowGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _RedirectGuard extends RouteGuard {
  final String path;

  _RedirectGuard(this.path);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.redirect(path);
  }
}

class _RejectGuard extends RouteGuard {
  final String? reason;

  _RejectGuard({this.reason});

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.reject(reason: reason);
  }
}

class _CallbackGuard extends RouteGuard {
  final GuardResult Function() callback;

  _CallbackGuard(this.callback);

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return callback();
  }
}
