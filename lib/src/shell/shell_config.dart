import 'package:flutter/widgets.dart';

/// Configuration for shell navigation behavior.
/// 
/// Use this to customize how the shell handles navigation,
/// state preservation, and transitions.
/// 
/// ## Example
/// ```dart
/// final adapter = GoRouterAdapter.wrap(
///   existingRouter,
///   shellConfig: ShellConfig(
///     preserveState: true,
///     indexedStackBuilder: (children, index) => IndexedStack(
///       index: index,
///       children: children,
///     ),
///   ),
/// );
/// ```
class ShellConfig {
  /// Whether to preserve state when switching between branches.
  /// 
  /// If true, each branch maintains its navigation stack.
  /// If false, branches are rebuilt when switching.
  final bool preserveState;

  /// Custom builder for the indexed stack (if using IndexedStack pattern).
  final Widget Function(
    List<Widget> children,
    int currentIndex,
  )? indexedStackBuilder;

  /// Custom builder for the bottom navigation bar.
  final Widget Function(
    BuildContext context,
    int currentIndex,
    void Function(int) onTap,
  )? bottomNavBuilder;

  /// Animation duration for branch transitions.
  final Duration transitionDuration;

  /// Custom transition builder for branch changes.
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  )? transitionBuilder;

  /// Whether to preload all branches on first render.
  final bool preloadBranches;

  /// Callback when branch changes.
  final void Function(int oldIndex, int newIndex)? onBranchChanged;

  const ShellConfig({
    this.preserveState = true,
    this.indexedStackBuilder,
    this.bottomNavBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionBuilder,
    this.preloadBranches = false,
    this.onBranchChanged,
  });

  ShellConfig copyWith({
    bool? preserveState,
    Widget Function(List<Widget>, int)? indexedStackBuilder,
    Widget Function(BuildContext, int, void Function(int))? bottomNavBuilder,
    Duration? transitionDuration,
    Widget Function(BuildContext, Animation<double>, Widget)? transitionBuilder,
    bool? preloadBranches,
    void Function(int, int)? onBranchChanged,
  }) {
    return ShellConfig(
      preserveState: preserveState ?? this.preserveState,
      indexedStackBuilder: indexedStackBuilder ?? this.indexedStackBuilder,
      bottomNavBuilder: bottomNavBuilder ?? this.bottomNavBuilder,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionBuilder: transitionBuilder ?? this.transitionBuilder,
      preloadBranches: preloadBranches ?? this.preloadBranches,
      onBranchChanged: onBranchChanged ?? this.onBranchChanged,
    );
  }
}

/// Represents the current state of shell navigation.
class ShellNavigationState {
  /// Current branch index.
  final int currentIndex;

  /// Navigation stacks for each branch.
  final List<List<String>> branchStacks;

  /// History of branch selections.
  final List<int> branchHistory;

  const ShellNavigationState({
    this.currentIndex = 0,
    this.branchStacks = const [],
    this.branchHistory = const [],
  });

  ShellNavigationState copyWith({
    int? currentIndex,
    List<List<String>>? branchStacks,
    List<int>? branchHistory,
  }) {
    return ShellNavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      branchStacks: branchStacks ?? this.branchStacks,
      branchHistory: branchHistory ?? this.branchHistory,
    );
  }

  /// Get the current path in the active branch.
  String? get currentPath {
    if (branchStacks.isEmpty || currentIndex >= branchStacks.length) {
      return null;
    }
    final stack = branchStacks[currentIndex];
    return stack.isNotEmpty ? stack.last : null;
  }

  /// Check if we can go back within the current branch.
  bool get canPopInBranch {
    if (branchStacks.isEmpty || currentIndex >= branchStacks.length) {
      return false;
    }
    return branchStacks[currentIndex].length > 1;
  }

  /// Check if we can go back to a previous branch.
  bool get canPopToPreviousBranch => branchHistory.length > 1;
}
