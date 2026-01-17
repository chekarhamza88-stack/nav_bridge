# Contributing to Nav Bridge

First off, thank you for considering contributing to Nav Bridge!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [your-email@example.com].

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Code samples** if applicable
- **Flutter/Dart version** (`flutter --version`)
- **Package version** you're using

### Suggesting Features

Feature suggestions are welcome! Please:

1. Check if it's already suggested in [Issues](https://github.com/chekarhamza88-stack/nav_bridge/issues)
2. Create a new issue with the **feature request** template
3. Explain the use case and why it would benefit others

### Pull Requests

We love pull requests! Here's how to contribute code:

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`flutter test`)
6. Ensure code passes analysis (`flutter analyze`)
7. Commit your changes (see [Commit Messages](#commit-messages))
8. Push to your branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## Development Setup

### Prerequisites

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0

### Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/nav_bridge.git
cd nav_bridge

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run analysis
flutter analyze

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Project Structure

```
nav_bridge/
├── lib/
│   ├── nav_bridge.dart             # Main export file
│   └── src/
│       ├── core/                   # Core abstractions
│       │   ├── guard_context.dart
│       │   ├── guard_result.dart
│       │   ├── route_definition.dart
│       │   ├── route_guard.dart
│       │   └── router_adapter.dart
│       ├── adapters/               # Router implementations
│       │   ├── go_router_adapter.dart
│       │   └── in_memory_adapter.dart
│       ├── guards/                 # Guard implementations
│       │   ├── riverpod_route_guard.dart
│       │   └── go_router_guard_bridge.dart
│       └── shell/                  # Shell navigation
│           ├── shell_config.dart
│           └── shell_route_definition.dart
├── test/                           # Tests mirror lib/ structure
├── example/                        # Example application
└── doc/                            # Documentation
```

## Pull Request Process

1. **Update documentation** if you're changing functionality
2. **Add tests** for new features (aim for >80% coverage)
3. **Update CHANGELOG.md** with your changes
4. **Ensure CI passes** (tests, analysis, formatting)
5. **Request review** from maintainers
6. **Address feedback** promptly

### PR Title Format

```
type(scope): description

Examples:
feat(guards): add role-based guard
fix(adapter): handle null state in wrap mode
docs(readme): update migration guide
test(in-memory): add navigation history tests
```

## Style Guidelines

### Dart Style

We follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines with these specifics:

```dart
// ✅ DO: Use const constructors
const MyWidget({super.key});

// ✅ DO: Use trailing commas for better formatting
final list = [
  item1,
  item2,
  item3,
];

// ✅ DO: Document public APIs
/// Navigates to the specified [location].
///
/// Throws [NavigationException] if the route is not found.
Future<void> go(String location);

// ✅ DO: Use named parameters for clarity
GuardResult.redirect(
  '/login',
  extra: {'returnTo': currentPath},
);

// ❌ DON'T: Use dynamic unless absolutely necessary
// ❌ DON'T: Ignore analysis warnings
// ❌ DON'T: Skip documentation on public members
```

### Test Style

```dart
void main() {
  group('GuardContext', () {
    test('provides access to Riverpod Ref', () {
      // Arrange
      final mockRef = MockRef();
      final context = GuardContext(
        destination: RouteDefinition(path: '/test'),
        extras: {'ref': mockRef},
      );

      // Act
      final ref = context.ref;

      // Assert
      expect(ref, mockRef);
    });
  });
}
```

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, semicolons, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Build process, dependencies, etc.

### Examples

```bash
feat(guards): add RiverpodRouteGuard with Ref support

- Add canActivateWithRef method
- Inject Ref from GuardContext extras
- Add AuthenticationGuard convenience class

Closes #123

---

fix(adapter): prevent duplicate navigation events

The location stream was emitting twice on each navigation.
This fix deduplicates events by checking the previous location.

---

docs(readme): add progressive migration guide

Added a 4-phase migration guide to help enterprise teams
adopt Nav Bridge incrementally.
```

## Questions?

Feel free to:
- Open a [Discussion](https://github.com/chekarhamza88-stack/nav_bridge/discussions)
- Ask in the issue you're working on
- Reach out to maintainers

Thank you for contributing!
