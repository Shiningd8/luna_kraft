import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'dart:async';

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

  // Add a testing mode flag for development and testing
  static bool _testingMode = false; // Set to false by default, especially for release mode
  
  // Method to enable/disable testing mode
  static void setTestingMode(bool enabled) {
    _testingMode = enabled;
    instance._updateSubscriptionStatusForTestingMode();
  }
  
  // Force enable testing mode even in release builds (for emergency fixes)
  static void forceEnableTestingMode() {
    setTestingMode(true); // Force enable testing mode
    print('⚠️ EMERGENCY: Testing mode forcibly enabled for subscription access');
    // Add bonus coins for emergency cases
    if (currentUserReference != null) {
      FirebaseFirestore.instance.doc(currentUserReference!.path).get().then((doc) {
        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>?;
          final currentCoins = userData?['lunaCoins'] as int? ?? 0;
          FirebaseFirestore.instance.doc(currentUserReference!.path).update({
            'lunaCoins': currentCoins + 1000,
          }).then((_) {
            print('💰 EMERGENCY: Added 1000 bonus coins');
          }).catchError((e) {
            print('❌ Failed to add emergency coins: $e');
          });
        }
      }).catchError((e) {
        print('❌ Error getting user document for emergency coins: $e');
      });
    }
  }
  
  // Provide a testing subscription for development
  void _updateSubscriptionStatusForTestingMode() {
    if (_testingMode) {
      // Create a test subscription with all benefits
      _updateSubscriptionStatus(SubscriptionStatus(
        isSubscribed: true,
        subscriptionTier: 'yearly', // Use yearly to get all benefits
        expiryDate: DateTime.now().add(Duration(days: 365)),
        benefits: _subscriptionBenefits['yearly'] ?? [],
      ));
      print('🧪 TESTING MODE: Simulated yearly subscription activated');
      
      // In testing mode, also add bonus coins if needed
      Future.microtask(() => _addBonusCoinsForSubscription('yearly'));
    } else if (_cachedStatus?.isSubscribed == true && _cachedStatus?.subscriptionTier == 'yearly') {
      // Only reset if we previously set a test subscription
      _startListeningToSubscriptionChanges();
      print('🧪 TESTING MODE: Disabled, reverted to actual subscription status');
    }
  }

  // Initialize subscription manager
  Future<void> initialize() async {
    // Clean up any existing subscriptions
    await dispose();

    // Enable testing mode in debug mode
    if (kDebugMode) {
      setTestingMode(true);
      print('🧪 Debug build detected - Testing mode enabled automatically');
    }
    
    // Start listening for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        if (_testingMode) {
          // If in testing mode, use simulated subscription
          _updateSubscriptionStatusForTestingMode();
        } else {
          // Otherwise use real subscription data
          _startListeningToSubscriptionChanges();
        }
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

  // Check if user has an active subscription
  bool get isSubscribed => _testingMode || _cachedStatus?.isSubscribed == true;

  // Get subscription tier
  String? get subscriptionTier => _testingMode ? 'yearly' : _cachedStatus?.subscriptionTier;

  // Check if user has a specific benefit
  bool hasBenefit(String benefit) {
    if (_testingMode) {
      // In testing mode, provide access to all benefits
      return _subscriptionBenefits['yearly']?.contains(benefit) ?? false;
    }
    return _cachedStatus?.benefits.contains(benefit) ?? false;
  }

  // Get current user's benefits
  List<String> get benefits {
    if (_testingMode) {
      return _subscriptionBenefits['yearly'] ?? [];
    }
    
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
    if (currentUserReference == null) return;
    
    try {
      int bonusCoins = 0;
      
      // Determine bonus coins based on subscription tier
      if (productId.contains('weekly')) {
        bonusCoins = 150;
      } else if (productId.contains('monthly')) {
        bonusCoins = 250;
      } else if (productId.contains('yearly')) {
        bonusCoins = 1000;
      }
      
      if (bonusCoins > 0) {
        print('💰 Adding $bonusCoins bonus coins for subscription: $productId');
        
        // Get current user data
        final userDoc = await FirebaseFirestore.instance.doc(currentUserReference!.path).get();
        if (!userDoc.exists) return;
        
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) return;
        
        // Calculate new coin balance
        final currentCoins = userData['lunaCoins'] as int? ?? 0;
        final newCoins = currentCoins + bonusCoins;
        
        // Update user document with new coin balance and mark coins as applied
        await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
          'lunaCoins': newCoins,
          'subscription.bonusCoinsApplied': true,
        });
        
        print('✅ Successfully added $bonusCoins coins. New balance: $newCoins');
      }
    } catch (e) {
      print('❌ Error adding bonus coins: $e');
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
        // Calculate new coin balance
        final currentCoins = userData['lunaCoins'] as int? ?? 0;
        final newCoins = currentCoins + bonusCoins;
        
        // Update user document with new coin balance and mark coins as applied
        await FirebaseFirestore.instance.doc(currentUserReference!.path).update({
          'lunaCoins': newCoins,
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
      
      // Temporarily disable testing mode to get real status
      final wasInTestingMode = _testingMode;
      if (wasInTestingMode) {
        _testingMode = false;
      }
      
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
        } else {
          print('❌ Subscription found but it is expired or inactive');
        }
      } else {
        print('❌ No valid subscription data found');
      }
      
      // Restore testing mode if it was enabled
      if (wasInTestingMode) {
        _testingMode = true;
        _updateSubscriptionStatusForTestingMode();
      }
    } catch (e) {
      print('❌ Error refreshing subscription status: $e');
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
