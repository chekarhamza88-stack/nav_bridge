import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('GuardResult', () {
    group('GuardAllow', () {
      test('creates allow result', () {
        final result = GuardResult.allow();

        expect(result, isA<GuardAllow>());
        expect(result.isAllowed, isTrue);
        expect(result.isRedirect, isFalse);
        expect(result.isRejected, isFalse);
      });

      test('equality works correctly', () {
        final result1 = GuardResult.allow();
        final result2 = GuardResult.allow();

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('toString returns readable format', () {
        final result = GuardResult.allow();

        expect(result.toString(), equals('GuardAllow()'));
      });
    });

    group('GuardRedirect', () {
      test('creates redirect result with path', () {
        final result = GuardResult.redirect('/login');

        expect(result, isA<GuardRedirect>());
        expect(result.isRedirect, isTrue);
        expect((result).path, equals('/login'));
        expect(result.replace, isTrue);
      });

      test('creates redirect result with extra data', () {
        final result = GuardResult.redirect(
          '/login',
          extra: {'returnTo': '/dashboard'},
        );

        expect(result, isA<GuardRedirect>());
        expect((result).extra, {'returnTo': '/dashboard'});
      });

      test('creates redirect result with replace=false', () {
        final result = GuardResult.redirect('/login', replace: false);

        expect((result).replace, isFalse);
      });

      test('equality works correctly', () {
        final result1 = GuardResult.redirect('/login');
        final result2 = GuardResult.redirect('/login');
        final result3 = GuardResult.redirect('/register');

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString returns readable format', () {
        final result = GuardResult.redirect('/login');

        expect(
          result.toString(),
          equals('GuardRedirect(path: /login, replace: true)'),
        );
      });
    });

    group('GuardReject', () {
      test('creates reject result without reason', () {
        final result = GuardResult.reject();

        expect(result, isA<GuardReject>());
        expect(result.isRejected, isTrue);
        expect((result).reason, isNull);
        expect(result.showError, isFalse);
      });

      test('creates reject result with reason', () {
        final result = GuardResult.reject(reason: 'Unauthorized');

        expect((result).reason, equals('Unauthorized'));
      });

      test('creates reject result with showError', () {
        final result = GuardResult.reject(showError: true);

        expect((result).showError, isTrue);
      });

      test('equality works correctly', () {
        final result1 = GuardResult.reject(reason: 'test');
        final result2 = GuardResult.reject(reason: 'test');
        final result3 = GuardResult.reject(reason: 'other');

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString returns readable format', () {
        final result = GuardResult.reject(reason: 'Unauthorized');

        expect(result.toString(), equals('GuardReject(reason: Unauthorized)'));
      });
    });

    group('Pattern matching with when()', () {
      test('matches allow', () {
        final result = GuardResult.allow();

        final matched = result.when(
          allow: () => 'allowed',
          redirect: (path, extra, replace) => 'redirect to $path',
          reject: (reason, showError) => 'rejected: $reason',
        );

        expect(matched, equals('allowed'));
      });

      test('matches redirect', () {
        final result = GuardResult.redirect('/login');

        final matched = result.when(
          allow: () => 'allowed',
          redirect: (path, extra, replace) => 'redirect to $path',
          reject: (reason, showError) => 'rejected: $reason',
        );

        expect(matched, equals('redirect to /login'));
      });

      test('matches reject', () {
        final result = GuardResult.reject(reason: 'No access');

        final matched = result.when(
          allow: () => 'allowed',
          redirect: (path, extra, replace) => 'redirect to $path',
          reject: (reason, showError) => 'rejected: $reason',
        );

        expect(matched, equals('rejected: No access'));
      });
    });

    group('Dart 3 pattern matching', () {
      test('works with switch expression', () {
        final result = GuardResult.redirect('/login');

        final message = switch (result) {
          GuardAllow() => 'allowed',
          GuardRedirect(:final path) => 'redirect to $path',
        };

        expect(message, equals('redirect to /login'));
      });
    });
  });
}
