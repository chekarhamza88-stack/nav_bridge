import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bridge/nav_bridge.dart';

void main() {
  group('InMemoryAdapter', () {
    late InMemoryAdapter adapter;

    setUp(() {
      adapter = InMemoryAdapter();
    });

    group('initialization', () {
      test('starts at root by default', () {
        expect(adapter.currentLocation, equals('/'));
      });

      test('starts at custom initial location', () {
        adapter = InMemoryAdapter(initialLocation: '/home');
        
        expect(adapter.currentLocation, equals('/home'));
      });

      test('stack contains initial location', () {
        expect(adapter.stack, equals(['/']));
      });
    });

    group('go()', () {
      test('navigates to new location', () async {
        await adapter.go('/profile');
        
        expect(adapter.currentLocation, equals('/profile'));
      });

      test('replaces navigation stack', () async {
        await adapter.go('/first');
        await adapter.go('/second');
        
        expect(adapter.stack, equals(['/second']));
      });

      test('records navigation in history', () async {
        await adapter.go('/first');
        await adapter.go('/second');
        
        expect(adapter.navigationHistory, equals(['/first', '/second']));
      });

      test('emits location on stream', () async {
        final locations = <String>[];
        adapter.locationStream.listen(locations.add);
        
        await adapter.go('/test');
        await Future<void>.delayed(Duration.zero);
        
        expect(locations, contains('/test'));
      });
    });

    group('push()', () {
      test('pushes location onto stack', () async {
        await adapter.push('/first');
        await adapter.push('/second');
        
        expect(adapter.stack, equals(['/', '/first', '/second']));
        expect(adapter.currentLocation, equals('/second'));
      });

      test('records navigation in history', () async {
        await adapter.push('/first');
        await adapter.push('/second');
        
        expect(
          adapter.history.map((e) => e.type),
          equals([NavigationType.push, NavigationType.push]),
        );
      });
    });

    group('replace()', () {
      test('replaces current location', () async {
        await adapter.push('/first');
        await adapter.replace('/replaced');
        
        expect(adapter.stack, equals(['/', '/replaced']));
        expect(adapter.currentLocation, equals('/replaced'));
      });
    });

    group('pop()', () {
      test('pops from stack', () async {
        await adapter.push('/first');
        await adapter.push('/second');
        
        adapter.pop();
        
        expect(adapter.currentLocation, equals('/first'));
        expect(adapter.stack, equals(['/', '/first']));
      });

      test('does not pop last item', () async {
        adapter.pop();
        adapter.pop();
        
        expect(adapter.currentLocation, equals('/'));
        expect(adapter.stack, equals(['/']));
      });

      test('records pop in history', () async {
        await adapter.push('/first');
        adapter.pop();
        
        expect(adapter.history.last.type, equals(NavigationType.pop));
      });
    });

    group('canPop()', () {
      test('returns false when stack has one item', () {
        expect(adapter.canPop(), isFalse);
      });

      test('returns true when stack has multiple items', () async {
        await adapter.push('/test');
        
        expect(adapter.canPop(), isTrue);
      });
    });

    group('popUntil()', () {
      test('pops until predicate is true', () async {
        await adapter.push('/a');
        await adapter.push('/b');
        await adapter.push('/c');
        
        adapter.popUntil((path) => path == '/a');
        
        expect(adapter.currentLocation, equals('/a'));
      });

      test('does not pop below root', () async {
        await adapter.push('/test');
        
        adapter.popUntil((path) => path == '/nonexistent');
        
        expect(adapter.currentLocation, equals('/'));
      });
    });

    group('reset()', () {
      test('resets to initial state', () async {
        await adapter.push('/first');
        await adapter.push('/second');
        
        adapter.reset();
        
        expect(adapter.currentLocation, equals('/'));
        expect(adapter.stack, equals(['/']));
        expect(adapter.history, isEmpty);
      });

      test('resets to custom initial location', () async {
        await adapter.push('/test');
        
        adapter.reset(initialLocation: '/home');
        
        expect(adapter.currentLocation, equals('/home'));
      });
    });

    group('guards', () {
      test('adds guard', () {
        final guard = _TestGuard();
        
        adapter.addGuard(guard);
        
        expect(adapter.guards, contains(guard));
      });

      test('removes guard', () {
        final guard = _TestGuard();
        adapter.addGuard(guard);
        
        adapter.removeGuard(guard);
        
        expect(adapter.guards, isNot(contains(guard)));
      });

      test('guard can redirect navigation', () async {
        final guard = _RedirectGuard('/login');
        adapter = InMemoryAdapter(guards: [guard]);
        
        await adapter.go('/protected');
        
        expect(adapter.currentLocation, equals('/login'));
      });

      test('guard can allow navigation', () async {
        final guard = _AllowGuard();
        adapter = InMemoryAdapter(guards: [guard]);
        
        await adapter.go('/allowed');
        
        expect(adapter.currentLocation, equals('/allowed'));
      });

      test('guard can reject navigation', () async {
        final guard = _RejectGuard();
        adapter = InMemoryAdapter(guards: [guard]);
        
        await adapter.go('/rejected');
        
        // Should stay at current location
        expect(adapter.currentLocation, equals('/'));
      });

      test('guards run in priority order', () async {
        final lowPriority = _PriorityGuard(priority: 10, redirect: '/low');
        final highPriority = _PriorityGuard(priority: 100, redirect: '/high');
        
        adapter = InMemoryAdapter(guards: [lowPriority, highPriority]);
        
        await adapter.go('/test');
        
        // High priority runs first and redirects
        expect(adapter.currentLocation, equals('/high'));
      });
    });

    group('path parameters', () {
      test('extracts numeric path parameters', () async {
        await adapter.go('/users/42');
        
        expect(adapter.currentPathParameters, {'id': '42'});
      });
    });

    group('query parameters', () {
      test('extracts query parameters', () async {
        await adapter.go('/search?query=test&page=1');
        
        expect(adapter.currentQueryParameters, {'query': 'test', 'page': '1'});
      });
    });

    group('history tracking', () {
      test('tracks navigation type', () async {
        await adapter.go('/go');
        await adapter.push('/push');
        await adapter.replace('/replace');
        adapter.pop();
        
        final types = adapter.history.map((e) => e.type).toList();
        
        expect(types, [
          NavigationType.go,
          NavigationType.push,
          NavigationType.replace,
          NavigationType.pop,
        ]);
      });

      test('tracks redirects', () async {
        final guard = _RedirectGuard('/redirected');
        adapter = InMemoryAdapter(guards: [guard]);
        
        await adapter.go('/original');
        
        final lastEvent = adapter.history.last;
        expect(lastEvent.type, equals(NavigationType.redirected));
        expect(lastEvent.redirectedFrom, equals('/original'));
      });

      test('records timestamps', () async {
        final before = DateTime.now();
        await adapter.go('/test');
        final after = DateTime.now();
        
        final event = adapter.history.first;
        expect(event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(event.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
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

class _AllowGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.allow();
  }
}

class _RedirectGuard extends RouteGuard {
  final String redirectPath;
  
  _RedirectGuard(this.redirectPath);
  
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.redirect(redirectPath);
  }
}

class _RejectGuard extends RouteGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.reject(reason: 'Test rejection');
  }
}

class _PriorityGuard extends RouteGuard {
  @override
  final int priority;
  final String redirect;
  
  _PriorityGuard({required this.priority, required this.redirect});
  
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    return GuardResult.redirect(redirect);
  }
}
