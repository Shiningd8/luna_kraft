import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp/otp.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:page_transition/page_transition.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'firebase_app_check_stub.dart';
import 'dart:io';

import '/backend/backend.dart';
import '/services/app_state.dart';
import '/flutter_flow/app_state.dart';
import 'package:stream_transform/stream_transform.dart';
import 'firebase_auth_manager.dart';
import 'google_auth.dart';
import 'firebase_user_provider.dart';

export 'firebase_auth_manager.dart';

final _authManager = FirebaseAuthManager();
FirebaseAuthManager get authManager => _authManager;

String get currentUserEmail =>
    currentUserDocument?.email ?? currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName =>
    currentUserDocument?.displayName ?? currentUser?.displayName ?? '';

String get currentUserPhoto {
  String photoUrl =
      currentUserDocument?.photoUrl ?? currentUser?.photoUrl ?? '';

  if (photoUrl.isEmpty) {
    // Return a default avatar URL if no photo is available
    String initial = currentUserDisplayName.isNotEmpty
        ? currentUserDisplayName[0].toUpperCase()
        : 'U';
    return 'https://ui-avatars.com/api/?name=$initial&background=random&size=256';
  }

  // For Firebase Storage URLs with potential CORS issues, use UI Avatars instead
  if (photoUrl.contains('firebasestorage.googleapis.com')) {
    print('PHOTO URL DEBUG (Firebase Storage detected): $photoUrl');
    print('CORS issues might occur - defaulting to avatar URL');

    String initial = currentUserDisplayName.isNotEmpty
        ? currentUserDisplayName[0].toUpperCase()
        : 'U';
    return 'https://ui-avatars.com/api/?name=$initial&background=random&size=256';
  }

  // For ui-avatars URLs, they're already safe to use
  if (photoUrl.contains('ui-avatars.com')) {
    print('PHOTO URL DEBUG (avatar URL): $photoUrl');
    return photoUrl;
  }

  // For any other URL type
  return photoUrl;
}

String get currentPhoneNumber =>
    currentUserDocument?.phoneNumber ?? currentUser?.phoneNumber ?? '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .map((user) async => _currentJwtToken = await user?.getIdToken())
    .asBroadcastStream();

DocumentReference? get currentUserReference =>
    loggedIn ? UserRecord.collection.doc(currentUser!.uid) : null;

UserRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap(
      (uid) => uid.isEmpty
          ? Stream.value(null)
          : UserRecord.getDocument(UserRecord.collection.doc(uid))
              .handleError((_) {}),
    )
    .map((user) {
  currentUserDocument = user;

  return currentUserDocument;
}).asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({Key? key, required this.builder})
      : super(key: key);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => builder(context),
      );
}

