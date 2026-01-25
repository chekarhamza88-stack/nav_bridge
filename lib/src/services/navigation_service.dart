import 'package:flutter/material.dart';

import '../core/router_adapter.dart';
import '../core/typed_route.dart';

/// Base navigation service that apps can extend or use directly.
///
/// Provides a clean API for navigation that delegates to the underlying
/// [RouterAdapter]. This abstraction allows you to swap router implementations
/// without changing your navigation code.
///
/// ## Example
/// ```dart
/// class AppNavigationService extends BaseNavigationService {
///   @override
///   final RouterAdapter adapter;
///
///   AppNavigationService(this.adapter);
///
///   // Add app-specific navigation methods
///   Future<void> goToUserProfile(String userId) =>
///     goNamed('userProfile', pathParams: {'userId': userId});
///
///   Future<void> goToSettings() => go('/settings');
/// }
/// ```
abstract class BaseNavigationService {
  /// The underlying router adapter.
  RouterAdapter get adapter;

  // Path-based navigation

  /// Navigate to a path, replacing the current history.
  Future<void> go(String path, {Object? extra}) =>
      adapter.go(path, extra: extra);

  /// Push a path onto the navigation stack.
  Future<void> push(String path, {Object? extra}) =>
      adapter.push(path, extra: extra);

  /// Replace the current location with a new path.
  Future<void> replace(String path, {Object? extra}) =>
      adapter.replace(path, extra: extra);

  /// Pop the current location from the stack.
  void pop<T>([T? result]) => adapter.pop(result);

  /// Pop until a condition is met.
  void popUntil(bool Function(String path) predicate) =>
      adapter.popUntil(predicate);

  /// Check if we can pop.
  bool canPop() => adapter.canPop();

  // Named navigation

  /// Navigate to a named route, replacing the current history.
  Future<void> goNamed(
    String name, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) =>
      adapter.goNamed(
        name,
        pathParameters: pathParams,
        queryParameters: queryParams,
        extra: extra,
      );

  /// Push a named route onto the navigation stack.
  Future<void> pushNamed(
    String name, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) =>
      adapter.pushNamed(
        name,
        pathParameters: pathParams,
        queryParameters: queryParams,
        extra: extra,
      );

  /// Replace the current location with a named route.
  Future<void> replaceNamed(
    String name, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) =>
      adapter.replaceNamed(
        name,
        pathParameters: pathParams,
        queryParameters: queryParams,
        extra: extra,
      );

  // Type-safe navigation

  /// Navigate to a typed route, replacing the current history.
  Future<void> goTo<T extends TypedRoute>(T route) => adapter.goToRoute(route);

  /// Push a typed route onto the navigation stack.
  Future<void> pushTo<T extends TypedRoute>(T route) =>
      adapter.pushRoute(route);

  /// Replace the current location with a typed route.
  Future<void> replaceTo<T extends TypedRoute>(T route) =>
      adapter.replaceRoute(route);

  // State getters

  /// The current location path.
  String get currentLocation => adapter.currentLocation;

  /// The current route name (if available).
  String? get currentRouteName => adapter.currentRouteName;

  /// The current path parameters.
  Map<String, String> get currentPathParameters =>
      adapter.currentPathParameters;

  /// The current query parameters.
  Map<String, String> get currentQueryParameters =>
      adapter.currentQueryParameters;

  // Reactive navigation

  /// Stream of location changes.
  Stream<String> get locationChanges => adapter.locationStream;

  /// Refresh the router (re-evaluate guards).
  void refresh() => adapter.refresh();

  /// Dispose of resources.
  void dispose() => adapter.dispose();
}

/// Ready-to-use navigation service with modal and dialog support.
///
/// This service extends [BaseNavigationService] with support for modals,
/// dialogs, and bottom sheets using a navigator key.
///
/// ## Example
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
///
/// final navigationService = NavBridgeNavigationService(
///   adapter: myAdapter,
///   navigatorKey: navigatorKey,
/// );
///
/// // Use in MaterialApp
/// MaterialApp.router(
///   routerConfig: adapter.routerConfig,
/// )
///
/// // Show a dialog
/// final result = await navigationService.showConfirmDialog(
///   title: 'Delete Item',
///   message: 'Are you sure you want to delete this item?',
/// );
/// ```
class NavBridgeNavigationService extends BaseNavigationService {
  @override
  final RouterAdapter adapter;

  /// The navigator key for modal/dialog operations.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Creates a NavBridgeNavigationService.
  NavBridgeNavigationService({
    required this.adapter,
    required this.navigatorKey,
  });

  /// Gets the navigator context, or null if not available.
  BuildContext? get _context => navigatorKey.currentContext;

  /// Gets the navigator state, or null if not available.
  NavigatorState? get _navigator => navigatorKey.currentState;

  // Modal support

  /// Shows a modal dialog.
  ///
  /// Returns the result of the dialog, or null if dismissed.
  Future<T?> showModal<T>({
    required Widget Function(BuildContext context) builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) async {
    final context = _context;
    if (context == null) {
      throw StateError(
        'Navigator context not available. '
        'Make sure the navigatorKey is attached to your MaterialApp.',
      );
    }

    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Shows a confirmation dialog with Yes/No buttons.
  ///
  /// Returns true if confirmed, false if cancelled, null if dismissed.
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
    bool barrierDismissible = true,
  }) async {
    return showModal<bool>(
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Shows an alert dialog with a single OK button.
  Future<void> showAlert({
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showModal<void>(
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet.
  ///
  /// Returns the result of the bottom sheet, or null if dismissed.
  Future<T?> showBottomSheet<T>({
    required Widget Function(BuildContext context) builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = false,
    RouteSettings? routeSettings,
  }) async {
    final context = _context;
    if (context == null) {
      throw StateError(
        'Navigator context not available. '
        'Make sure the navigatorKey is attached to your MaterialApp.',
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
    );
  }

  /// Shows a snackbar.
  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    final context = _context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Hides the current snackbar.
  void hideSnackBar() {
    final context = _context;
    if (context == null) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Shows a loading overlay.
  ///
  /// Returns a function to dismiss the overlay.
  void Function() showLoading({
    String? message,
    Color barrierColor = Colors.black54,
  }) {
    final context = _context;
    if (context == null) {
      throw StateError(
        'Navigator context not available. '
        'Make sure the navigatorKey is attached to your MaterialApp.',
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: barrierColor,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return () {
      final nav = _navigator;
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    };
  }
}
