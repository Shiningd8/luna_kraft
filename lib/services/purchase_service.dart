import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/subscription_product.dart';
import 'models/coin_product.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/subscription_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        rethrow; // Rethrow the error to notify callers of initialization failure
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
      for (var package in allPackages) {
        if (package.storeProduct.identifier == productId) {
          foundPackage = package;
          debugPrint('Found package with product ID: $productId');
          break;
        }
      }
      
      if (foundPackage == null) {
        debugPrint('❌ Package not found for product ID: $productId');
        return PurchaseResult(
          success: false,
          message: 'Product not available',
          productId: productId,
        );
      }
      
      // Purchase the package
      debugPrint('Attempting to purchase package: ${foundPackage.identifier}');
      
      // Process the purchase
      final purchaseResult = await Purchases.purchasePackage(foundPackage);
      debugPrint('Purchase completed for: $productId');
      
      // Get detailed information about the purchase result
      debugPrint('Purchase result info: CustomerID: ${purchaseResult.originalAppUserId}');
      final hasActiveEntitlements = purchaseResult.entitlements.active.isNotEmpty;
      debugPrint('Has active entitlements: $hasActiveEntitlements');
      
      if (hasActiveEntitlements) {
        debugPrint('Active entitlements: ${purchaseResult.entitlements.active.keys.join(', ')}');
        purchaseResult.entitlements.active.forEach((key, entitlement) {
          debugPrint('Entitlement: $key, ID: ${entitlement.productIdentifier}, Will Renew: ${entitlement.willRenew}');
        });
      }
      
      // Handle purchase result based on product type
      if (productId.contains('lunacoin')) {
        // This is a Luna Coins purchase - update user's coin balance
        debugPrint('Processing Luna Coins purchase: $productId');
        
        // Extract the coin amount from the product ID
        final coinAmount = _extractCoinAmount(productId);
        if (coinAmount > 0 && currentUserReference != null) {
          debugPrint('Adding $coinAmount Luna Coins to user balance');
          
          try {
            // First try the direct Firestore update
            final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserUid != null) {
              await _updateUserLunaCoinsOnly(currentUserUid, coinAmount, productId);
            } else {
              debugPrint('❌ User not logged in, cannot update coins');
            }
          } catch (e) {
            debugPrint('❌ Error updating Luna Coins: $e');
            // No fallback needed now as _updateUserLunaCoinsOnly handles everything
          }
        }
        
        return PurchaseResult(
          success: true,
          message: 'Purchased $coinAmount Luna Coins successfully',
          productId: productId,
        );
      } else {
        // This is a subscription purchase
        final hasActiveSubscription = purchaseResult.entitlements.active.containsKey('Premium');
        debugPrint('Purchase is a subscription. Has active Premium subscription: $hasActiveSubscription');
        
        if (hasActiveSubscription) {
          // Immediately update Firestore with subscription details
          debugPrint('Syncing subscription to Firestore...');
          await syncSubscriptionToFirestore(purchaseResult);
          
          // Force refresh the subscription manager to update UI
          try {
            await SubscriptionManager.instance.refreshSubscriptionStatus();
            debugPrint('Successfully refreshed SubscriptionManager');
          } catch (e) {
            debugPrint('Error refreshing SubscriptionManager: $e');
          }
        } else {
          debugPrint('⚠️ Purchase successful but no Premium entitlement found. This may indicate an issue with RevenueCat.');
        }
        
        return PurchaseResult(
          success: true,
          message: 'Purchase successful',
          productId: productId,
        );
      }
    } catch (e) {
      debugPrint('❌ Purchase failed: $e');
      
      // Special handling for platform exceptions
      if (e is PlatformException) {
        return PurchaseResult(
          success: false,
          message: e.message ?? 'Unknown error occurred',
        );
      }
      
      return PurchaseResult(
        success: false,
        message: e.toString(),
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

  // Sync subscription information from RevenueCat to Firestore
  static Future<bool> syncSubscriptionToFirestore(CustomerInfo customerInfo) async {
    try {
      // Ensure we have a user reference
      if (currentUserReference == null) {
        debugPrint('❌ Cannot sync subscription - no user logged in');
        return false;
      }
      
      // Check if user has an active premium entitlement
      final hasPremium = customerInfo.entitlements.active.containsKey('Premium');
      debugPrint('User has active premium entitlement: $hasPremium');
      
      // Print out all available entitlements for debugging
      debugPrint('Available entitlements: ${customerInfo.entitlements.active.keys.join(', ')}');
      if (customerInfo.entitlements.active.isNotEmpty) {
        customerInfo.entitlements.active.forEach((key, entitlement) {
          debugPrint('Entitlement: $key, ID: ${entitlement.productIdentifier}, Active: ${entitlement.isActive}');
        });
      } else {
        debugPrint('❌ No active entitlements found in RevenueCat');
      }
      
      if (hasPremium) {
        // Get the active subscription from the customer info
        final activeSubscription = customerInfo.entitlements.active['Premium'];
        if (activeSubscription == null) {
          debugPrint('❌ Active subscription data is null');
          return false;
        }
        
        // Get the product ID of the active subscription
        final productId = activeSubscription.productIdentifier;
        debugPrint('Active subscription product ID: $productId');
        
        // Get user document to check current subscription status
        final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
        if (!userDoc.exists) {
          debugPrint('❌ User document not found');
          return false;
        }
        
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) {
          debugPrint('❌ User data is null');
          return false;
        }
        
        // Get current subscription data
        final currentSubscriptionData = userData['subscription'] as Map<String, dynamic>?;
        final currentProductId = currentSubscriptionData?['productId'] as String?;
        final bonusCoinsApplied = currentSubscriptionData?['bonusCoinsApplied'] as bool? ?? false;
        
        debugPrint('Current subscription product ID: $currentProductId');
        debugPrint('Bonus coins already applied: $bonusCoinsApplied');
        
        // Check if this is a new subscription or product change
        final isNewSubscription = currentProductId != productId;
        
        // If this is a new subscription or product change, update subscription data
        if (isNewSubscription || !bonusCoinsApplied) {
          // Determine subscription tier and benefits
          final tier = _getSubscriptionTier(productId);
          final benefits = _getSubscriptionBenefits(tier);
          
          // Get expiry date from RevenueCat
          final expiryDate = activeSubscription.expirationDate != null
              ? _safelyConvertToDateTime(activeSubscription.expirationDate)
              : _calculateExpiryDate(tier, DateTime.now());
          
          debugPrint('📅 RevenueCat expirationDate (raw): ${activeSubscription.expirationDate} (${activeSubscription.expirationDate.runtimeType})');
          debugPrint('📅 Converted expiryDate: $expiryDate');
          
          // Determine if bonus coins should be added
          final shouldAddBonusCoins = isNewSubscription || !bonusCoinsApplied;
          
          // Update subscription data in Firestore
          await _directlyUpdateSubscriptionInFirestore(
            productId: productId,
            autoRenew: true,
            applyBonusCoins: shouldAddBonusCoins,
            expiryDateOverride: expiryDate,
          );
          
          debugPrint('✅ Successfully synced subscription to Firestore from RevenueCat');
        } else {
          debugPrint('ℹ️ Subscription data already up to date, no changes needed');
        }
        
        return true;
      } else {
        // No active subscription - check if we need to update Firestore
        final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
        if (!userDoc.exists) {
          debugPrint('❌ User document not found');
          return false;
        }
        
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) {
          debugPrint('❌ User data is null');
          return false;
        }
        
        // Check if user is currently marked as subscribed in Firestore
        final isSubscribed = userData['isSubscribed'] as bool? ?? false;
        
        if (isSubscribed) {
          // Update Firestore to mark subscription as expired
          await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
            'isSubscribed': false,
            'subscription.isActive': false,
            'lastSubscriptionUpdate': Timestamp.now(),
          });
          
          debugPrint('✅ Marked subscription as expired in Firestore');
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error syncing subscription to Firestore: $e');
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

  // Purchase a product by its ID
  static Future<PurchaseResult> purchaseProductById(String productId) async {
    try {
      debugPrint('🔄 Attempting to purchase product: $productId');
      
      // Handle simulator mode first
      if (isSimulatorMode || _overrideSimulatorMode) {
        debugPrint('🔧 SIMULATOR MODE: Simulating successful purchase of $productId');
        await Future.delayed(Duration(seconds: 1)); // Simulate network delay
        
        // Determine bonus coins based on subscription tier
        int bonusCoins = 0;
        if (productId.contains('weekly')) {
          bonusCoins = 150;
        } else if (productId.contains('monthly')) {
          bonusCoins = 250;
        } else if (productId.contains('yearly')) {
          bonusCoins = 1000;
        }
        
        // If this is a subscription, update Firestore directly
        if ((productId.contains('premium') || productId.contains('weekly') || 
            productId.contains('monthly') || productId.contains('yearly')) &&
            !productId.contains('lunacoin')) {
          try {
            await _directlyUpdateSubscriptionInFirestore(
              productId: productId,
              autoRenew: true,
            );
            debugPrint('✅ Subscription updated in simulator mode with $bonusCoins bonus coins');
          } catch (e) {
            debugPrint('❌ Error updating subscription in simulator mode: $e');
          }
        }
        
        // Return a success result
        return PurchaseResult(
          success: true,
          message: 'Purchase successful (SIMULATOR MODE)',
          productId: productId,
          purchaseId: 'sim_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // Real device purchase flow
      // Find the package for the product ID
      final offerings = await Purchases.getOfferings();
      
      // Detailed debug info
      debugPrint('Available offerings: ${offerings.all.keys.join(', ')}');
      
      // Find the package by looking through all offerings
      Package? foundPackage;
      offerings.all.forEach((offeringId, offering) {
        for (var package in offering.availablePackages) {
          if (package.storeProduct.identifier == productId) {
            foundPackage = package;
            debugPrint('Found package with product ID: $productId in offering: $offeringId');
            break;
          }
        }
      });
      
      if (foundPackage == null) {
        debugPrint('❌ Product ID not found in any offering: $productId');
        return PurchaseResult(
          success: false,
          message: 'Product not found',
          productId: productId,
        );
      }
      
      // Attempt the purchase
      final Package package = foundPackage!;
      debugPrint('Starting purchase for package: ${package.identifier}');
      final purchaseResult = await Purchases.purchasePackage(package);
      
      // Check if purchase was successful by looking for entitlements
      final isPremium = purchaseResult.entitlements.active.containsKey('Premium');
      debugPrint('Purchase completed, has premium entitlement: $isPremium');
      
      // Print out all entitlements for debugging
      debugPrint('Available entitlements after purchase: ${purchaseResult.entitlements.active.keys.join(', ')}');
      purchaseResult.entitlements.active.forEach((key, entitlement) {
        debugPrint('Entitlement: $key, ID: ${entitlement.productIdentifier}, Active: ${entitlement.isActive}');
      });
      
      // CRITICAL FIX: Only update subscription data if the product is a subscription, NOT Luna Coins
      if (isPremium && !productId.contains('lunacoin')) {
        // Immediately update Firestore with subscription details
        try {
          debugPrint('💽 Updating subscription in Firestore for product: $productId');
          await _directlyUpdateSubscriptionInFirestore(
            productId: productId,
            autoRenew: true,
          );
          debugPrint('✅ Subscription successfully updated in Firestore');
          
          // Force a refresh of the subscription manager to ensure UI is updated
          try {
            await SubscriptionManager.instance.refreshSubscriptionStatus();
            debugPrint('✅ SubscriptionManager refreshed successfully');
          } catch (e) {
            debugPrint('⚠️ Error refreshing SubscriptionManager: $e');
          }
        } catch (e) {
          debugPrint('❌ Error updating subscription in Firestore: $e');
          // Try backup method
          await syncSubscriptionToFirestore(purchaseResult);
        }
      }
      
      return PurchaseResult(
        success: true,
        message: 'Purchase successful',
        productId: productId,
        purchaseId: purchaseResult.originalAppUserId,
      );
    } catch (e) {
      debugPrint('❌ Purchase failed: $e');
      
      // Special handling for platform exceptions
      if (e is PlatformException) {
        return PurchaseResult(
          success: false,
          message: e.message ?? 'Unknown error occurred',
          productId: productId,
        );
      }
      
      return PurchaseResult(
        success: false,
        message: e.toString(),
        productId: productId,
      );
    }
  }

  // Static flag to indicate if we're simulating purchases (for testing or debug mode)
  static bool get isSimulatorMode => false; // Always return false in release mode

  // Manually refresh subscription status
  static Future<bool> refreshSubscriptionStatus() async {
    try {
      // In simulator mode, return false
      if (isSimulatorMode) {
        debugPrint('🔧 SIMULATOR MODE: Refresh not needed (simulated)');
        return false;
      }
      
      final customerInfo = await Purchases.getCustomerInfo();
      final hasActiveSubscription = customerInfo.entitlements.active.containsKey('Premium');
      
      if (hasActiveSubscription) {
        debugPrint('✅ Active subscription found in RevenueCat');
        await syncSubscriptionToFirestore(customerInfo);
        return true;
      } else {
        debugPrint('❌ No active subscription found in RevenueCat');
        return false;
      }
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
          debugPrint('✅ Subscription purchase was successful for: $productId');
          
          // Refresh from RevenueCat first to ensure we have the latest entitlements
          try {
            debugPrint('🔄 Refreshing subscription status from RevenueCat...');
            await refreshSubscriptionStatus();
          } catch (e) {
            debugPrint('⚠️ Error refreshing from RevenueCat: $e');
          }
          
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
              debugPrint('📝 Updating subscription data in Firestore...');
              
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
              
              debugPrint('✅ Successfully updated user subscription status for: $productId');
              
              // Ensure SubscriptionManager is aware of the change
              try {
                await SubscriptionManager.instance.refreshSubscriptionStatus();
                debugPrint('✅ SubscriptionManager refreshed successfully');
              } catch (e) {
                debugPrint('⚠️ Error refreshing SubscriptionManager: $e');
              }
            }
          } catch (e) {
            debugPrint('❌ Error updating subscription data: $e');
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error in purchasePackage: $e');
      return PurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Helper method to update Firestore with subscription details
  static Future<void> _updateFirestoreWithSubscription(String productId, CustomerInfo purchaseResult) async {
    try {
      // CRITICAL FIX: Skip this method entirely for Luna Coin purchases
      if (productId.contains('lunacoin')) {
        debugPrint('⚠️ Skipping subscription update for Luna Coin product: $productId');
        return;
      }
      
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
          
          debugPrint('✅ Successfully updated user subscription status for: $productId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating subscription data: $e');
    }
  }
  
  // Helper method to get subscription tier from product ID
  static String _getSubscriptionTier(String productId) {
    if (productId.contains('weekly')) {
      return 'weekly';
    } else if (productId.contains('monthly')) {
      return 'monthly';
    } else if (productId.contains('yearly')) {
      return 'yearly';
    }
    return 'unknown';
  }
  
  // Helper method to get subscription benefits based on tier
  static List<String> _getSubscriptionBenefits(String tier) {
    if (tier == 'weekly') {
      return ['dream_analysis', 'exclusive_themes', 'bonus_coins_150', 'ad_free'];
      // Note: 'zen_mode' is intentionally excluded from weekly tier
    } else if (tier == 'monthly') {
      return ['dream_analysis', 'exclusive_themes', 'bonus_coins_250', 'ad_free', 'zen_mode'];
    } else if (tier == 'yearly') {
      return ['dream_analysis', 'exclusive_themes', 'bonus_coins_1000', 'ad_free', 'zen_mode', 'priority_support'];
    }
    return [];
  }
  
  // Helper method to calculate expiry date based on tier
  static DateTime _calculateExpiryDate(String tier, DateTime startDate) {
    if (tier == 'weekly') {
      return startDate.add(Duration(days: 7));
    } else if (tier == 'monthly') {
      return startDate.add(Duration(days: 30));
    } else if (tier == 'yearly') {
      return startDate.add(Duration(days: 365));
    }
    return startDate.add(Duration(days: 30)); // Default to monthly
  }

  // Directly update subscription in Firestore - used as a fallback or for immediate updates
  static Future<void> _directlyUpdateSubscriptionInFirestore({
    required String productId,
    bool autoRenew = true,
    bool applyBonusCoins = true,
    DateTime? expiryDateOverride,
  }) async {
    try {
      // CRITICAL FIX: Never update subscription data for Luna Coin purchases
      if (productId.contains('lunacoin')) {
        debugPrint('⚠️ Prevented subscription data modification for Luna Coin product: $productId');
        return;
      }
      
      // Check if we have a user reference
      if (currentUserReference == null) {
        debugPrint('❌ Cannot update subscription - no user logged in');
        return;
      }

      debugPrint('🔄 Directly updating subscription in Firestore for product: $productId');
      
      // Determine subscription tier and benefits based on product ID
      final tier = _getSubscriptionTier(productId);
      final benefits = _getSubscriptionBenefits(tier);
      final expiryDate = expiryDateOverride ?? _calculateExpiryDate(tier, DateTime.now());
      
      // Determine bonus coins based on subscription tier
      int bonusCoins = 0;
      if (tier == 'weekly') {
        bonusCoins = 150;
      } else if (tier == 'monthly') {
        bonusCoins = 250;
      } else if (tier == 'yearly') {
        bonusCoins = 1000;
      }
      
      // Get current user document to update the coin balance
      final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found');
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        debugPrint('❌ User data is null');
        return;
      }
      
      // Calculate new coin balance if bonus coins should be applied
      int newCoins = userData['luna_coins'] as int? ?? 0;
      if (applyBonusCoins && bonusCoins > 0) {
        debugPrint('💰 Adding $bonusCoins bonus coins. Current: $newCoins');
        newCoins += bonusCoins;
        debugPrint('💰 New balance: $newCoins');
      }
      
      // Create subscription data to update
      final subscriptionData = {
        'productId': productId,
        'tier': tier,
        'benefits': benefits,
        'activationDate': Timestamp.now(),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'autoRenew': autoRenew,
        'isActive': true,
        'bonusCoinsApplied': applyBonusCoins, // Only mark as applied if we actually applied them
      };
      
      // Update user document with subscription details
      final updateData = {
        'isSubscribed': true,
        'subscription': subscriptionData,
        'lastSubscriptionUpdate': Timestamp.now(),
      };
      
      // Only update coins if we're applying bonus coins
      if (applyBonusCoins && bonusCoins > 0) {
        updateData['luna_coins'] = newCoins;
      }
      
      await FirebaseFirestore.instance.doc(currentUserReference!.path).update(updateData);
      
      if (applyBonusCoins && bonusCoins > 0) {
        debugPrint('✅ Successfully updated subscription in Firestore with $bonusCoins bonus coins');
      } else {
        debugPrint('✅ Successfully updated subscription in Firestore (no bonus coins applied)');
      }
      
      // Try to refresh the SubscriptionManager to update UI immediately
      try {
        await SubscriptionManager.instance.refreshSubscriptionStatus();
      } catch (e) {
        debugPrint('⚠️ Error refreshing SubscriptionManager: $e');
      }
      
      // Debug log to verify the method was called completely
      debugPrint('✅✅✅ _directlyUpdateSubscriptionInFirestore completed for productId: $productId, autoRenew: $autoRenew, applyBonusCoins: $applyBonusCoins');
    } catch (e) {
      debugPrint('❌ Error directly updating subscription in Firestore: $e');
      throw e; // Rethrow to allow caller to handle
    }
  }

  // Helper method to check if running on iOS simulator
  static Future<bool> _isRunningOnIOSSimulator() async {
    // Simple check for iOS simulator
    if (!Platform.isIOS) return false;
    
    try {
      // Use a simple heuristic - simulator typically has a device name containing "Simulator"
      final String deviceName = Platform.environment['SIMULATOR_DEVICE_NAME'] ?? '';
      return deviceName.contains('Simulator') || 
             deviceName.contains('iPhone Simulator') ||
             deviceName.contains('iOS Simulator');
    } catch (e) {
      debugPrint('Error checking iOS simulator status: $e');
      return false;
    }
  }
  
  // Helper method to check if running on Android emulator
  static Future<bool> _isRunningOnAndroidEmulator() async {
    // Simple check for Android
    if (!Platform.isAndroid) return false;
    
    try {
      // Android emulators typically have specific model names
      final String model = Platform.environment['ANDROID_MODEL'] ?? '';
      return model.contains('sdk') || 
             model.contains('google_sdk') || 
             model.contains('emulator') ||
             model.contains('Android SDK');
    } catch (e) {
      debugPrint('Error checking Android emulator status: $e');
      return false;
    }
  }

  // Check if device is a simulator/emulator
  static Future<bool> checkIfSimulator() async {
    // Always return false for production/release
    return false;
  }

  // Static variable to manually override simulator mode
  static bool _overrideSimulatorMode = false;

  // Helper method to update only Luna Coins without affecting subscription
  static Future<void> _updateUserLunaCoinsOnly(
    String uid, 
    int coinAmount, 
    String productId,
  ) async {
    try {
      print('🔄 Updating ONLY Luna Coins for user $uid with $coinAmount coins from product $productId');
      
      // CRITICAL: Use FieldValue.increment to ONLY modify the luna_coins field
      // This approach preserves all other user data including:
      // - unlocked_backgrounds
      // - subscription data
      // - other user preferences
      
      // BUGFIX: Use correct collection path - "User" instead of "users"
      final userRef = FirebaseFirestore.instance.collection('User').doc(uid);
      
      await userRef.update({
        'luna_coins': FieldValue.increment(coinAmount),
        'last_coin_update': FieldValue.serverTimestamp(),
      });
      
      print('✅ Successfully updated ONLY Luna Coins balance for user $uid');
    } catch (e) {
      print('❌ Error updating Luna Coins: $e');
      rethrow;
    }
  }

  // Helper method to safely convert to DateTime
  static DateTime _safelyConvertToDateTime(dynamic date) {
    try {
      debugPrint('🔄 Converting date value to DateTime: $date (type: ${date.runtimeType})');
      
      if (date == null) {
        debugPrint('⚠️ Date value is null, using default expiry');
        return DateTime.now().add(Duration(days: 30));
      }
      
      if (date is int) {
        // Handle milliseconds timestamp
        if (date > 100000000000) { // If timestamp is in milliseconds (13 digits typically)
          return DateTime.fromMillisecondsSinceEpoch(date);
        } else { // If timestamp is in seconds (10 digits typically)
          return DateTime.fromMillisecondsSinceEpoch(date * 1000);
        }
      } 
      else if (date is double) {
        // Convert double to int for milliseconds timestamp
        final int milliseconds = date.toInt();
        if (milliseconds > 100000000000) { // If timestamp is in milliseconds
          return DateTime.fromMillisecondsSinceEpoch(milliseconds);
        } else { // If timestamp is in seconds
          return DateTime.fromMillisecondsSinceEpoch(milliseconds * 1000);
        }
      } 
      else if (date is String) {
        debugPrint('🔍 Attempting to parse date string: $date');
        
        // Try parsing as int timestamp first
        try {
          final int timestamp = int.parse(date);
          if (timestamp > 100000000000) { // If timestamp is in milliseconds
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else { // If timestamp is in seconds
            return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          }
        } catch (_) {
          // If not a number, try as ISO format
          try {
            return DateTime.parse(date);
          } catch (e) {
            debugPrint('❌ Failed to parse date string as ISO: $e');
            // Default to a future date
            return DateTime.now().add(Duration(days: 30));
          }
        }
      } 
      else {
        debugPrint('⚠️ Unknown date format (${date.runtimeType}), using default expiry');
        // Default to 30 days from now as fallback
        return DateTime.now().add(Duration(days: 30));
      }
    } catch (e) {
      debugPrint('❌ Error converting date: $e');
      // Fallback to a reasonable default
      return DateTime.now().add(Duration(days: 30));
    }
  }
}
