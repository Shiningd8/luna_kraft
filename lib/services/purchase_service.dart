import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'models/subscription_product.dart';
import 'models/coin_product.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/subscription_manager.dart';

/// Result class for subscription purchases
class PurchaseResult {
  final bool success;
  final String? message;
  final String? productId;
  final String? purchaseId;

  PurchaseResult({
    required this.success,
    this.message,
    this.productId,
    this.purchaseId,
  });
}

/// A platform-specific purchase service that uses RevenueCat for both iOS and Android
class PurchaseService {
  // Private constructor to prevent direct instantiation
  PurchaseService._();

  // Initialize RevenueCat
  static Future<void> init() async {
    try {
      // Check if we're already configured to avoid double initialization
      bool isConfigured = false;
      try {
        // If this doesn't throw, we're already configured
        final customerInfo = await Purchases.getCustomerInfo();
        debugPrint('RevenueCat appears to be already configured - reusing existing configuration');
        isConfigured = true;
      } catch (_) {
        debugPrint('RevenueCat does not appear to be configured yet');
      }
      
      if (!isConfigured) {
        // Use your actual RevenueCat API key for iOS
        const apiKey = 'appl_aUbICkbeGteMFoiMsBOJzdjVoTE';
        debugPrint('Using RevenueCat API key: $apiKey');
        
        // Check if we're in debug mode
        if (kDebugMode) {
          debugPrint('🔧 Initializing RevenueCat in DEBUG mode');
        }
        
        // Additional configuration for more reliable behavior in TestFlight
        final purchasesConfig = PurchasesConfiguration(apiKey);
        
        // Configure RevenueCat with the enhanced configuration
        await Purchases.configure(purchasesConfig);
        
        // Wait a moment to ensure configuration is complete
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Set user ID if available
      if (currentUserDocument != null) {
        debugPrint('Setting RevenueCat user ID: ${currentUserUid}');
        await Purchases.logIn(currentUserUid);
      }
      
      // Sync offerings after initialization
      await syncProducts();
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
      // Try a fallback approach for TestFlight if normal init fails
      try {
        if (!kDebugMode) {
          const apiKeyVal = 'appl_aUbICkbeGteMFoiMsBOJzdjVoTE';
          debugPrint('Attempting fallback initialization for TestFlight...');
          final purchasesConfig = PurchasesConfiguration(apiKeyVal);
          await Purchases.configure(purchasesConfig);
        }
      } catch (fallbackError) {
        debugPrint('Fallback initialization also failed: $fallbackError');
      }
    }
  }

  // Sync products from RevenueCat server
  static Future<void> syncProducts() async {
    try {
      debugPrint('Syncing products from RevenueCat server...');
      // Force a fresh fetch from the server with retry
      Offerings? offerings;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (offerings == null && retryCount < maxRetries) {
        try {
          offerings = await Purchases.getOfferings();
          if (offerings.current == null && offerings.all.isEmpty) {
            debugPrint('Empty offerings returned, retrying... (${retryCount + 1}/$maxRetries)');
            offerings = null;
            retryCount++;
            await Future.delayed(Duration(seconds: 2 * retryCount)); // Increasing backoff
          }
        } catch (e) {
          debugPrint('Error fetching offerings, retrying... (${retryCount + 1}/$maxRetries): $e');
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }
      
      if (offerings == null) {
        debugPrint('WARNING: Failed to fetch offerings after $maxRetries attempts');
        return;
      }
      
      debugPrint('Products synced successfully. Found ${offerings.all.length} offerings');
      
      if (offerings.all.isEmpty) {
        debugPrint('WARNING: No offerings available from RevenueCat');
      } else {
        offerings.all.forEach((id, offering) {
          debugPrint('Offering: $id with ${offering.availablePackages.length} packages');
        });
      }
    } catch (e) {
      debugPrint('Error syncing products: $e');
    }
  }

  // Get subscription products
  static Future<List<SubscriptionProduct>> getMembershipProducts() async {
    try {
      // In simulator mode, return mock data
      if (isSimulatorMode) {
        debugPrint('🔧 SIMULATOR MODE: Returning mock subscription products');
        return [
          SubscriptionProduct(
            id: 'ios.premium_weekly_sub',
            title: 'Weekly Premium',
            description: 'Weekly subscription with premium features',
            price: '\$0.99',
            rawPrice: '0.99',
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
          SubscriptionProduct(
            id: 'ios.premium_monthly',
            title: 'Monthly Premium',
            description: 'Monthly subscription with premium features',
            price: '\$3.99',
            rawPrice: '3.99',
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
          SubscriptionProduct(
            id: 'ios.premium_yearly',
            title: 'Yearly Premium',
            description: 'Yearly subscription with all premium features',
            price: '\$29.99',
            rawPrice: '29.99',
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
        ];
      }
      
      final offerings = await Purchases.getOfferings();
      debugPrint('Loaded offerings: ${offerings.all.keys.join(', ')}');
      
      // Detailed debug logging
      offerings.all.forEach((id, offering) {
        debugPrint('Offering: $id with ${offering.availablePackages.length} packages');
        offering.availablePackages.forEach((package) {
          debugPrint('  - Package: ${package.identifier}, Product: ${package.storeProduct.identifier}');
        });
      });
      
      // Use the exact offering identifier from RevenueCat dashboard
      final offering = offerings.current ?? offerings.getOffering('Premium');
      if (offering == null) {
        debugPrint('No Premium offering available. Available offerings: ${offerings.all.keys.join(', ')}');
        return [];
      }
      
      final packages = offering.availablePackages;
      debugPrint('Loaded ${packages.length} subscription products');
      
      // Convert to list of subscription products
      final productList = packages.map((package) {
        final product = package.storeProduct;
        return SubscriptionProduct(
          id: product.identifier,
          title: product.title,
          description: product.description,
          price: product.priceString,
          rawPrice: product.price.toString(),
          currencyCode: product.currencyCode,
          currencySymbol: '',
        );
      }).toList();
      
      // Sort the products in the order: weekly, monthly, yearly
      productList.sort((a, b) {
        if (a.id.contains('weekly')) return -1;
        if (b.id.contains('weekly')) return 1;
        if (a.id.contains('monthly')) return -1;
        if (b.id.contains('monthly')) return 1;
        return 0;
      });
      
      return productList;
    } catch (e) {
      debugPrint('Error getting subscription products: $e');
      return [];
    }
  }

  // Get coin products
  static Future<List<CoinProduct>> getCoinProducts() async {
    try {
      // In simulator mode, return mock data
      if (isSimulatorMode) {
        debugPrint('🔧 SIMULATOR MODE: Returning mock coin products');
        return [
          CoinProduct(
            id: 'ios.lunacoin_100',
            title: '100 Luna Coins',
            amount: 100,
            price: '\$0.99',
            rawPrice: '0.99',
            currencyCode: 'USD',
            currencySymbol: '\$',
            bonus: '',
          ),
          CoinProduct(
            id: 'ios.lunacoin_500',
            title: '500 Luna Coins',
            amount: 500,
            price: '\$4.99',
            rawPrice: '4.99',
            currencyCode: 'USD',
            currencySymbol: '\$',
            bonus: 'BEST VALUE',
          ),
          CoinProduct(
            id: 'ios.lunacoin_1000',
            title: '1000 Luna Coins',
            amount: 1000,
            price: '\$9.99',
            rawPrice: '9.99',
            currencyCode: 'USD',
            currencySymbol: '\$',
            bonus: 'MOST POPULAR',
          ),
        ];
      }
      
      final offerings = await Purchases.getOfferings();
      debugPrint('Loaded coin offerings: ${offerings.all.keys.join(', ')}');
      
      // Use the exact offering identifier from RevenueCat dashboard
      final offering = offerings.getOffering('Lunacoins');
      if (offering == null) {
        debugPrint('No Lunacoins offering available. Available offerings: ${offerings.all.keys.join(', ')}');
        return [];
      }
      
      final packages = offering.availablePackages;
      debugPrint('Loaded ${packages.length} coin products:');
      packages.forEach((package) {
        debugPrint('  - Package: ${package.identifier}, Product: ${package.storeProduct.identifier}');
      });
      
      return packages.map((package) {
        final product = package.storeProduct;
        final amount = _extractCoinAmount(product.identifier);
        return CoinProduct(
          id: product.identifier,
          title: product.title,
          amount: amount,
          price: product.priceString,
          rawPrice: product.price.toString(),
          currencyCode: product.currencyCode,
          currencySymbol: '',
          bonus: _getBonusLabel(product.identifier),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting coin products: $e');
      return [];
    }
  }

  // Purchase a product
  static Future<PurchaseResult> purchaseProduct(dynamic product) async {
    try {
      final productId = product is SubscriptionProduct 
          ? product.id 
          : product is CoinProduct 
            ? product.id 
            : product is Map 
              ? product['id']?.toString() 
              : null;
              
      if (productId == null) {
        debugPrint('Invalid product: $product');
        return PurchaseResult(
          success: false,
          message: 'Invalid product',
        );
      }
      
      // For simulator testing, use our direct product ID purchase method which handles simulation
      if (isSimulatorMode) {
        return purchaseProductById(productId);
      }
      
      debugPrint('Purchasing product: $productId');
      debugPrint('Available offerings: ${(await Purchases.getOfferings()).all.keys.join(', ')}');
      
      // Get all available packages from all offerings
      List<Package> allPackages = [];
      final offerings = await Purchases.getOfferings();
      offerings.all.forEach((offeringId, offering) {
        allPackages.addAll(offering.availablePackages);
      });
      
      // Find the package by product ID
      Package? foundPackage;
      for (var p in allPackages) {
        if (p.storeProduct.identifier == productId) {
          foundPackage = p;
          debugPrint('Found matching package: ${p.identifier} for product ID: $productId');
          break;
        }
      }
      
      if (foundPackage == null) {
        debugPrint('Product not found across any offerings for ID: $productId');
        debugPrint('Available products: ${allPackages.map((p) => p.storeProduct.identifier).join(', ')}');
        return PurchaseResult(
          success: false,
          message: 'Product not found',
        );
      }
      
      debugPrint('Purchasing package: ${foundPackage.identifier} with product ID: ${foundPackage.storeProduct.identifier}');
      
      try {
        // Try the purchase with standard approach
        final purchaseResult = await Purchases.purchasePackage(foundPackage);
        
        // Check if purchase was successful
        final isPro = purchaseResult.entitlements.active.containsKey('Premium');
        final hasPurchasedCoins = productId.contains('coin') || productId.contains('lunacoin');
        
        if (isPro || hasPurchasedCoins) {
          return PurchaseResult(
            success: true,
            message: 'Purchase successful',
            productId: foundPackage.storeProduct.identifier,
            purchaseId: purchaseResult.originalAppUserId,
          );
        } else {
          return PurchaseResult(
            success: false,
            message: 'Purchase not activated',
          );
        }
      } catch (e) {
        // Handle the specific StoreKit receipt validation error
        if (e.toString().contains('INVALID_RECEIPT') && 
           (productId.contains('weekly') || productId.contains('monthly'))) {
          
          debugPrint('⚠️ Receipt validation issue detected. Implementing workaround...');
          
          // For weekly/monthly subscriptions with receipt issues, check if purchase actually went through
          try {
            await Future.delayed(Duration(seconds: 2)); // Wait for backend processing
            final customerInfo = await Purchases.getCustomerInfo();
            
            // Check if the user now has the premium entitlement despite the error
            if (customerInfo.entitlements.active.containsKey('Premium')) {
              debugPrint('✅ Premium entitlement active despite receipt error - purchase was successful');
              return PurchaseResult(
                success: true,
                message: 'Purchase successful (workaround)',
                productId: productId,
                purchaseId: customerInfo.originalAppUserId,
              );
            }
          } catch (fallbackError) {
            debugPrint('Error in fallback entitlement check: $fallbackError');
          }
        }
        
        // Re-throw the original error
        rethrow;
      }
    } catch (e) {
      debugPrint('Error during purchase: $e');
      if (e is PurchasesErrorCode) {
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          return PurchaseResult(
            success: false,
            message: 'Purchase cancelled by user',
          );
        }
      }
      return PurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Check subscription status
  static Future<bool> hasActiveSubscription() async {
    try {
      // In simulator mode, always return false to encourage testing purchases
      if (isSimulatorMode) {
        debugPrint('🔧 SIMULATOR MODE: No active subscription (simulated)');
        return false;
      }
      
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('Premium');
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  // Restore purchases
  static Future<List<PurchaseResult>> restorePurchases() async {
    try {
      // In simulator mode, return an empty list
      if (isSimulatorMode) {
        debugPrint('🔧 SIMULATOR MODE: No purchases to restore (simulated)');
        return [];
      }
      
      final customerInfo = await Purchases.restorePurchases();
      final activeEntitlements = customerInfo.entitlements.active;
      
      // Sync any active subscription to Firestore
      if (activeEntitlements.containsKey('Premium')) {
        await syncSubscriptionToFirestore(customerInfo);
      }
      
      return activeEntitlements.entries.map((entry) {
        return PurchaseResult(
          success: true,
          message: 'Purchase restored',
          productId: entry.key,
          purchaseId: customerInfo.originalAppUserId,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return [];
    }
  }

  // Sync current subscription data from RevenueCat to Firestore
  static Future<bool> syncSubscriptionToFirestore(CustomerInfo? customerInfo) async {
    try {
      if (currentUserReference == null) {
        debugPrint('Cannot sync subscription: User not logged in');
        return false;
      }
      
      // Get customer info if not provided
      CustomerInfo info;
      if (customerInfo == null) {
        info = await Purchases.getCustomerInfo();
      } else {
        info = customerInfo;
      }
      
      // Check if user has Premium entitlement
      if (!info.entitlements.active.containsKey('Premium')) {
        debugPrint('No active Premium entitlement found');
        return false;
      }
      
      // Get the subscription details
      final entitlement = info.entitlements.active['Premium']!;
      final productId = entitlement.productIdentifier;
      
      // Get tier and other subscription details
      final tierName = _getSubscriptionTier(productId);
      final benefits = _getSubscriptionBenefits(tierName);
      final expiryDate = entitlement.expirationDate != null
          ? DateTime.fromMillisecondsSinceEpoch(entitlement.expirationDate as int)
          : DateTime.now().add(Duration(days: 30));
      
      debugPrint('Syncing subscription data: Product=$productId, Tier=$tierName, Expiry=$expiryDate');
      
      // Update Firestore with subscription details
      await FirebaseFirestore.instance
          .doc(currentUserReference!.path)
          .update({
        'isSubscribed': true,
        'subscription': {
          'productId': productId,
          'tier': tierName,
          'activationDate': Timestamp.now(),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'isActive': true,
          'autoRenew': true,
          'benefits': benefits,
          'bonusCoinsApplied': false, // Force bonus coins to be applied
        },
        'lastSubscriptionUpdate': Timestamp.now(),
      });
      
      debugPrint('✅ Successfully synced subscription from RevenueCat to Firestore');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing subscription data: $e');
      return false;
    }
  }

  // Helper method to extract coin amount from product identifier
  static int _extractCoinAmount(String productId) {
    // Check in descending order (largest first) to avoid partial matches
    if (productId.contains('1000')) return 1000;
    if (productId.contains('500')) return 500;
    if (productId.contains('100')) return 100;
    return 0;
  }

  // Helper method to get bonus label
  static String? _getBonusLabel(String productId) {
    if (productId.contains('500')) return 'BEST VALUE';
    if (productId.contains('1000')) return 'MOST POPULAR';
    return null;
  }

  // Purchase a product by ID directly (more reliable in StoreKit 2)
  static Future<PurchaseResult> purchaseProductById(String productId) async {
    try {
      debugPrint('Attempting direct purchase by product ID: $productId${isSimulatorMode ? " (SIMULATOR MODE)" : ""}');
      
      if (isSimulatorMode) {
        // For simulator testing, we'll simulate a successful purchase
        debugPrint('🔧 SIMULATOR MODE: Simulating successful purchase of $productId');
        await Future.delayed(Duration(seconds: 1)); // Simulate network delay
        
        // If this is a subscription, update Firestore directly for simulator testing
        if (productId.contains('premium') || productId.contains('weekly') || 
            productId.contains('monthly') || productId.contains('yearly')) {
          await _directlyUpdateSubscriptionInFirestore(productId);
        }
        
        // Return a success result with the product ID
        return PurchaseResult(
          success: true,
          message: 'Purchase successful (SIMULATOR MODE)',
          productId: productId,
          purchaseId: 'sim_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // Real purchase flow for production devices
      final offerings = await Purchases.getOfferings();
      
      // Log available products for debugging
      debugPrint('Available offerings for direct purchase: ${offerings.all.keys.join(', ')}');
      
      // Build a list of all packages across all offerings
      List<Package> allPackages = [];
      offerings.all.forEach((offeringId, offering) {
        allPackages.addAll(offering.availablePackages);
      });
      
      // Find the package by product ID
      Package? foundPackage;
      for (var p in allPackages) {
        if (p.storeProduct.identifier == productId) {
          foundPackage = p;
          debugPrint('Found matching package: ${p.identifier} for product ID: $productId');
          break;
        }
      }
      
      if (foundPackage == null) {
        debugPrint('Product not found across any offerings for ID: $productId');
        debugPrint('Available products: ${allPackages.map((p) => p.storeProduct.identifier).join(', ')}');
        return PurchaseResult(
          success: false,
          message: 'Product not found',
        );
      }
      
      debugPrint('Purchasing package: ${foundPackage.identifier} with product ID: ${foundPackage.storeProduct.identifier}');
      
      try {
        // Try the purchase with the standard approach
        final purchaseResult = await Purchases.purchasePackage(foundPackage);
        
        // Consider the purchase successful if it's a consumable or entitlement
        final isPremium = purchaseResult.entitlements.active.containsKey('Premium');
        final isLunacoin = productId.contains('lunacoin');
        
        if (isPremium || isLunacoin) {
          // For subscription purchases, IMMEDIATELY update Firestore with subscription details
          if (isPremium || productId.contains('premium') || productId.contains('weekly') || 
              productId.contains('monthly') || productId.contains('yearly')) {
            // Directly update Firestore subscription details for immediate access
            await _directlyUpdateSubscriptionInFirestore(productId);
          }
          
          return PurchaseResult(
            success: true,
            message: 'Purchase successful',
            productId: productId,
            purchaseId: purchaseResult.originalAppUserId,
          );
        } else {
          return PurchaseResult(
            success: false,
            message: 'Purchase not activated',
          );
        }
      } catch (e) {
        // Handle the specific StoreKit receipt validation error
        if (e.toString().contains('INVALID_RECEIPT') && 
           (productId.contains('weekly') || productId.contains('monthly'))) {
          
          debugPrint('⚠️ Receipt validation issue detected. Implementing workaround...');
          
          // For weekly/monthly subscriptions with receipt issues, check if purchase actually went through
          // by checking the customer info directly
          try {
            await Future.delayed(Duration(seconds: 2)); // Wait for backend processing
            final customerInfo = await Purchases.getCustomerInfo();
            
            // Check if the user now has the premium entitlement despite the error
            if (customerInfo.entitlements.active.containsKey('Premium')) {
              debugPrint('✅ Premium entitlement active despite receipt error - purchase was successful');
              
              // Directly update Firestore for immediate access
              await _directlyUpdateSubscriptionInFirestore(productId);
              
              return PurchaseResult(
                success: true,
                message: 'Purchase successful (workaround)',
                productId: productId,
                purchaseId: customerInfo.originalAppUserId,
              );
            }
          } catch (fallbackError) {
            debugPrint('Error in fallback entitlement check: $fallbackError');
          }
        }
        
        // Re-throw the original error if workaround didn't succeed
        rethrow;
      }
    } catch (e) {
      debugPrint('Error during direct product purchase: $e');
      if (e is PurchasesErrorCode) {
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          return PurchaseResult(
            success: false,
            message: 'Purchase cancelled by user',
          );
        }
      }
      return PurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Static flag to indicate if we're simulating purchases (for testing or debug mode)
  static bool get isSimulatorMode => kDebugMode;

  // Manually refresh subscription status
  static Future<bool> refreshSubscriptionStatus() async {
    try {
      debugPrint('🔄 Manually refreshing subscription status...');
      
      // Force refresh from RevenueCat
      await Purchases.restorePurchases();
      
      // Try to sync to Firestore
      final result = await syncSubscriptionToFirestore(null);
      
      // Trigger a refresh of the SubscriptionManager
      try {
        // Call the refresh method on the SubscriptionManager instance
        await SubscriptionManager.instance.refreshSubscriptionStatus();
        debugPrint('✅ SubscriptionManager refresh triggered successfully');
      } catch (e) {
        // This is not critical, just for optimization
        debugPrint('❌ Could not trigger SubscriptionManager refresh: $e');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ Error refreshing subscription status: $e');
      return false;
    }
  }

  // Update the purchasePackage method to handle subscription benefits
  static Future<PurchaseResult> purchasePackage(dynamic package) async {
    try {
      final result = await purchaseProduct(package);
      
      if (result.success) {
        final productId = result.productId;
        if (productId == null) return result;
        
        // Check if this is a subscription product
        final isSubscription = 
            productId.contains('premium') || 
            productId.contains('weekly') || 
            productId.contains('monthly') || 
            productId.contains('yearly');
        
        if (isSubscription && currentUserReference != null) {
          // Update user's subscription information in Firestore
          final tierName = _getSubscriptionTier(productId);
          final benefits = _getSubscriptionBenefits(tierName);
          final now = DateTime.now();
          final expiryDate = _calculateExpiryDate(tierName, now);
          
          try {
            // Check if user already exists in Firestore
            final userDoc = await FirebaseFirestore.instance
                .doc(currentUserReference!.path)
                .get();
            
            if (userDoc.exists) {
              // Update subscription data
              await FirebaseFirestore.instance
                  .doc(currentUserReference!.path)
                  .update({
                'isSubscribed': true,
                'subscription': {
                  'productId': productId,
                  'tier': tierName,
                  'activationDate': Timestamp.now(),
                  'expiryDate': Timestamp.fromDate(expiryDate),
                  'isActive': true,
                  'autoRenew': true,
                  'benefits': benefits,
                  'bonusCoinsApplied': false, // Set to false so bonus coins get added
                },
                'lastSubscriptionUpdate': Timestamp.now(),
              });
              
              print('✅ Successfully updated user subscription status for: $productId');
            }
          } catch (e) {
            print('❌ Error updating subscription data: $e');
          }
        }
      }
      
      return result;
    } catch (e) {
      print('Error in purchasePackage: $e');
      return PurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Helper method to update Firestore with subscription details
  static Future<void> _updateFirestoreWithSubscription(String productId, CustomerInfo purchaseResult) async {
    try {
      // Check if this is a subscription product
      final isSubscription = 
          productId.contains('premium') || 
          productId.contains('weekly') || 
          productId.contains('monthly') || 
          productId.contains('yearly');
      
      if (isSubscription && currentUserReference != null) {
        // Update user's subscription information in Firestore
        final tierName = _getSubscriptionTier(productId);
        final benefits = _getSubscriptionBenefits(tierName);
        final now = DateTime.now();
        final expiryDate = _calculateExpiryDate(tierName, now);
        
        // Check if user already exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .doc(currentUserReference!.path)
            .get();
        
        if (userDoc.exists) {
          // Update subscription data
          await FirebaseFirestore.instance
              .doc(currentUserReference!.path)
              .update({
            'isSubscribed': true,
            'subscription': {
              'productId': productId,
              'tier': tierName,
              'activationDate': Timestamp.now(),
              'expiryDate': Timestamp.fromDate(expiryDate),
              'isActive': true,
              'autoRenew': true,
              'benefits': benefits,
              'bonusCoinsApplied': false, // Set to false so bonus coins get added
            },
            'lastSubscriptionUpdate': Timestamp.now(),
          });
          
          print('✅ Successfully updated user subscription status for: $productId');
        }
      }
    } catch (e) {
      print('❌ Error updating subscription data: $e');
    }
  }
  
  // Helper method to get subscription tier from product ID
  static String _getSubscriptionTier(String productId) {
    if (productId.contains('weekly') || productId == 'ios.premium_weekly_sub') {
      return 'weekly';
    } else if (productId.contains('monthly') || productId == 'ios.premium_monthly') {
      return 'monthly';
    } else if (productId.contains('yearly') || productId == 'ios.premium_yearly') {
      return 'yearly';
    }
    // Default to monthly if we can't determine
    return 'monthly';
  }
  
  // Helper method to get subscription benefits based on tier
  static List<String> _getSubscriptionBenefits(String tier) {
    switch (tier) {
      case 'weekly':
        return ['dream_analysis', 'exclusive_themes', 'bonus_coins_150', 'ad_free'];
      case 'monthly':
        return ['dream_analysis', 'exclusive_themes', 'bonus_coins_250', 'ad_free', 'zen_mode'];
      case 'yearly':
        return ['dream_analysis', 'exclusive_themes', 'bonus_coins_1000', 'ad_free', 'zen_mode', 'priority_support'];
      default:
        return ['dream_analysis', 'ad_free']; // Minimum benefits as fallback
    }
  }
  
  // Helper method to calculate expiry date based on tier
  static DateTime _calculateExpiryDate(String tier, DateTime startDate) {
    switch (tier) {
      case 'weekly':
        return startDate.add(Duration(days: 7));
      case 'monthly':
        return startDate.add(Duration(days: 30));
      case 'yearly':
        return startDate.add(Duration(days: 365));
      default:
        return startDate.add(Duration(days: 30)); // Default to monthly
    }
  }

  // Add a new reliable method to directly update subscription benefits in Firestore
  static Future<void> _directlyUpdateSubscriptionInFirestore(String productId) async {
    try {
      if (currentUserReference == null) {
        debugPrint('❌ Cannot update subscription: No logged in user');
        return;
      }
      
      debugPrint('🔄 Directly updating subscription in Firestore for: $productId');
      
      // Determine subscription tier and benefits
      final tierName = _getSubscriptionTier(productId);
      final benefits = _getSubscriptionBenefits(tierName);
      final expiryDate = _calculateExpiryDate(tierName, DateTime.now());
      
      // Determine bonus coins based on tier
      int bonusCoins = 0;
      if (tierName == 'weekly') {
        bonusCoins = 150;
      } else if (tierName == 'monthly') {
        bonusCoins = 250;
      } else if (tierName == 'yearly') {
        bonusCoins = 1000;
      }
      
      // Get current user document
      final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found for updating subscription');
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Get current coin balance
      final currentCoins = userData['lunaCoins'] as int? ?? 0;
      
      // Update subscription data AND add bonus coins in a single update
      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'isSubscribed': true,
        'subscription': {
          'productId': productId,
          'tier': tierName,
          'activationDate': Timestamp.now(),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'isActive': true,
          'autoRenew': true,
          'benefits': benefits,
          'bonusCoinsApplied': true, // Mark as applied since we're adding them now
        },
        'lastSubscriptionUpdate': Timestamp.now(),
        'lunaCoins': currentCoins + bonusCoins, // Add bonus coins immediately
      });
      
      debugPrint('✅ Successfully updated subscription data for: $productId');
      debugPrint('💰 Added $bonusCoins bonus coins. New balance: ${currentCoins + bonusCoins}');
      
      // Try to refresh the subscription manager to update UI immediately
      // Note: This is optional and may not always work if the manager isn't initialized
      try {
        // Import is already at the top of the file
        SubscriptionManager.instance.refreshSubscriptionStatus();
        debugPrint('✅ SubscriptionManager refresh triggered successfully');
      } catch (e) {
        // Refresh failed but the data is already updated in Firestore
        debugPrint('Note: Could not trigger SubscriptionManager refresh: $e');
      }
    } catch (e) {
      debugPrint('❌ Error updating subscription data: $e');
    }
  }

  // Emergency method to force unlock all subscription benefits
  static Future<bool> emergencyForceUnlockAllBenefits() async {
    try {
      if (currentUserReference == null) {
        debugPrint('❌ Cannot update subscription: No logged in user');
        return false;
      }
      
      debugPrint('🆘 EMERGENCY: Force unlocking all subscription benefits!');
      
      // Use two approaches for maximum reliability:
      
      // 1. First, directly update Firestore with subscription data
      final tierName = 'yearly';  // Always give yearly tier (most benefits)
      final benefits = _getSubscriptionBenefits(tierName);
      final expiryDate = DateTime.now().add(Duration(days: 365));
      
      // Add significant bonus coins
      const bonusCoins = 1000;
      
      // Get current user document
      final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found for updating subscription');
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Get current coin balance
      final currentCoins = userData['lunaCoins'] as int? ?? 0;
      
      // Update subscription data AND add bonus coins in a single update
      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'isSubscribed': true,
        'subscription': {
          'productId': 'ios.premium_yearly',
          'tier': tierName,
          'activationDate': Timestamp.now(),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'isActive': true,
          'autoRenew': true,
          'benefits': benefits,
          'bonusCoinsApplied': true,
        },
        'lastSubscriptionUpdate': Timestamp.now(),
        'lunaCoins': currentCoins + bonusCoins,
      });
      
      // 2. Then, also force testing mode for immediate effect
      SubscriptionManager.forceEnableTestingMode();
      
      debugPrint('✅ EMERGENCY: All subscription benefits unlocked!');
      debugPrint('💰 Added $bonusCoins bonus coins. New balance: ${currentCoins + bonusCoins}');
      
      // Refresh subscription manager
      try {
        await SubscriptionManager.instance.refreshSubscriptionStatus();
        debugPrint('✅ SubscriptionManager refresh triggered');
        
        // Also force the manager to apply missing benefits
        await SubscriptionManager.instance.applyMissingSubscriptionBenefits();
        debugPrint('✅ Applied any missing benefits');
      } catch (e) {
        debugPrint('❌ Error refreshing manager: $e');
        // Even if this fails, testing mode should still give access
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ EMERGENCY UNLOCK ERROR: $e');
      
      // As a last resort, just enable testing mode
      try {
        SubscriptionManager.forceEnableTestingMode();
        return true;
      } catch (e2) {
        debugPrint('❌ CRITICAL: Even testing mode failed: $e2');
        return false;
      }
    }
  }
}
