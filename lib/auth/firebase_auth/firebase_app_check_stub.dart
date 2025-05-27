// Stub implementation for firebase_app_check
// This provides enough of the API to prevent compile errors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseAppCheck {
  static FirebaseAppCheck get instance => _instance;
  static final FirebaseAppCheck _instance = FirebaseAppCheck._();
  FirebaseAppCheck._();

  Future<void> activate({
    String? webRecaptchaSiteKey,
    bool androidProvider = false,
    String? appleProvider,
    bool androidDebugProvider = false,
    String? appleDebugProvider,
    ReCaptchaV3Provider? webProvider,
  }) async {
    debugPrint('[STUB] FirebaseAppCheck.activate() called');
    return;
  }

  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled) async {
    debugPrint('[STUB] FirebaseAppCheck.setTokenAutoRefreshEnabled() called');
    return;
  }

  Future<AppCheckToken> getToken([bool forceRefresh = false]) async {
    debugPrint('[STUB] FirebaseAppCheck.getToken() called');
    return AppCheckToken(token: 'stub-token', expireTimeMillis: 0);
  }
}

class AppCheckToken {
  AppCheckToken({required this.token, required this.expireTimeMillis});
  final String token;
  final int expireTimeMillis;
}

class AppleProvider {
  const AppleProvider();
  
  static const deviceCheck = 'deviceCheck';
  static const appAttest = 'appAttest';
  static const debug = 'debug';
}

class AndroidProvider {
  const AndroidProvider.playIntegrity();
  const AndroidProvider.debug();
  const AndroidProvider.safetyNet();
  
  static const String kPlayIntegrity = 'playIntegrity';
  static const String kDebug = 'debug';
  static const String kSafetyNet = 'safetyNet';
}

class ReCaptchaV3Provider {
  final String siteKey;
  const ReCaptchaV3Provider(this.siteKey);
}

// Additional stub classes if needed
class AppCheckProvider {} 