import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'dart:async';
import '/services/purchase_service.dart';
import '/services/app_state.dart';
import '/backend/schema/user_record.dart';
import '/services/zen_audio_service.dart';

/// Service to manage user subscription status and verification
class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();

  // Singleton instance
  static SubscriptionManager get instance => _instance;

  // Private constructor
  SubscriptionManager._internal();

  // Stream controller for subscription changes
  final _subscriptionStatusController =
      StreamController<SubscriptionStatus>.broadcast();

  // Stream for subscription status
  Stream<SubscriptionStatus> get subscriptionStatus =>
      _subscriptionStatusController.stream;

  // Cached subscription status
  SubscriptionStatus? _cachedStatus;

  // Listen for Firestore changes
  StreamSubscription? _firestoreSubscription;

  // Mapping of subscription tiers to benefits
  final Map<String, List<String>> _subscriptionBenefits = {
    'weekly': [
      'dream_analysis',
      'exclusive_themes',
      'bonus_coins_150',
      'ad_free',
      // Note: 'zen_mode' is intentionally excluded from weekly tier
    ],
    'monthly': [
      'dream_analysis',
      'exclusive_themes',
      'bonus_coins_250',
      'ad_free',
      'zen_mode',
    ],
    'yearly': [
      'dream_analysis',
      'exclusive_themes',
      'bonus_coins_1000',
      'ad_free',
      'zen_mode',
      'priority_support',
    ],
  };

  // Initialize subscription manager
  Future<void> initialize() async {
    // Clean up any existing subscriptions
    await dispose();

    // Start listening for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Use real subscription data
        _startListeningToSubscriptionChanges();
      } else {
        _stopListeningToSubscriptionChanges();
        _updateSubscriptionStatus(SubscriptionStatus(
          isSubscribed: false,
          subscriptionTier: null,
          expiryDate: null,
          benefits: [],
        ));
      }
    });
  }

  // Start listening to Firestore for subscription changes
  void _startListeningToSubscriptionChanges() {
    if (currentUserReference == null) return;

    print('🔄 Starting to listen for subscription changes for user: ${currentUserReference!.id}');
    
    // First, trigger an immediate RevenueCat refresh to ensure data is synced
    PurchaseService.refreshSubscriptionStatus().then((hasSubscription) {
      print('Initial RevenueCat refresh completed: hasSubscription=$hasSubscription');
    }).catchError((e) {
      print('❌ Error during initial RevenueCat refresh: $e');
    });

    _firestoreSubscription = FirebaseFirestore.instance
        .doc(currentUserReference!.path)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final userData = snapshot.data() as Map<String, dynamic>?;
      if (userData == null) return;

      // Get subscription data
      final subscription = userData['subscription'] as Map<String, dynamic>?;
      final isSubscribed = userData['isSubscribed'] as bool? ?? false;

      if (subscription != null && isSubscribed) {
        // Check if subscription is active and not expired
        final expiryDate = (subscription['expiryDate'] as Timestamp?)?.toDate();
        final isActive = subscription['isActive'] as bool? ?? false;

        final isExpired = expiryDate != null &&
            expiryDate.isBefore(DateTime.now()) &&
            !(subscription['autoRenew'] as bool? ?? false);

        // Check if this is a new subscription (has bonusCoinsApplied flag)
        final bonusCoinsApplied = subscription['bonusCoinsApplied'] as bool? ?? false;

        if (isActive && !isExpired) {
          // Valid subscription - check if we need to apply bonus coins
          // This happens only once when the subscription is first activated
          if (!bonusCoinsApplied) {
            _addBonusCoinsForSubscription(subscription['productId'] as String? ?? 'unknown');
          }
          
          // Update subscription status in memory for active subscription
          _updateSubscriptionStatus(SubscriptionStatus(
            isSubscribed: true,
            subscriptionTier: subscription['productId'] as String? ?? 'unknown',
            expiryDate: expiryDate,
            benefits: _parseBenefits(subscription['benefits']),
          ));
          
          // Print debug info for valid subscription
          print('✅ Valid subscription detected: ${subscription['productId']}');
        } else {
          // Expired or inactive subscription
          _updateSubscriptionStatus(SubscriptionStatus(
            isSubscribed: false,
            subscriptionTier: null,
            expiryDate: null,
            benefits: [],
          ));

          // If expired, update the user's subscription status in Firestore
          if (isExpired) {
            _markSubscriptionAsExpired();
            print('❌ Expired subscription detected');
          } else {
            print('❌ Inactive subscription detected');
          }
        }
      } else {
        // No subscription data found
        _updateSubscriptionStatus(SubscriptionStatus(
          isSubscribed: false,
          subscriptionTier: null,
          expiryDate: null,
          benefits: [],
        ));
        print('ℹ️ No subscription data found for user');
      }
    });
  }

  // Convert benefits from various formats to a List<String>
  List<String> _parseBenefits(dynamic benefits) {
    if (benefits == null) {
      return [];
    } else if (benefits is List) {
      return benefits.map((e) => e.toString()).toList();
    } else if (benefits is String) {
      return [benefits];
    }
    return [];
  }

  // Mark subscription as expired in Firebase
  Future<void> _markSubscriptionAsExpired() async {
    try {
      if (currentUserReference == null) return;

      await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
        'isSubscribed': false,
        'subscription.isActive': false,
        'lastSubscriptionUpdate': Timestamp.now(),
      });

      print('Subscription marked as expired');
    } catch (e) {
      print('Error marking subscription as expired: $e');
    }
  }

  // Stop listening to Firestore changes
  void _stopListeningToSubscriptionChanges() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  // Update subscription status and notify listeners
  void _updateSubscriptionStatus(SubscriptionStatus status) {
    _cachedStatus = status;
    _subscriptionStatusController.add(status);
  }

  // Reset all subscription state - call this during logout
  Future<void> resetSubscriptionState() async {
    print('🔄 Resetting subscription state during logout');
    // Clear the cached status
    _cachedStatus = SubscriptionStatus(
      isSubscribed: false,
      subscriptionTier: null,
      expiryDate: null,
      benefits: [],
    );
    
    // Notify listeners
    _subscriptionStatusController.add(_cachedStatus!);
    
    // Stop listening for changes
    _stopListeningToSubscriptionChanges();
    
    print('✅ Subscription state reset complete');
  }

  // Check if user has an active subscription
  bool get isSubscribed => _cachedStatus?.isSubscribed == true;

  // Get subscription tier
  String? get subscriptionTier => _cachedStatus?.subscriptionTier;

  // Check if user has a specific benefit
  bool hasBenefit(String benefit) {
    return _cachedStatus?.benefits.contains(benefit) ?? false;
  }

  // Get current user's benefits
  List<String> get benefits {
    if (!isSubscribed || _cachedStatus == null) {
      return [];
    }
    
    final tier = _cachedStatus!.subscriptionTier;
    if (tier == null) {
      return [];
    }
    
    // Parse the tier to a simple format (weekly, monthly, yearly)
    String simpleTier = _getSimpleTier(tier);
    
    // Return benefits based on tier from mapping
    if (_subscriptionBenefits.containsKey(simpleTier)) {
      return _subscriptionBenefits[simpleTier]!;
    }
    
    // Fallback to determine benefits based on tier for backward compatibility
    List<String> tierBenefits = [];
    
    if (tier.contains('weekly')) {
      tierBenefits = ['dream_analysis', 'exclusive_themes', 'bonus_coins_150', 'ad_free'];
    } else if (tier.contains('monthly')) {
      tierBenefits = ['dream_analysis', 'exclusive_themes', 'bonus_coins_250', 'ad_free', 'zen_mode'];
    } else if (tier.contains('yearly')) {
      tierBenefits = ['dream_analysis', 'exclusive_themes', 'bonus_coins_1000', 'ad_free', 'zen_mode', 'priority_support'];
    }
    
    return tierBenefits;
  }
  
  // Helper to get a simple tier name from product ID
  String _getSimpleTier(String tier) {
    if (tier.contains('weekly') || tier == 'ios.premium_weekly_sub') {
      return 'weekly';
    } else if (tier.contains('monthly') || tier == 'ios.premium_monthly') {
      return 'monthly';
    } else if (tier.contains('yearly') || tier == 'ios.premium_yearly') {
      return 'yearly';
    }
    return '';
  }

  // Get days left in subscription
  int get daysLeft {
    final expiryDate = _cachedStatus?.expiryDate;
    if (expiryDate == null) return 0;

    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  // Dispose resources
  Future<void> dispose() async {
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  // Add bonus coins to user account based on subscription tier
  Future<void> _addBonusCoinsForSubscription(String productId) async {
    // Current user reference is required
    if (currentUserReference == null) {
      print('⚠️ Cannot add bonus coins: No current user');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();

      // First check if bonus coins were already applied
      final subscriptionData = userDoc.data()?['subscription'] as Map<String, dynamic>?;
      final bonusCoinsAlreadyApplied = subscriptionData?['bonusCoinsApplied'] as bool? ?? false;
      
      if (bonusCoinsAlreadyApplied) {
        print('ℹ️ Bonus coins were already applied for this subscription');
        return;
      }

      // Determine bonus coin amount based on tier
      int bonusCoins = 0;
      if (productId.contains('weekly')) {
        bonusCoins = 150;
      } else if (productId.contains('monthly')) {
        bonusCoins = 250;
      } else if (productId.contains('yearly')) {
        bonusCoins = 1000;
      }

      if (bonusCoins > 0) {
        // Use a transaction to ensure atomic update
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Get the latest user data within transaction
          final latestUserDoc = await transaction.get(currentUserReference!);
          final userData = latestUserDoc.data() as Map<String, dynamic>?;
          
          if (userData == null) return;
          
          // Get current coin balance
          final currentCoins = userData['luna_coins'] as int? ?? 0;
          
          // Update both coins and mark as applied in one transaction
          transaction.update(currentUserReference!, {
            'luna_coins': currentCoins + bonusCoins,
            'subscription.bonusCoinsApplied': true,
          });
        });

        print('💰 Added $bonusCoins bonus coins for subscription tier: $productId');
      }
      
      // Unlock all backgrounds for premium users
      await _unlockAllBackgroundsForPremium();
      
    } catch (e) {
      print('❌ Error adding bonus coins: $e');
    }
  }
  
  // Unlock all backgrounds for premium subscribers
  Future<void> _unlockAllBackgroundsForPremium() async {
    if (currentUserReference == null) return;
    
    try {
      // Get all backgrounds from AppState (excluding default ones)
      final appState = AppState();
      final backgroundOptions = appState.backgroundOptions;
      
      final backgroundFiles = backgroundOptions
          .where((bg) => 
              bg['file'] != 'backgroundanimation.json' && 
              bg['file'] != 'gradient.json')
          .map((bg) => bg['file']!)
          .toList();
      
      // We no longer permanently unlock backgrounds in Firestore
      // Instead, access is granted based on subscription status
      
      // Force refresh the AppState to update the UI
      appState.forceReinitialize();
      
      // Also make premium zen sounds available during subscription
      await _makePremiumZenSoundsAvailable();
      
      print('🔓 Premium backgrounds made available during subscription');
    } catch (e) {
      print('❌ Error making premium backgrounds available: $e');
    }
  }
  
  // Make premium zen sounds available during subscription
  Future<void> _makePremiumZenSoundsAvailable() async {
    try {
      // Refresh the Zen audio service to update sound availability
      final zenService = ZenAudioService();
      
      // Check if the service is already initialized before refreshing
      if (zenService.isInitialized) {
        // Use the public method to refresh sound lock status
        zenService.refreshSoundLockStatus();
        print('🔊 Premium zen sounds made available during subscription');
      } else {
        // The service will initialize with correct states when needed
        print('ℹ️ Zen service not yet initialized, sound status will update on init');
      }
    } catch (e) {
      print('❌ Error making premium zen sounds available: $e');
    }
  }

  // Manually apply subscription benefits including adding bonus coins
  // Can be called to fix user accounts that didn't receive their benefits
  Future<bool> applyMissingSubscriptionBenefits() async {
    try {
      if (currentUserReference == null) return false;
      
      // Get current user data
      final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return false;
      
      // Check if the user has an active subscription
      final isSubscribed = userData['isSubscribed'] as bool? ?? false;
      final subscription = userData['subscription'] as Map<String, dynamic>?;
      
      if (!isSubscribed || subscription == null) {
        print('❌ No active subscription found - cannot apply benefits');
        return false;
      }
      
      // Apply bonus coins
      final productId = subscription['productId'] as String? ?? 'unknown';
      print('🔄 Manually applying missing benefits for subscription: $productId');
      
      // Get bonus coin amount
      int bonusCoins = 0;
      if (productId.contains('weekly')) {
        bonusCoins = 150;
      } else if (productId.contains('monthly')) {
        bonusCoins = 250;
      } else if (productId.contains('yearly')) {
        bonusCoins = 1000;
      }
      
      if (bonusCoins > 0) {
        // Calculate new coin balance - use the correct field name
        final currentCoins = userData['luna_coins'] as int? ?? 0;
        final newCoins = currentCoins + bonusCoins;
        
        // Update user document with new coin balance and mark coins as applied
        await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
          'luna_coins': newCoins,
          'subscription.bonusCoinsApplied': true,
        });
        
        print('✅ Successfully added $bonusCoins missing coins. New balance: $newCoins');
        return true;
      } else {
        print('❓ Could not determine bonus coin amount for product: $productId');
      }
      
      return false;
    } catch (e) {
      print('❌ Error applying missing subscription benefits: $e');
      return false;
    }
  }
  
  // Refresh the subscription status manually - useful for fixing issues
  Future<void> refreshSubscriptionStatus() async {
    try {
      if (currentUserReference == null) return;
      
      // Re-fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return;
      
      // Process subscription data
      final subscription = userData['subscription'] as Map<String, dynamic>?;
      final isSubscribed = userData['isSubscribed'] as bool? ?? false;
      
      print('🔄 Manually refreshing subscription status. isSubscribed: $isSubscribed');
      
      if (subscription != null && isSubscribed) {
        final expiryDate = (subscription['expiryDate'] as Timestamp?)?.toDate();
        final isActive = subscription['isActive'] as bool? ?? false;
        final productId = subscription['productId'] as String? ?? 'unknown';
        
        final isExpired = expiryDate != null &&
            expiryDate.isBefore(DateTime.now()) &&
            !(subscription['autoRenew'] as bool? ?? false);
            
        if (isActive && !isExpired) {
          print('✅ Valid subscription found: $productId');
          
          // Update subscription status in memory
          _updateSubscriptionStatus(SubscriptionStatus(
            isSubscribed: true,
            subscriptionTier: productId,
            expiryDate: expiryDate,
            benefits: _parseBenefits(subscription['benefits']),
          ));
          
          // Also check if we need to apply any bonus benefits that weren't applied
          if (productId.contains('premium') || 
              productId.contains('weekly') || 
              productId.contains('monthly') || 
              productId.contains('yearly')) {
            
            final bonusApplied = subscription['bonusCoinsApplied'] as bool? ?? false;
            if (!bonusApplied) {
              print('💰 Applying missing bonus coins for subscription...');
              await _addBonusCoinsForSubscription(productId);
            }
          }
        } else {
          print('❌ Subscription found but it is expired or inactive');
          
          // Update subscription status in memory to indicate no active subscription
          _updateSubscriptionStatus(SubscriptionStatus(
            isSubscribed: false,
            subscriptionTier: null,
            expiryDate: null,
            benefits: [],
          ));
        }
      } else {
        print('❌ No valid subscription data found');
        
        // Try to check with RevenueCat as a fallback
        try {
          // Directly call PurchaseService
          print('🔄 Attempting to refresh subscription from RevenueCat...');
          final success = await PurchaseService.refreshSubscriptionStatus();
          if (success) {
            print('✅ Successfully refreshed subscription from RevenueCat');
            // Wait a moment for the Firestore data to update
            await Future.delayed(Duration(seconds: 2));
            // Call this method again to read the updated Firestore data
            await refreshSubscriptionStatus();
            return;
          }
        } catch (e) {
          print('❌ Error refreshing from RevenueCat: $e');
        }
        
        // If we get here, no subscription was found
        _updateSubscriptionStatus(SubscriptionStatus(
          isSubscribed: false,
          subscriptionTier: null,
          expiryDate: null,
          benefits: [],
        ));
      }
    } catch (e) {
      print('❌ Error refreshing subscription status: $e');
    }
  }
  
  // Force a complete refresh of subscription status from both RevenueCat and Firestore
  Future<bool> forceCompleteRefresh() async {
    try {
      print('🔄 Performing complete subscription refresh...');
      
      // First try to refresh from RevenueCat
      try {
        print('🔄 Refreshing subscription data from RevenueCat...');
        
        // Directly call PurchaseService
        await PurchaseService.refreshSubscriptionStatus();
        print('✅ RevenueCat refresh completed');
      } catch (e) {
        print('⚠️ Error during RevenueCat refresh: $e');
      }
      
      // Then refresh from Firestore
      await refreshSubscriptionStatus();
      
      // Finally, check if we were able to find an active subscription
      final hasActiveSubscription = isSubscribed;
      
      print('🔍 Complete refresh result: hasActiveSubscription=$hasActiveSubscription');
      return hasActiveSubscription;
    } catch (e) {
      print('❌ Error during complete subscription refresh: $e');
      return false;
    }
  }
}

/// Class representing subscription status
class SubscriptionStatus {
  final bool isSubscribed;
  final String? subscriptionTier;
  final DateTime? expiryDate;
  final List<String> benefits;

  SubscriptionStatus({
    required this.isSubscribed,
    required this.subscriptionTier,
    required this.expiryDate,
    required this.benefits,
  });

  @override
  String toString() =>
      'SubscriptionStatus(isSubscribed: $isSubscribed, tier: $subscriptionTier, expires: $expiryDate, benefits: $benefits)';
}
