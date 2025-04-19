import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import 'package:provider/provider.dart';
import '/services/app_state.dart';

class Prof1Widget extends StatefulWidget {
  // ... (existing code)
  const Prof1Widget({Key? key}) : super(key: key);

  @override
  _Prof1WidgetState createState() => _Prof1WidgetState();
}

class _Prof1WidgetState extends State<Prof1Widget> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _signOut() async {
    if (_isDisposed) return;

    // Store necessary references before any async operations
    final navigator = Navigator.of(context);
    final goRouter = GoRouter.of(context);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear any stored state
      await FFAppState().initializePersistedState();

      // Clean up app state
      await appState.cleanup();

      // Only proceed with navigation if not disposed
      if (!_isDisposed && mounted) {
        // First pop any remaining navigation stack
        while (navigator.canPop()) {
          navigator.pop();
        }
        // Then navigate to sign in
        goRouter.go('/');
      }
    } catch (e) {
      print('Error signing out: $e');
      // Don't show error messages since the widget might be disposed
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
    return Container(); // Add a default return value
  }
}
