import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A utility class to handle logging configuration
class LoggingConfig {
  /// Initialize logging filters to reduce noise in the debug console
  static void initialize() {
    // Only filter logs in debug mode
    if (kDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      // Set up a zone to catch and filter print statements
      runZonedGuarded(() {
        // Override print to filter out noisy logs
        debugPrint = _filteredDebugPrint;
      }, (error, stack) {
        developer.log('Error caught in runZonedGuarded:',
            error: error, stackTrace: stack);
      });
    }
  }

  /// A custom debug print function that filters out noisy logs
  static void _filteredDebugPrint(String? message, {int? wrapWidth}) {
    if (message == null) return;

    // Skip Android runtime logs and other noisy messages
    if (_shouldSkipMessage(message)) {
      return;
    }

    // Use the original debugPrint function for messages that pass the filter
    developer.log(message);
  }

  /// Determines whether a log message should be skipped
  static bool _shouldSkipMessage(String message) {
    final lowercaseMessage = message.toLowerCase();

    // Skip if error is from another process (like Google Play Services)
    if (message.contains("Process: com.google.android.gms") ||
        message.contains("E/AndroidRuntime") ||
        message.contains("FATAL EXCEPTION")) {
      return true;
    }

    // List of patterns to filter out
    final filterPatterns = [
      'flutter.gradle',
      'i/flutter',
      'w/flutter',
      'd/flutter',
      'i/firestore',
      'w/firestore',
      'e/flutter',
      'i/firebase',
      'w/firebase',
      'i/chatkit',
      'w/chatkit',
      'i/dynamiclinkssdk',
      'w/dynamiclinkssdk',
      'i/dynamiclinks',
      'w/dynamiclinks',
      'i/databaseclient',
      'w/databaseclient',
      'late-enabling profile',
      'v/syncutils',
      'i/googleapiauth',
      'w/googleapiauth',
      'syncutils',
      'art_jni',
      'art runtime',
      'i/art',
      'd/art',
      'choreo',
      'dalvikvm',
      'libc',
      'androidruntime',
      'i/adrequest',
      'i/firebaseinappmessaging',
      'i/firebaseinstallations',
      'i/firebaseiid',
      'i/skia',
      'w/skia',
      'gl finalization',
      'libems',
      'i/libems',
      'w/libems',
      'i/system/hwcomposer',
      'i/system',
      'eglrenderer',
      'i/mali',
      'i/mali_so',
      'w/mali',
      'audio_hw_primary',
      'binder',
      'unity',
      'vsnapshot',
      'isolate',
      'instrumentation',
      // Added for Google Play Services specific errors
      'e/androidruntime',
      'networkCapability',
      'IllegalArgumentException',
      'handleBindService',
      'gms.persistent',
      'google.android.gms',
      'firebase',
      'fcm',
      'zygoteinit',
      'at dagger.internal',
      'at com.google.android',
      'push',
      'messaging',
      'runtimeexception',
      'at android.'
    ];

    // Check if the message contains any of the patterns to be filtered
    return filterPatterns.any((pattern) => lowercaseMessage.contains(pattern));
  }
}
