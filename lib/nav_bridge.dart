/// Nav Bridge - Enterprise-Ready Progressive Navigation Architecture
///
/// A router-agnostic navigation layer for Flutter that allows you to wrap
/// existing GoRouter apps and migrate to a clean, testable, decoupled
/// architecture without rewriting your routes.
library;

export 'src/core/guard_context.dart';
export 'src/core/guard_result.dart';
export 'src/core/route_definition.dart';
export 'src/core/route_guard.dart';
export 'src/core/router_adapter.dart';

export 'src/adapters/go_router_adapter.dart';
export 'src/adapters/in_memory_adapter.dart';

export 'src/guards/riverpod_route_guard.dart';
export 'src/guards/go_router_guard_bridge.dart';

export 'src/shell/shell_route_definition.dart';
export 'src/shell/shell_config.dart';