class AuthUtil {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
    int retryCount = 0,
  }) async {
    try {
      // Check if App Check is skipped in debug mode
      final isAppCheckSkipped = await _isAppCheckSkipped();
      if (isAppCheckSkipped) {
        print('App Check is skipped - using custom auth approach');
      }

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (_isNetworkError(e) && retryCount < _maxRetries) {
        // Add a short delay before retrying
        await Future.delayed(_retryDelay);
        return signInWithEmailAndPassword(
          email: email,
          password: password,
          retryCount: retryCount + 1,
        );
      }

      // Handle App Check related errors more gracefully
      if (_isAppCheckError(e)) {
        debugPrint(
            'App Check related error - retrying with strategy: ${e.message}');

        // Check if App Check was skipped
        final isAppCheckSkipped = await _isAppCheckSkipped();
        if (isAppCheckSkipped && retryCount < _maxRetries) {
          // For App Check errors in debug mode with the flag set,
          // we can try a special approach if needed
          debugPrint(
              'Attempting auth retry with App Check workaround (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 3));
          return signInWithEmailAndPassword(
            email: email,
            password: password,
            retryCount: retryCount + 1,
          );
        }
      }

      _handleAuthException(e);
      rethrow;
    }
  }

  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    int retryCount = 0,
  }) async {
    try {
      // Check if App Check is skipped in debug mode
      final isAppCheckSkipped = await _isAppCheckSkipped();
      if (isAppCheckSkipped) {
        print(
            'App Check is skipped - using custom auth approach for registration');
      }

      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (_isNetworkError(e) && retryCount < _maxRetries) {
        // Add a short delay before retrying
        await Future.delayed(_retryDelay);
        return createUserWithEmailAndPassword(
          email: email,
          password: password,
          retryCount: retryCount + 1,
        );
      }

      // Handle App Check related errors more gracefully
      if (_isAppCheckError(e)) {
        debugPrint(
            'App Check related error during registration - retrying: ${e.message}');

        // Check if App Check was skipped
        final isAppCheckSkipped = await _isAppCheckSkipped();
        if (isAppCheckSkipped && retryCount < _maxRetries) {
          debugPrint(
              'Attempting registration retry with App Check workaround (attempt ${retryCount + 1})');
          await Future.delayed(Duration(seconds: 3));
          return createUserWithEmailAndPassword(
            email: email,
            password: password,
            retryCount: retryCount + 1,
          );
        }
      }

      _handleAuthException(e);
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (_isNetworkError(e)) {
        // For sign out, we can ignore network errors as the user is already signed out locally
        debugPrint('Network error during sign out: ${e.message}');
      } else {
        _handleAuthException(e);
      }
    }
  }

  static Future<void> resetPassword({
    required String email,
    int retryCount = 0,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (_isNetworkError(e) && retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return resetPassword(
          email: email,
          retryCount: retryCount + 1,
        );
      }
      _handleAuthException(e);
      rethrow;
    }
  }

  static bool _isNetworkError(FirebaseAuthException e) {
    return e.code == 'network-request-failed' ||
        e.code == 'timeout' ||
        e.code == 'too-many-requests';
  }

  static void _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'timeout':
        message = 'Request timed out. Please try again.';
        break;
      default:
        message = e.message ?? 'An error occurred. Please try again.';
    }
    debugPrint('Firebase Auth Error: ${e.code} - $message');
    throw FirebaseAuthException(
      code: e.code,
      message: message,
    );
  }

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // A completely isolated sign-out method that can be called from anywhere
  static Future<void> signOutSafely() async {
    try {
      debugPrint('Starting minimal sign-out process');

      // Just sign out from Firebase - nothing else
      await _auth.signOut();

      // Let the auth state change listener handle navigation
      debugPrint(
          'Sign-out complete - Firebase auth state listener will handle navigation');
    } catch (e) {
      debugPrint('Error in signOutSafely: $e');
    }
  }

  // Safe sign out method that avoids scaffold messenger deactivation issues
  static Future<void> safeSignOut({
    required BuildContext context,
    bool shouldNavigate = true,
    String? navigateTo,
  }) async {
    // Create a completer to ensure we only continue when logout is complete
    final completer = Completer<void>();

    try {
      // First sign out from Firebase without any navigation
      await signOutSafely();

      // Wait a moment for auth state to update
      await Future.delayed(Duration(milliseconds: 300));

      // Get navigation references if needed and if context is still valid
      GoRouter? router;
      if (shouldNavigate && context.mounted) {
        try {
          router = GoRouter.of(context);
        } catch (e) {
          debugPrint('Error getting GoRouter: $e');
        }
      }

      // Cleanup app state if available and if context is still valid
      if (context.mounted) {
        try {
          final appState = Provider.of<AppState>(context, listen: false);
          await appState.cleanup();
        } catch (e) {
          debugPrint('Error cleaning up AppState: $e');
        }
      }

      // Clear FFAppState
      try {
        await FFAppState().initializePersistedState();
      } catch (e) {
        debugPrint('Error initializing app state: $e');
      }

      // Navigation should be the last step, and only if requested and context is still valid
      if (shouldNavigate && router != null && context.mounted) {
        // Use a microtask to ensure navigation happens after all other processing
        Future.microtask(() {
          try {
            // Use go() instead of context.pushNamed to avoid navigation conflicts
            router?.go(navigateTo ?? '/');
            completer.complete();
          } catch (e) {
            debugPrint('Error during navigation after sign out: $e');
            completer.completeError(e);
          }
        });
      } else {
        completer.complete();
      }

      return completer.future;
    } catch (e) {
      debugPrint('Error during safe sign out: $e');
      completer.completeError(e);
      return completer.future;
    }
  }

  // Function to check if 2FA is enabled for the current user
  static Future<bool> isTwoFactorEnabled() async {
    try {
      // Check if a user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Get the user's document from Firestore
      final userDoc =
          await UserRecord.getDocumentOnce(UserRecord.collection.doc(user.uid));
      return userDoc.is2FAEnabled;
    } catch (e) {
      print('Error checking 2FA status: $e');
      return false;
    }
  }

  // Function to verify a TOTP 2FA code
  static Future<bool> verifyTwoFactorCode(String code) async {
    try {
      if (code.length != 6) {
        return false;
      }

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Get the user's document from Firestore
      final userDoc =
          await UserRecord.getDocumentOnce(UserRecord.collection.doc(user.uid));
      final secretKey = userDoc.twoFactorSecretKey;

      if (secretKey.isEmpty) {
        return false;
      }

      // Generate TOTP code with the current time
      final now = DateTime.now().millisecondsSinceEpoch;
      final currentCode = OTP.generateTOTPCodeString(
        secretKey,
        now,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      // Check if the entered code matches the current code
      if (code == currentCode) {
        return true;
      }

      // Try with adjacent time windows to account for timing differences
      for (int i = -1; i <= 1; i++) {
        if (i == 0) continue; // Skip the current time as we already checked it

        final adjustedTime = now + (i * 30 * 1000);
        final alternateCode = OTP.generateTOTPCodeString(
          secretKey,
          adjustedTime,
          length: 6,
          interval: 30,
          algorithm: Algorithm.SHA1,
          isGoogle: true,
        );

        if (code == alternateCode) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error verifying 2FA code: $e');
      return false;
    }
  }

  // New method to detect App Check related errors
  static bool _isAppCheckError(FirebaseAuthException e) {
    final List<String> appCheckErrorIndicators = [
      'app check',
      'app-check',
      'appcheck',
      'attestation',
      'unauthorized',
      'unauthenticated',
      'permission-denied',
      'permission denied',
      'forbidden',
      '403',
      'failed to obtain app check token',
    ];

    final errorMsg = (e.message ?? '').toLowerCase();
    return appCheckErrorIndicators
        .any((indicator) => errorMsg.contains(indicator.toLowerCase()));
  }

  // New method to check if App Check was skipped
  static Future<bool> _isAppCheckSkipped() async {
    try {
      // If we're in debug mode, we might have skipped App Check
      if (kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        final isSkipped = prefs.getBool('app_check_skipped') ?? false;
        return isSkipped;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking App Check skipped status: $e');
      return false;
    }
  }
}

// Function to handle Google Sign-In with error handling
Future<UserCredential?> handleGoogleSignIn(BuildContext context) async {
  try {
    return await googleSignInFunc();
  } on FirebaseAuthException catch (e) {
    String errorMessage = 'An error occurred during sign in.';
    String errorTitle = 'Sign In Error';
    IconData errorIcon = Icons.error_outline;

    // Handle known error codes with user-friendly messages
    if (e.code == 'google-signin-config-error') {
      errorTitle = 'Configuration Error';
      errorMessage =
          'Google Sign-In is not properly configured. Please try another sign-in method or try again later.';
      errorIcon = Icons.settings;
    } else if (e.code == 'account-exists-with-different-credential') {
      errorTitle = 'Account Exists';
      errorMessage =
          'An account already exists with the same email address but different sign-in method. Please try signing in a different way.';
      errorIcon = Icons.person;
    } else if (e.code == 'network-request-failed') {
      errorTitle = 'Network Error';
      errorMessage = 'Please check your internet connection and try again.';
      errorIcon = Icons.wifi_off;
    } else if (e.code.contains('user-disabled')) {
      errorTitle = 'Account Disabled';
      errorMessage =
          'This account has been disabled. Please contact support for help.';
      errorIcon = Icons.block;
    }

    // Show error dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              errorIcon,
                              size: 50,
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.8),
                            ),
                            SizedBox(height: 16),
                            Text(
                              errorTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              errorMessage,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return null;
  } catch (e) {
    // Handle other exceptions
    debugPrint('Unexpected error during Google Sign-In: $e');

    if (context.mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign In Error'),
            content:
                Text('An unexpected error occurred. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    return null;
  }
}

// Add a helper method to try authentication again with relaxed App Check
Future<BaseAuthUser?> retryAuthWithRelaxedAppCheck({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  try {
    // Check if we're running in debug mode with App Check skipped
    final isAppCheckSkipped = await AuthUtil._isAppCheckSkipped();

    if (isAppCheckSkipped) {
      print(
          'App Check is disabled in debug mode - proceeding with direct auth');

      // In debug mode with App Check disabled, use direct Firebase Auth
      try {
        // Directly use Firebase Auth without App Check verification
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          // Create a LunaKraftFirebaseUser from the successful auth
          return LunaKraftFirebaseUser.fromUserCredential(userCredential);
        }
      } catch (directAuthError) {
        print('Direct Firebase Auth failed in debug mode: $directAuthError');
      }
    }

    // If not in debug mode or direct auth failed, try normal path
    print('Attempting normal auth path with Auth Manager');
    return authManager.signInWithEmail(context, email, password);
  } catch (e) {
    print('Retry auth with relaxed App Check failed: $e');
    return null;
  }
}

// Update the existing method to check for App Check errors
bool isAppCheckError(String errorMessage) {
  if (errorMessage.isEmpty) return false;

  final appCheckKeywords = [
    'app-check',
    'app check',
    'appcheck',
    'token',
    'verification',
    'verify',
    'attestation',
    'attestation failed',
    'forbidden',
    'unauthorized',
    'unauthenticated',
    'permission-denied',
    'permission denied',
    '403',
  ];

  return appCheckKeywords.any(
      (keyword) => errorMessage.toLowerCase().contains(keyword.toLowerCase()));
}

Future<bool> checkUserProfileExists() async {
  try {
    if (!loggedIn || currentUser == null) {
      print('checkUserProfileExists: User not logged in');
      return false;
    }

    print(
        'checkUserProfileExists: Checking profile for user ID ${currentUser!.uid}');

    // Get the user document
    final userDoc = await UserRecord.getDocumentOnce(
        UserRecord.collection.doc(currentUser!.uid));

    // Check if the user document exists and has required profile fields completed
    if (userDoc == null) {
      print('checkUserProfileExists: User document not found');
      return false;
    }

    print('checkUserProfileExists: User document found with data:');
    print('  - displayName: ${userDoc.displayName}');
    print('  - userName: ${userDoc.userName}');

    // Check if essential profile fields are completed
    final isProfileComplete = userDoc.displayName != null &&
        userDoc.displayName!.isNotEmpty &&
        userDoc.userName != null &&
        userDoc.userName!.isNotEmpty;

    print('checkUserProfileExists: Profile is complete: $isProfileComplete');
    return isProfileComplete;
  } catch (e) {
    print('Error checking user profile: $e');
    return false;
  }
}
