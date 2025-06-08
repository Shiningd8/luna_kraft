import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

Future<UserCredential?> appleSignInFunc() async {
  try {
    // Check if Apple Sign-In is available on this platform
    if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
      debugPrint('Apple Sign-In is not available on this platform');
      throw FirebaseAuthException(
        code: 'apple-signin-unavailable',
        message: 'Apple Sign-In is not available on this platform.',
      );
    }

    // Check if Apple Sign-In is available
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      debugPrint('Apple Sign-In is not available on this device');
      throw FirebaseAuthException(
        code: 'apple-signin-unavailable',
        message: 'Apple Sign-In is not available on this device.',
      );
    }

    // Request Apple ID credential
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: kIsWeb
          ? WebAuthenticationOptions(
              clientId: 'com.flutterflow.lunakraft', // Your app's bundle ID
              redirectUri: Uri.parse(
                'https://luna-kraft-default-rtdb.firebaseio.com/__/auth/handler',
              ),
            )
          : null,
    );

    // Create OAuth credential for Firebase
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in to Firebase with the Apple credential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    
    // Handle name information for both new and existing users
    await _handleAppleUserNameInfo(userCredential, appleCredential);
    
    return userCredential;
  } catch (e) {
    debugPrint('Apple sign in error: ${e.toString()}');

    // Handle specific Apple Sign-In exceptions
    if (e is SignInWithAppleAuthorizationException) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          debugPrint('User cancelled Apple Sign-In');
          return null;
        case AuthorizationErrorCode.failed:
          throw FirebaseAuthException(
            code: 'apple-signin-failed',
            message: 'Apple Sign-In failed. Please try again.',
          );
        case AuthorizationErrorCode.invalidResponse:
          throw FirebaseAuthException(
            code: 'apple-signin-invalid-response',
            message: 'Invalid response from Apple Sign-In.',
          );
        case AuthorizationErrorCode.notHandled:
          throw FirebaseAuthException(
            code: 'apple-signin-not-handled',
            message: 'Apple Sign-In request was not handled.',
          );
        case AuthorizationErrorCode.unknown:
          throw FirebaseAuthException(
            code: 'apple-signin-unknown-error',
            message: 'An unknown error occurred with Apple Sign-In.',
          );
        default:
          throw FirebaseAuthException(
            code: 'apple-signin-error',
            message: 'Apple Sign-In error: ${e.message}',
          );
      }
    }

    // Handle Firebase Auth exceptions
    if (e is FirebaseAuthException) {
      debugPrint('Firebase Auth Error Code: ${e.code}');
      rethrow;
    }

    // Re-throw other errors
    rethrow;
  }
}

Future<void> _handleAppleUserNameInfo(
  UserCredential userCredential, 
  AuthorizationCredentialAppleID appleCredential
) async {
  try {
    final user = userCredential.user;
    if (user == null) return;

    final isNewUser = userCredential.additionalUserInfo?.isNewUser == true;
    
    // Check if Apple provided name information (only happens on first sign-in)
    String? displayName;
    if (appleCredential.givenName != null && appleCredential.familyName != null) {
      displayName = '${appleCredential.givenName} ${appleCredential.familyName}'.trim();
      debugPrint('Apple provided name: $displayName');
    }

    if (isNewUser) {
      debugPrint('New Apple user detected');
      
      // For new users, update Firebase Auth display name if we have it
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        debugPrint('Updated Firebase Auth display name to: $displayName');
      }
      
      // Store Apple name info in Firestore for future reference
      await _storeAppleNameInFirestore(user.uid, displayName, appleCredential);
    } else {
      debugPrint('Existing Apple user detected');
      
      // For existing users, try to restore name from Firestore if Firebase Auth doesn't have it
      if ((user.displayName == null || user.displayName!.isEmpty)) {
        final storedName = await _getStoredAppleNameFromFirestore(user.uid);
        if (storedName != null && storedName.isNotEmpty) {
          await user.updateDisplayName(storedName);
          debugPrint('Restored display name from Firestore: $storedName');
        }
      }
    }
  } catch (e) {
    debugPrint('Error handling Apple user name info: $e');
    // Don't throw here as this is not critical for authentication
  }
}

Future<void> _storeAppleNameInFirestore(
  String uid, 
  String? displayName, 
  AuthorizationCredentialAppleID appleCredential
) async {
  try {
    final Map<String, dynamic> appleData = {};
    
    if (displayName != null && displayName.isNotEmpty) {
      appleData['apple_display_name'] = displayName;
    }
    
    if (appleCredential.givenName != null) {
      appleData['apple_given_name'] = appleCredential.givenName;
    }
    
    if (appleCredential.familyName != null) {
      appleData['apple_family_name'] = appleCredential.familyName;
    }
    
    if (appleData.isNotEmpty) {
      appleData['apple_name_stored_at'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('apple_user_data')
          .doc(uid)
          .set(appleData, SetOptions(merge: true));
      
      debugPrint('Stored Apple name data in Firestore for user: $uid');
    }
  } catch (e) {
    debugPrint('Error storing Apple name in Firestore: $e');
  }
}

Future<String?> _getStoredAppleNameFromFirestore(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('apple_user_data')
        .doc(uid)
        .get();
    
    if (doc.exists) {
      final data = doc.data();
      final storedName = data?['apple_display_name'] as String?;
      debugPrint('Retrieved stored Apple name: $storedName');
      return storedName;
    }
  } catch (e) {
    debugPrint('Error retrieving stored Apple name: $e');
  }
  return null;
}

Future<void> signOutWithApple() async {
  try {
    // Apple doesn't provide a sign-out method like Google
    // We only need to sign out from Firebase Auth
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('Error signing out: $e');
    rethrow;
  }
} 