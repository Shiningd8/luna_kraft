import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'web_client_id.dart';

// Configure Google Sign In with proper scopes and client ID based on platform
GoogleSignIn _getGoogleSignIn() {
  if (kIsWeb) {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: AuthConfig.webClientId,
    );
  } else if (Platform.isIOS) {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: AuthConfig.iosClientId,
      serverClientId: AuthConfig.iosClientId,
    );
  } else {
    // Android and other platforms
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: AuthConfig.webClientId,
    );
  }
}

Future<UserCredential?> googleSignInFunc() async {
  try {
    // Create the appropriate GoogleSignIn instance for this platform
    final GoogleSignIn googleSignIn = _getGoogleSignIn();
    
    if (kIsWeb) {
      // Web platform sign in using popup with Google provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({
        'login_hint': 'user@example.com',
        'prompt': 'select_account'
      });
      
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    }

    // First, try to sign out to ensure a clean authentication state
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error during sign out before sign in: $e');
      // Continue even if sign out fails
    }

    // Log client ID information for debugging
    if (Platform.isIOS) {
      debugPrint('Using iOS client ID: ${AuthConfig.iosClientId}');
    } else {
      debugPrint('Using web client ID for server auth: ${AuthConfig.webClientId}');
    }

    // Trigger the Google Sign In flow - show account picker
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // If user cancels the sign-in flow
    if (googleUser == null) {
      debugPrint('User cancelled Google Sign In');
      return null;
    }

    try {
      // Get the authentication details from the sign in
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Log token info for debugging (don't log full tokens in production)
      debugPrint('Got ID token (length: ${googleAuth.idToken?.length ?? 0})');
      debugPrint('Got access token (length: ${googleAuth.accessToken?.length ?? 0})');

      // Create a credential from the authentication tokens
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Update user info if needed
      if (userCredential.user != null && 
          (userCredential.user!.displayName == null || userCredential.user!.displayName!.isEmpty)) {
        await userCredential.user!.updateDisplayName(googleUser.displayName);
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Error authenticating with Google: $e');

      // Attempt to disconnect the Google account to clear any stale state
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        // Ignore errors during disconnect
      }

      // Let the error handler below deal with this
      rethrow;
    }
  } catch (e) {
    // Log the error with more details
    debugPrint('Google sign in error: ${e.toString()}');

    // Handle specific platform exceptions
    if (e is PlatformException) {
      if (e.code == 'sign_in_failed' && e.message?.contains('ApiException: 10') == true) {
        // Error code 10 is a developer error - SHA-1 certificate fingerprint issue
        debugPrint('Error code 10: SHA-1 fingerprint not registered in Firebase console');

        // Instead of crashing, show a dialog to the user that an error occurred
        throw FirebaseAuthException(
          code: 'google-signin-config-error',
          message: 'There was a problem with Google Sign-In configuration. Please contact support.',
        );
      }
      
      // Handle play services not available
      if (e.code == 'sign_in_failed' && e.message?.contains('ApiException: 7') == true) {
        throw FirebaseAuthException(
          code: 'play-services-unavailable',
          message: 'Google Play Services is not available or needs to be updated on your device.',
        );
      }
      
      // Handle invalid audience error
      if (e.code == 'sign_in_failed' && e.message?.contains('invalid_audience') == true) {
        debugPrint('Invalid audience error - check client IDs in Firebase console and app');
        throw FirebaseAuthException(
          code: 'invalid-client-id',
          message: 'Google Sign-In configuration error. Please contact support.',
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
    final GoogleSignIn googleSignIn = _getGoogleSignIn();
    await googleSignIn.signOut();

    // Then sign out from Firebase Auth
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('Error signing out: $e');
    rethrow;
  }
}
