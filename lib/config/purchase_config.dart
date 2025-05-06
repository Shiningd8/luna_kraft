import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// This is a placeholder for the PurchaseConfig
// The implementation has been temporarily removed and will be re-implemented from scratch
class PurchaseConfig {
  // Coin product IDs from Google Play Console
  static const String coins100 = 'lunacoin_100';
  static const String coins500 = 'lunacoin_500';
  static const String coins1000 = 'lunacoin_1000';

  // Subscription product IDs - these match the IDs from the screenshots
  static const String membershipWeekly = 'premium_weekly';
  static const String membershipMonthly = 'premium_monthly';
  static const String membershipYearly = 'premium_yearly';

  // Offering types
  static const String coinsOffering = 'coins';
  static const String membershipOffering = 'premium';

  // Get the platform-specific product ID
  static String getProductId(String baseId) {
    // For Google Play, we keep the same ID
    if (Platform.isAndroid) {
      return baseId;
    }

    // For iOS, prefix with 'ios.'
    if (Platform.isIOS) {
      return 'ios.$baseId';
    }

    // Default case
    return baseId;
  }
}
