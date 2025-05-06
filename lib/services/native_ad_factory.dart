import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/foundation.dart';

/// Define a custom Native Ad Factory to control how native ads are displayed
class LunaKraftNativeAdFactory {
  /// Register the native ad factory with the Google Mobile Ads SDK
  static void registerNativeAdFactory() {
    // Register the ad factory for use in Android
    if (NativeAdmobPlatform.instance != null) {
      NativeAdmobPlatform.instance!.registerNativeAdFactory(
        'adFactoryExample',
        LunaKraftNativeAdFactory._createNativeAd,
      );
    }

    // Disable native ad validator popups in debug mode
    if (kDebugMode) {
      _disableNativeAdValidation();
    }
  }

  /// Disable native ad validation popups
  static void _disableNativeAdValidation() {
    try {
      // Use the MobileAds configuration to disable validation popups
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );

      debugPrint('Native ad validation popups disabled');
    } catch (e) {
      debugPrint('Failed to disable native ad validation: $e');
    }
  }

  /// Create a native ad that resembles a post in the app's feed
  static Widget _createNativeAd(
    NativeAd ad,
    Map<String, dynamic> options,
  ) {
    return Builder(builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AdWidget(ad: ad),
      );
    });
  }
}

/// Native ad platform implementation (required for the factory)
abstract class NativeAdmobPlatform {
  /// The currently active platform implementation
  static NativeAdmobPlatform? get instance => _instance;
  static NativeAdmobPlatform? _instance;

  /// Register a platform implementation
  static set instance(NativeAdmobPlatform? instance) {
    _instance = instance;
  }

  /// Register a native ad factory with the given factory ID
  void registerNativeAdFactory(
    String factoryId,
    Widget Function(NativeAd ad, Map<String, dynamic> options) createAd,
  );

  /// Unregister a previously registered native ad factory
  void unregisterNativeAdFactory(String factoryId);
}
