import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Configure Google Sign In with proper scopes
final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Avoid requesting immediate silent sign-in
  // which can cause issues on some Android devices
  signInOption: SignInOption.standard,
);

Future<UserCredential?> googleSignInFunc() async {
  try {
    if (kIsWeb) {
      // Web platform sign in using popup
      return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    }

    // First, try to sign out to ensure a clean authentication state
    await signOutWithGoogle().catchError((e) {
      debugPrint('Error during sign out before sign in: $e');
      // Continue even if sign out fails
      return null;
    });

    // Trigger the Google Sign In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // If user cancels the sign-in flow
    if (googleUser == null) {
      debugPrint('User cancelled Google Sign In');
      return null;
    }

    try {
      // Get the authentication details from the sign in
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential from the authentication tokens
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase with the Google credential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error authenticating with Google: $e');

      // Attempt to disconnect the Google account to clear any stale state
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}

      // Let the error handler below deal with this
      rethrow;
    }
  } catch (e) {
    // Log the error with more details
    debugPrint('Google sign in error: ${e.toString()}');

    // Handle specific platform exceptions
    if (e is PlatformException) {
      if (e.code == 'sign_in_failed' &&
          e.message?.contains('ApiException: 10') == true) {
        // Error code 10 is a developer error - SHA-1 certificate fingerprint issue
        debugPrint(
            'Error code 10: SHA-1 fingerprint not registered in Firebase console');

        // Instead of crashing, show a dialog to the user that an error occurred
        // This will be caught by the UI layer to show a friendly message
        throw FirebaseAuthException(
          code: 'google-signin-config-error',
          message:
              'There was a problem with Google Sign-In configuration. Please contact support.',
        );
      }
    }

    // If we have a FirebaseAuthException, extract the code for better handling
    if (e is FirebaseAuthException) {
      debugPrint('Firebase Auth Error Code: ${e.code}');
    }

    // Re-throw the error for the caller to handle
    rethrow;
  }
}

Future<void> signOutWithGoogle() async {
  try {
    // First sign out from Google
    await _googleSignIn.signOut();

    // Then sign out from Firebase Auth
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('Error signing out: $e');
    rethrow;
  }
}
