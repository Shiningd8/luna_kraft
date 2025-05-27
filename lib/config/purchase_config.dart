import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// This is a placeholder for the PurchaseConfig
// The implementation has been temporarily removed and will be re-implemented from scratch
class PurchaseConfig {
  // Coin product IDs from Google Play Console
  static const String coins100 = 'ios.lunacoin_100';
  static const String coins500 = 'ios.lunacoin_500';
  static const String coins1000 = 'ios.lunacoin_1000';

  // Subscription product IDs - these match the IDs from the screenshots
  static const String membershipWeekly = 'ios.premium_weekly_sub';
  static const String membershipMonthly = 'ios.premium_monthly';
  static const String membershipYearly = 'ios.premium_yearly';

  // Offering types
  static const String coinsOffering = 'coins';
  static const String membershipOffering = 'premium';

  // Get the platform-specific product ID
  static String getProductId(String baseId) {
    // Since iOS product IDs already include 'ios.' prefix, we just return the ID as is
    return baseId;
  }
}
