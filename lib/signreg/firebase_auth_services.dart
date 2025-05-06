import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '/auth/firebase_auth/auth_util.dart';

// Helper class for authentication with better App Check handling
class FirebaseAuthServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Method to check if App Check was disabled in debug mode
  static Future<bool> isAppCheckDisabled() async {
    if (kDebugMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('app_check_skipped') ?? false;
      } catch (e) {
        debugPrint('Error checking App Check status: $e');
      }
    }
    return false;
  }

  // Method to handle and log App Check errors
  static void handleAppCheckError(dynamic error) {
    debugPrint('App Check error detected: $error');
    // Log the error for debugging
    if (kDebugMode) {
      debugPrint('App Check error details: $error');
    }
  }

  // Sign in with email and password with App Check error handling
  static Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
    int retryCount = 0,
  }) async {
    try {
      final isAppCheckSkipped = await isAppCheckDisabled();

      if (isAppCheckSkipped && kDebugMode) {
        debugPrint(
            'App Check is disabled in debug mode - auth may proceed without verification');
      }

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Check if it's an App Check related error
      if (isAppCheckError(e.message ?? '')) {
        debugPrint('App Check error during sign in: ${e.message}');

        if (retryCount < maxRetries) {
          // Add delay and retry
          await Future.delayed(retryDelay * (retryCount + 1));

          // Try to force refresh App Check token before retry
          try {
            if (kDebugMode) {
              // In debug mode, we might have completely skipped App Check
              final isDisabled = await isAppCheckDisabled();
              if (!isDisabled) {
                // Only try to refresh if App Check was not completely disabled
                await FirebaseAppCheck.instance.getToken(true);
              }
            } else {
              // In production, always try to refresh
              await FirebaseAppCheck.instance.getToken(true);
            }
          } catch (refreshError) {
            debugPrint('App Check token refresh error: $refreshError');
          }

          // Retry the sign-in
          return signInWithEmailPassword(
            email: email,
            password: password,
            context: context,
            retryCount: retryCount + 1,
          );
        }

        // If we've exhausted retries and are in debug mode
        final isDisabled = await isAppCheckDisabled();
        if (kDebugMode && isDisabled) {
          debugPrint(
              'All retries failed. App Check is disabled in debug mode.');

          // Show a debug-only message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'App Check error in debug mode. Try restarting the app.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }

      // For other authentication errors, rethrow
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  // Create account with email and password with App Check error handling
  static Future<UserCredential?> createUserWithEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
    int retryCount = 0,
  }) async {
    try {
      final isAppCheckSkipped = await isAppCheckDisabled();

      if (isAppCheckSkipped && kDebugMode) {
        debugPrint(
            'App Check is disabled in debug mode - registration may proceed without verification');
      }

      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Check if it's an App Check related error
      if (isAppCheckError(e.message ?? '')) {
        debugPrint('App Check error during registration: ${e.message}');

        if (retryCount < maxRetries) {
          // Add delay and retry
          await Future.delayed(retryDelay * (retryCount + 1));

          // Try to force refresh App Check token before retry
          try {
            if (kDebugMode) {
              // In debug mode, we might have completely skipped App Check
              final isDisabled = await isAppCheckDisabled();
              if (!isDisabled) {
                // Only try to refresh if App Check was not completely disabled
                await FirebaseAppCheck.instance.getToken(true);
              }
            } else {
              // In production, always try to refresh
              await FirebaseAppCheck.instance.getToken(true);
            }
          } catch (refreshError) {
            debugPrint('App Check token refresh error: $refreshError');
          }

          // Retry the registration
          return createUserWithEmailPassword(
            email: email,
            password: password,
            context: context,
            retryCount: retryCount + 1,
          );
        }
      }

      // For other authentication errors, rethrow
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      rethrow;
    }
  }

  // Password reset with App Check error handling
  static Future<void> resetPassword({
    required String email,
    required BuildContext context,
    int retryCount = 0,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Check if it's an App Check related error
      if (isAppCheckError(e.message ?? '') && retryCount < maxRetries) {
        debugPrint('App Check error during password reset: ${e.message}');

        // Add delay and retry
        await Future.delayed(retryDelay * (retryCount + 1));

        // Retry
        return resetPassword(
          email: email,
          context: context,
          retryCount: retryCount + 1,
        );
      }

      // For other errors, rethrow
      rethrow;
    }
  }
}
