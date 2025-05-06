import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'subscription_service.dart';
import 'models/subscription_product.dart';
import 'coin_service.dart';
import 'models/coin_product.dart';

// This is a placeholder for the PurchaseService
// The implementation has been temporarily removed and will be re-implemented from scratch
class PurchaseService {
  // Initialize the purchase service
  static Future<void> init() async {
    try {
      debugPrint('PurchaseService.init(): Initializing');
      await SubscriptionService.instance.init();
      await CoinService.instance.init();
      debugPrint('PurchaseService.init(): Service initialized successfully');
    } catch (e) {
      debugPrint('PurchaseService.init(): Error initializing service - $e');
    }
  }

  // Get available coin products
  static Future<List<CoinProduct>> getCoinProducts() async {
    try {
      debugPrint('PurchaseService.getCoinProducts(): Fetching coin products');

      // Make sure the service is initialized
      if (!CoinService.instance.isLoading &&
          CoinService.instance.availableProducts.isEmpty) {
        await CoinService.instance.init();
      }

      final products = CoinService.instance.availableProducts;
      debugPrint(
          'PurchaseService.getCoinProducts(): Retrieved ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('PurchaseService.getCoinProducts(): Error - $e');
      return [];
    }
  }

  // Get available membership products
  static Future<List<SubscriptionProduct>> getMembershipProducts() async {
    try {
      debugPrint('PurchaseService.getMembershipProducts(): Fetching products');

      // Make sure the service is initialized
      if (!SubscriptionService.instance.isLoading &&
          SubscriptionService.instance.availableProducts.isEmpty) {
        await SubscriptionService.instance.init();
      }

      final products = SubscriptionService.instance.availableProducts;
      debugPrint(
          'PurchaseService.getMembershipProducts(): Retrieved ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('PurchaseService.getMembershipProducts(): Error - $e');
      return [];
    }
  }

  // Purchase a product
  static Future<PurchaseResult> purchaseProduct(dynamic product) async {
    try {
      debugPrint('PurchaseService.purchaseProduct(): Starting purchase flow');

      if (product is SubscriptionProduct) {
        final result =
            await SubscriptionService.instance.purchaseSubscription(product);

        return PurchaseResult(
          success: result.success,
          isMembership: true,
          entitlements: result.success ? [product.id] : null,
          message: result.message,
        );
      } else if (product is CoinProduct) {
        final result = await CoinService.instance.purchaseCoins(product);

        return PurchaseResult(
          success: result.success,
          isMembership: false,
          coinAmount: product.amount,
          message: result.message,
        );
      } else {
        debugPrint('PurchaseService.purchaseProduct(): Unknown product type');
        return PurchaseResult(
          success: false,
          message: 'Unknown product type',
        );
      }
    } catch (e) {
      debugPrint('PurchaseService.purchaseProduct(): Error - $e');
      return PurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Restore previous purchases
  static Future<List<PurchaseResult>> restorePurchases() async {
    try {
      debugPrint('PurchaseService.restorePurchases(): Restoring purchases');

      final results = await SubscriptionService.instance.restorePurchases();

      return results
          .map((result) => PurchaseResult(
                success: result.success,
                isMembership: true,
                entitlements: result.success ? [result.productId!] : null,
                message: result.message,
              ))
          .toList();
    } catch (e) {
      debugPrint('PurchaseService.restorePurchases(): Error - $e');
      return [
        PurchaseResult(
          success: false,
          message: 'Error: $e',
        )
      ];
    }
  }

  // Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      return await SubscriptionService.instance.hasActiveSubscription();
    } catch (e) {
      debugPrint('PurchaseService.hasActiveSubscription(): Error - $e');
      return false;
    }
  }

  // Dispose resources
  static void dispose() {
    SubscriptionService.instance.dispose();
    CoinService.instance.dispose();
    debugPrint('PurchaseService.dispose(): Resources disposed');
  }

  // Run connectivity diagnostics
  static Future<Map<String, dynamic>> runConnectivityDiagnostics() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isSubInitialized =
          SubscriptionService.instance.availableProducts.isNotEmpty;
      final isCoinInitialized =
          CoinService.instance.availableProducts.isNotEmpty;

      return {
        'connectivityStatus': connectivityResult.toString(),
        'hasActiveConnection': connectivityResult != ConnectivityResult.none,
        'isSubscriptionInitialized': isSubInitialized,
        'isCoinInitialized': isCoinInitialized,
        'isInDebugMode': kDebugMode,
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'subscriptionProductsLoaded':
            SubscriptionService.instance.availableProducts.length,
        'coinProductsLoaded': CoinService.instance.availableProducts.length,
        'domainTests': {},
      };
    } catch (e) {
      debugPrint('PurchaseService.runConnectivityDiagnostics(): Error - $e');
      return {
        'error': e.toString(),
        'isInDebugMode': kDebugMode,
      };
    }
  }
}

// Purchase result
class PurchaseResult {
  final bool success;
  final bool isMembership;
  final int? coinAmount;
  final List<String>? entitlements;
  final String? message;

  PurchaseResult({
    required this.success,
    this.isMembership = false,
    this.coinAmount,
    this.entitlements,
    this.message,
  });
}
