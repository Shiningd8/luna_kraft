import 'package:flutter/services.dart';

/// AdMobService provides a wrapper for native AdMob implementation
/// This service communicates with the native Swift code via method channels
class AdMobService {
  static const MethodChannel _channel = MethodChannel('com.flutterflow.lunakraft/admob');
  
  /// Singleton instance
  static final AdMobService _instance = AdMobService._internal();
  
  /// Factory constructor to return the singleton instance
  factory AdMobService() => _instance;
  
  /// Private constructor
  AdMobService._internal();
  
  /// Loads an interstitial ad
  Future<bool> loadInterstitialAd() async {
    try {
      final result = await _channel.invokeMethod<bool>('loadInterstitialAd');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error loading interstitial ad: ${e.message}');
      return false;
    }
  }
  
  /// Shows an interstitial ad if one is loaded
  Future<bool> showInterstitialAd() async {
    try {
      final result = await _channel.invokeMethod<bool>('showInterstitialAd');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error showing interstitial ad: ${e.message}');
      return false;
    }
  }
  
  /// Loads a rewarded ad
  Future<bool> loadRewardedAd() async {
    try {
      final result = await _channel.invokeMethod<bool>('loadRewardedAd');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error loading rewarded ad: ${e.message}');
      return false;
    }
  }
  
  /// Shows a rewarded ad if one is loaded
  /// Returns a Map with 'success' and 'amount' keys
  Future<Map<String, dynamic>> showRewardedAd() async {
    try {
      final result = await _channel.invokeMethod<Map>('showRewardedAd');
      return Map<String, dynamic>.from(result ?? {'success': false, 'amount': 0});
    } on PlatformException catch (e) {
      print('Error showing rewarded ad: ${e.message}');
      return {'success': false, 'amount': 0};
    }
  }
} 