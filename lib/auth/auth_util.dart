import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/app_state.dart';

class AuthUtil {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static Future<void> safeSignOut({
    required BuildContext context,
    bool shouldNavigate = true,
    String? navigateTo,
  }) async {
    // Use a flag to track navigation state
    bool hasNavigated = false;

    try {
      // Store references before any async operations
      final router = GoRouter.of(context);
      AppState? appState;

      // Try to get app state, but don't fail if it's not available
      try {
        appState = Provider.of<AppState>(context, listen: false);
      } catch (e) {
        debugPrint('AppState not available: $e');
      }

      // Sign out from Firebase first
      await _auth.signOut();

      // Clean up app state if available
      if (appState != null) {
        try {
          await appState.cleanup();
        } catch (e) {
          debugPrint('Error during app state cleanup: $e');
        }
      }

      // Try to clear any stored state
      try {
        await FFAppState().initializePersistedState();
      } catch (e) {
        debugPrint('Error initializing persisted state: $e');
      }

      // Only proceed with navigation if the widget is still mounted
      // and we haven't navigated yet
      if (shouldNavigate && context.mounted && !hasNavigated) {
        hasNavigated = true;

        try {
          // First pop any remaining navigation stack
          final navigator = Navigator.of(context);
          while (navigator.canPop()) {
            navigator.pop();
          }

          // Then navigate to the specified route or default to sign in
          router.go(navigateTo ?? '/');
        } catch (e) {
          debugPrint('Navigation error during sign out: $e');
          // If navigation fails, mark that we've handled it
          hasNavigated = true;
        }
      }
    } catch (e) {
      debugPrint('Error during safe sign out: $e');
      // Don't show error messages since the widget might be disposed
    }
  }
}
