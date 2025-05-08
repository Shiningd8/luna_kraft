import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A helper class for debugging login issues when App Check is causing problems
class DebugLoginHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Direct login that bypasses App Check completely in debug mode
  static Future<void> debugDirectLogin(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      if (!kDebugMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug login only works in debug mode')),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Attempt direct login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (credential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug login successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed')),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      Navigator.of(context, rootNavigator: true).popUntil((route) {
        return route.isFirst || route.settings.name != null;
      });

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  /// Shows a debug login dialog (use only in debug builds)
  static void showDebugLoginDialog(BuildContext context) {
    if (!kDebugMode) return;

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Debug Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Dispose controllers before closing dialog
              emailController.dispose();
              passwordController.dispose();
              Navigator.pop(dialogContext);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              final password = passwordController.text;

              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Please enter email and password')),
                );
                return;
              }

              // Dispose controllers before closing dialog and navigating
              emailController.dispose();
              passwordController.dispose();
              Navigator.pop(dialogContext);

              debugDirectLogin(
                context,
                email: email,
                password: password,
              );
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}
