import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_app_check_stub.dart'
    if (dart.library.io) 'firebase_app_check_mobile.dart'
    if (dart.library.html) 'firebase_app_check_web.dart';
import '../auth_manager.dart';

import '/backend/backend.dart';
import 'anonymous_auth.dart';
import 'email_auth.dart';
import 'firebase_user_provider.dart';
import 'google_auth.dart';
import 'apple_auth.dart';
import 'jwt_token_auth.dart';
import 'github_auth.dart';
import 'auth_util.dart';

export '../base_auth_user_provider.dart';

class FirebasePhoneAuthManager extends ChangeNotifier {
  bool? _triggerOnCodeSent;
  FirebaseAuthException? phoneAuthError;
  // Set when using phone verification (after phone number is provided).
  String? phoneAuthVerificationCode;
  // Set when using phone sign in in web mode (ignored otherwise).
  ConfirmationResult? webPhoneAuthConfirmationResult;
  // Used for handling verification codes for phone sign in.
  void Function(BuildContext)? _onCodeSent;

  bool get triggerOnCodeSent => _triggerOnCodeSent ?? false;
  set triggerOnCodeSent(bool val) => _triggerOnCodeSent = val;

  void Function(BuildContext) get onCodeSent =>
      _onCodeSent == null ? (_) {} : _onCodeSent!;
  set onCodeSent(void Function(BuildContext) func) => _onCodeSent = func;

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}

