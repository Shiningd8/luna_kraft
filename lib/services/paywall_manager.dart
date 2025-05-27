import 'package:flutter/material.dart';
import 'purchase_service.dart';
import 'models/subscription_product.dart';
import 'models/coin_product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This is a placeholder for the PaywallManager
// The implementation has been temporarily removed and will be re-implemented from scratch
class PaywallManager {
  // Get coin products
  static Future<List<CoinProduct>> getCoinProducts() async {
    return await PurchaseService.getCoinProducts();
  }

  // Get membership products
  static Future<List<SubscriptionProduct>> getMembershipProducts() async {
    return await PurchaseService.getMembershipProducts();
  }

  // Purchase a product
  static Future<PurchaseResult> purchaseProduct(dynamic product) async {
    return await PurchaseService.purchaseProduct(product);
  }

  // Restore previous purchases
  static Future<List<PurchaseResult>> restorePurchases() async {
    return await PurchaseService.restorePurchases();
  }

  // Check if user has an active subscription
  static Future<bool> hasActiveSubscription() async {
    return await PurchaseService.hasActiveSubscription();
  }

  // Platform-specific product ID
  static String getPlatformSpecificProductId(String baseId) {
    // For Google Play, we keep the same ID
    return baseId;
  }

  // Show paywall
  static Future<void> showPaywall(
    BuildContext context, {
    required String offeringType,
    bool forceRealMode = false,
  }) async {
    try {
      // Initialize the purchase service if needed
      await PurchaseService.init();

      // Get the available products
      final products = await getMembershipProducts();

      if (products.isEmpty) {
        // Show a message if products are not available
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Subscriptions Not Available'),
            content: Text(
                'Could not load subscription options. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }

      // Show the paywall dialog with the available products
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Choose Subscription Plan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.title),
                  subtitle: Text(product.description),
                  trailing: Text(product.price),
                  onTap: () async {
                    Navigator.pop(context);

                    // Show loading indicator
                    final loadingDialog = showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text('Processing payment...'),
                          ],
                        ),
                      ),
                    );

                    try {
                      // Purchase the product
                      final result = await purchaseProduct(product);

                      // Dismiss loading dialog
                      Navigator.of(context).pop();

                      // Show result
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(result.success ? 'Success' : 'Error'),
                          content: Text(result.success
                              ? 'Your subscription was successful!'
                              : result.message ?? 'An error occurred'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      // Dismiss loading dialog
                      Navigator.of(context).pop();

                      // Show error
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Error'),
                          content: Text('An error occurred: $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Show loading indicator
                final loadingDialog = showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Restoring purchases...'),
                      ],
                    ),
                  ),
                );

                try {
                  // Restore purchases
                  final results = await restorePurchases();

                  // Dismiss loading dialog
                  Navigator.of(context).pop();

                  // Show result
                  final success = results.any((result) => result.success ?? false);
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(success ? 'Success' : 'No Purchases Found'),
                      content: Text(success
                          ? 'Your purchases have been restored!'
                          : 'No previous purchases were found.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  // Dismiss loading dialog
                  Navigator.of(context).pop();

                  // Show error
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Error'),
                      content: Text('An error occurred: $e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Restore Purchases'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Show error dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  // Show coin purchase dialog
  static Future<void> showCoinPurchase(
    BuildContext context, {
    bool forceRealMode = false,
  }) async {
    try {
      // Initialize the purchase service if needed
      await PurchaseService.init();

      // Get the available coin products
      final products = await getCoinProducts();

      // Show a dialog with the available coin products
      if (context.mounted && products.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Buy Luna Coins'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Choose a coin package:'),
                SizedBox(height: 16),
                ...products.map((product) => ListTile(
                      leading: Image.asset(
                        'assets/images/lunacoin.png',
                        width: 24,
                        height: 24,
                      ),
                      title: Text('${product.amount} Coins'),
                      subtitle: Text(product.price),
                      trailing:
                          product.bonus != null && product.bonus!.isNotEmpty
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    product.bonus!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await purchaseProduct(product);
                      },
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint(
          'PaywallManager.showCoinPurchase(): Error showing coin purchase dialog - $e');
    }
  }

  // Purchase a product by ID directly
  static Future<PurchaseResult> purchaseProductById(String productId) async {
    try {
      // First ensure RevenueCat is initialized
      await PurchaseService.init();
      
      // Purchase directly using product ID
      final result = await PurchaseService.purchaseProductById(productId);
      
      // If the purchase was successful and it's a lunacoin purchase, update the user's coins
      if (result.success && productId.contains('lunacoin')) {
        if (PurchaseService.isSimulatorMode) {
          await _updateUserCoinsForSimulatedPurchase(productId);
        } else {
          await _updateUserCoinsAfterPurchase(productId);
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error in purchaseProductById: $e');
      return PurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }
  
  // Updates user's coins after a successful purchase
  static Future<void> _updateUserCoinsAfterPurchase(String productId) async {
    try {
      // Only proceed if we have a logged in user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot update coins: No user is logged in');
        return;
      }
      
      // Extract coin amount from the product ID
      int coinAmount = 0;
      if (productId.contains('100') && !productId.contains('1000')) coinAmount = 100;
      else if (productId.contains('500')) coinAmount = 500;
      else if (productId.contains('1000')) coinAmount = 1000;
      
      if (coinAmount == 0) {
        debugPrint('Cannot determine coin amount from product ID: $productId');
        return;
      }
      
      debugPrint('Adding $coinAmount coins to user ${currentUser.uid}');
      
      // Update user document in Firestore to add the coins
      final userRef = FirebaseFirestore.instance.collection('User').doc(currentUser.uid);
      
      // Get current coins
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        debugPrint('User document not found');
        return;
      }
      
      final currentCoins = userDoc.data()?['luna_coins'] as int? ?? 0;
      final newCoins = currentCoins + coinAmount;
      
      // Update the document
      await userRef.update({
        'luna_coins': newCoins,
        'last_coin_update': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Updated user coins from $currentCoins to $newCoins');
    } catch (e) {
      debugPrint('Error updating user coins: $e');
    }
  }
  
  // Updates user's coins for simulated purchases in simulator mode
  static Future<void> _updateUserCoinsForSimulatedPurchase(String productId) async {
    try {
      // Only proceed if we have a logged in user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot update coins: No user is logged in');
        return;
      }
      
      // Extract coin amount from the product ID
      int coinAmount = 0;
      if (productId.contains('100') && !productId.contains('1000')) coinAmount = 100;
      else if (productId.contains('500')) coinAmount = 500;
      else if (productId.contains('1000')) coinAmount = 1000;
      
      if (coinAmount == 0) {
        debugPrint('Cannot determine coin amount from product ID: $productId');
        return;
      }
      
      debugPrint('🔧 SIMULATOR MODE: Adding $coinAmount coins to user ${currentUser.uid}');
      
      // Update user document in Firestore to add the coins
      final userRef = FirebaseFirestore.instance.collection('User').doc(currentUser.uid);
      
      // Get current coins
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        debugPrint('User document not found');
        return;
      }
      
      final currentCoins = userDoc.data()?['luna_coins'] as int? ?? 0;
      final newCoins = currentCoins + coinAmount;
      
      // Update the document
      await userRef.update({
        'luna_coins': newCoins,
        'last_coin_update': FieldValue.serverTimestamp(),
      });
      
      debugPrint('🔧 SIMULATOR MODE: Updated user coins from $currentCoins to $newCoins');
    } catch (e) {
      debugPrint('Error updating user coins: $e');
    }
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
