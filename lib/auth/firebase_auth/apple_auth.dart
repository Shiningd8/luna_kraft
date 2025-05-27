import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Generates a cryptographically secure random nonce, to be included in a
/// credential request.
String generateNonce([int length = 32]) {
  final charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

/// Returns the sha256 hash of [input] in hex notation.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<UserCredential> appleSignIn() async {
  try {
    if (kIsWeb) {
      final provider = OAuthProvider("apple.com")
        ..addScope('email')
        ..addScope('name');

      // Sign in the user with Firebase.
      return await FirebaseAuth.instance.signInWithPopup(provider);
    }
    
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // First, check if Apple Sign In is available on this device
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'apple-signin-unavailable',
        message: 'Apple Sign In is not available on this device. Please try another sign-in method.',
      );
    }

    try {
      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      final user =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // The display name does not automatically come with the user.
      final displayName = [appleCredential.givenName, appleCredential.familyName]
          .where((name) => name != null && name.isNotEmpty)
          .join(' ');

      if (displayName.isNotEmpty) {
        try {
          await user.user?.updateDisplayName(displayName);
        } catch (e) {
          debugPrint('Error updating display name: $e');
          // Continue anyway as this is not critical
        }
      }

      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle specific Apple Sign In errors
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw FirebaseAuthException(
            code: 'user-cancelled',
            message: 'Sign in was cancelled by the user.',
          );
        case AuthorizationErrorCode.failed:
          throw FirebaseAuthException(
            code: 'apple-signin-failed',
            message: 'Apple Sign In failed: ${e.message}',
          );
        case AuthorizationErrorCode.invalidResponse:
          throw FirebaseAuthException(
            code: 'apple-signin-invalid-response',
            message: 'Invalid response from Apple Sign In.',
          );
        default:
          throw FirebaseAuthException(
            code: 'apple-signin-error',
            message: 'Apple Sign In error: ${e.code.name}',
          );
      }
    } on PlatformException catch (e) {
      throw FirebaseAuthException(
        code: 'platform-error',
        message: 'Platform error during Apple Sign In: ${e.message}',
      );
    }
  } catch (e) {
    // If it's already a FirebaseAuthException, just rethrow it
    if (e is FirebaseAuthException) {
      rethrow;
    }
    
    // Otherwise wrap the error in a FirebaseAuthException for consistent handling
    debugPrint('Unexpected error during Apple Sign In: $e');
    throw FirebaseAuthException(
      code: 'unknown-error',
      message: 'An unexpected error occurred during sign in. Please try again.',
    );
  }
}