class FirebaseAuthManager extends AuthManager
    with
        EmailSignInManager,
        GoogleSignInManager,
        AppleSignInManager,
        AnonymousSignInManager,
        JwtSignInManager,
        GithubSignInManager,
        PhoneSignInManager {
  // Set when using phone verification (after phone number is provided).
  String? _phoneAuthVerificationCode;
  // Set when using phone sign in in web mode (ignored otherwise).
  ConfirmationResult? _webPhoneAuthConfirmationResult;
  FirebasePhoneAuthManager phoneAuthManager = FirebasePhoneAuthManager();

  @override
  Future signOut() {
    return FirebaseAuth.instance.signOut();
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        print('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Too long since most recent sign in. Sign in again before deleting your account.')),
        );
      }
    }
  }

  @override
  Future<void> updateEmail(
    BuildContext context,
    String email,
  ) async {
    try {
      if (!loggedIn) {
        print('Error: update email attempted with no logged in user!');
        return;
      }
      await currentUser?.updateEmail(email);
      await updateUserDocument(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Too long since most recent sign in. Sign in again before updating your email.')),
        );
      }
    }
  }

  @override
  Future<void> updatePassword(
    BuildContext context,
    String password,
  ) async {
    try {
      if (!loggedIn) {
        print('Error: update password attempted with no logged in user!');
        return;
      }
      await currentUser?.updatePassword(password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message!}')),
        );
      }
    }
  }

  @override
  Future<void> resetPassword(
    BuildContext context,
    String email,
  ) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message!}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset email sent')),
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  @override
  Future<void> refreshUser() async {
    await currentUser?.refreshUser();
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailSignInFunc(email, password),
        'EMAIL',
      );

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailCreateAccountFunc(email, password),
        'EMAIL',
      );

  @override
  Future<BaseAuthUser?> signInAnonymously(
    BuildContext context,
  ) =>
      _signInOrCreateAccount(context, anonymousSignInFunc, 'ANONYMOUS');

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) {
    // Use our improved Google Sign-In function that handles errors better
    return _signInOrCreateAccount(
        context, () => handleGoogleSignIn(context), 'GOOGLE');
  }

  @override
  Future<BaseAuthUser?> signInWithApple(BuildContext context) {
    return _signInOrCreateAccount(
        context, () => handleAppleSignIn(context), 'APPLE');
  }

  @override
  Future<BaseAuthUser?> signInWithGithub(BuildContext context) =>
      _signInOrCreateAccount(context, githubSignInFunc, 'GITHUB');

  @override
  Future<BaseAuthUser?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  ) =>
      _signInOrCreateAccount(context, () => jwtTokenSignIn(jwtToken), 'JWT');

  void handlePhoneAuthStateChanges(BuildContext context) {
    phoneAuthManager.addListener(() {
      if (!context.mounted) {
        return;
      }

      if (phoneAuthManager.triggerOnCodeSent) {
        phoneAuthManager.onCodeSent(context);
        phoneAuthManager
            .update(() => phoneAuthManager.triggerOnCodeSent = false);
      } else if (phoneAuthManager.phoneAuthError != null) {
        final e = phoneAuthManager.phoneAuthError!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message!}'),
        ));
        phoneAuthManager.update(() => phoneAuthManager.phoneAuthError = null);
      }
    });
  }

  @override
  Future beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  }) async {
    phoneAuthManager.update(() => phoneAuthManager.onCodeSent = onCodeSent);
    if (kIsWeb) {
      phoneAuthManager.webPhoneAuthConfirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
      phoneAuthManager.update(() => phoneAuthManager.triggerOnCodeSent = true);
      return;
    }
    final completer = Completer<bool>();
    // If you'd like auto-verification, without the user having to enter the SMS
    // code manually. Follow these instructions:
    // * For Android: https://firebase.google.com/docs/auth/android/phone-auth?authuser=0#enable-app-verification (SafetyNet set up)
    // * For iOS: https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0#start-receiving-silent-notifications
    // * Finally modify verificationCompleted below as instructed.
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout:
          Duration(seconds: 0), // Skips Android's default auto-verification
      verificationCompleted: (phoneAuthCredential) async {
        await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
        phoneAuthManager.update(() {
          phoneAuthManager.triggerOnCodeSent = false;
          phoneAuthManager.phoneAuthError = null;
        });
        // If you've implemented auto-verification, navigate to home page or
        // onboarding page here manually. Uncomment the lines below and replace
        // DestinationPage() with the desired widget.
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => DestinationPage()),
        // );
      },
      verificationFailed: (e) {
        phoneAuthManager.update(() {
          phoneAuthManager.triggerOnCodeSent = false;
          phoneAuthManager.phoneAuthError = e;
        });
        completer.complete(false);
      },
      codeSent: (verificationId, _) {
        phoneAuthManager.update(() {
          phoneAuthManager.phoneAuthVerificationCode = verificationId;
          phoneAuthManager.triggerOnCodeSent = true;
          phoneAuthManager.phoneAuthError = null;
        });
        completer.complete(true);
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  @override
  Future verifySmsCode({
    required BuildContext context,
    required String smsCode,
  }) {
    if (kIsWeb) {
      return _signInOrCreateAccount(
        context,
        () => phoneAuthManager.webPhoneAuthConfirmationResult!.confirm(smsCode),
        'PHONE',
      );
    } else {
      final authCredential = PhoneAuthProvider.credential(
        verificationId: phoneAuthManager.phoneAuthVerificationCode!,
        smsCode: smsCode,
      );
      return _signInOrCreateAccount(
        context,
        () => FirebaseAuth.instance.signInWithCredential(authCredential),
        'PHONE',
      );
    }
  }

  /// Tries to sign in or create an account using Firebase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<UserCredential?> Function() signInFunc,
    String authProvider,
  ) async {
    // Track retry attempts
    int attempts = 0;
    const int maxRetries = 2;

    while (attempts <= maxRetries) {
      try {
        final userCredential = await signInFunc();
        if (userCredential?.user != null) {
          await maybeCreateUser(userCredential!.user!);
        }
        return userCredential == null
            ? null
            : LunaKraftFirebaseUser.fromUserCredential(userCredential);
      } on FirebaseAuthException catch (e) {
        // Check if this is an App Check error
        if (isAppCheckError(e) && attempts < maxRetries) {
          debugPrint(
              'App Check error during authentication (attempt ${attempts + 1}): ${e.message}');
          attempts++;

          // Add a short delay between retries
          await Future.delayed(Duration(milliseconds: 800 * attempts));

          // Try to refresh App Check token if possible
          try {
            await FirebaseAppCheck.instance.getToken(true);
            debugPrint('Forced App Check token refresh for retry attempt');
          } catch (tokenError) {
            debugPrint('Failed to refresh App Check token: $tokenError');
          }

          // Continue to next retry attempt
          continue;
        }

        // Not an App Check error or we've exhausted retries
        final errorMsg = switch (e.code) {
          'email-already-in-use' =>
            'Error: The email is already in use by a different account',
          'INVALID_LOGIN_CREDENTIALS' =>
            'Error: The supplied auth credential is incorrect, malformed or has expired',
          _ => 'Error: ${e.message!}',
        };

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
        return null;
      } catch (e) {
        // General error handling
        debugPrint('Unexpected error during authentication: $e');

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: An unexpected error occurred. Please try again.')),
        );
        return null;
      }
    }

    // If we exhausted all retries
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Authentication failed after multiple attempts. Please try again later.')),
    );
    return null;
  }

  bool isAppCheckError(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('app check') ||
        errorString.contains('app-check') ||
        errorString.contains('appcheck') ||
        errorString.contains('attestation') ||
        errorString.contains('token') ||
        errorString.contains('permission-denied') ||
        errorString.contains('permission denied') ||
        (errorString.contains('403') && errorString.contains('forbidden'));
  }

  Future<T?> retryOnAppCheckError<T>({
    required Future<T> Function() operation,
    int maxRetries = 2,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        print('Operation attempt $attempts failed: $e');

        if (isAppCheckError(e) && attempts < maxRetries) {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * attempts));
          print('Retrying operation after App Check error...');
          continue;
        }

        // If not an App Check error or final attempt, rethrow
        rethrow;
      }
    }

    return null;
  }
}
