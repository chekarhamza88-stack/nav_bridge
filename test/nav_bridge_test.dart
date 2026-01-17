// Main test file for nav_bridge
// Run with: flutter test

import 'core/guard_context_test.dart' as guard_context_test;
import 'core/guard_result_test.dart' as guard_result_test;
import 'core/route_guard_test.dart' as route_guard_test;
import 'adapters/in_memory_adapter_test.dart' as in_memory_adapter_test;

void main() {
  guard_context_test.main();
  guard_result_test.main();
  route_guard_test.main();
  in_memory_adapter_test.main();
}
