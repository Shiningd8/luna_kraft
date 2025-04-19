import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../config/purchase_config.dart';

class PurchaseService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    // Configure debug logs
    await Purchases.setLogLevel(LogLevel.debug);

    // Initialize RevenueCat with platform-specific API key
    final apiKey = Platform.isIOS
        ? PurchaseConfig.revenueCatApiKeyIOS
        : PurchaseConfig.revenueCatApiKeyAndroid;

    await Purchases.configure(
      PurchasesConfiguration(apiKey),
    );

    _isInitialized = true;
  }

  // Fetch coin packages
  static Future<List<Package>> getCoinPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(PurchaseConfig.coinsOffering);
      if (offering != null) {
        return offering.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching coin packages: $e');
      return [];
    }
  }

  // Fetch membership packages
  static Future<List<Package>> getMembershipPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(PurchaseConfig.membershipOffering);
      if (offering != null) {
        return offering.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching membership packages: $e');
      return [];
    }
  }

  // Purchase a package
  static Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      final activeEntitlements = purchaseResult.entitlements.active;

      // For membership purchases, verify entitlements
      if (package.storeProduct.identifier.contains('membership')) {
        final hasPremium =
            activeEntitlements[PurchaseConfig.premiumEntitlement]?.isActive ??
                false;
        return PurchaseResult(
          success: hasPremium,
          isMembership: true,
          entitlements: activeEntitlements.keys.toList(),
        );
      }

      // For coin purchases
      return PurchaseResult(
        success: true,
        isMembership: false,
        coinAmount:
            _getCoinAmountFromProductId(package.storeProduct.identifier),
      );
    } catch (e) {
      debugPrint('Error making purchase: $e');
      return PurchaseResult(success: false);
    }
  }

  // Helper method to get coin amount from product ID
  static int _getCoinAmountFromProductId(String productId) {
    if (productId == PurchaseConfig.coins100) return 100;
    if (productId == PurchaseConfig.coins500) return 500;
    if (productId == PurchaseConfig.coins1000) return 1000;
    return 0;
  }

  // Check if user has specific entitlement
  static Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking entitlement: $e');
      return false;
    }
  }

  // Get all active entitlements
  static Future<List<String>> getActiveEntitlements() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.keys.toList();
    } catch (e) {
      debugPrint('Error getting active entitlements: $e');
      return [];
    }
  }

  // Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  // Update user identifier
  static Future<void> updateUserIdentifier(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('Error updating user identifier: $e');
    }
  }
}

// Class to handle purchase results
class PurchaseResult {
  final bool success;
  final bool isMembership;
  final List<String>? entitlements;
  final int? coinAmount;

  PurchaseResult({
    required this.success,
    this.isMembership = false,
    this.entitlements,
    this.coinAmount,
  });
}
