import '/services/subscription_manager.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Utility class for checking subscription status and features
class SubscriptionUtil {
  /// Check if the user has an active subscription
  static bool get isPremium {
    return SubscriptionManager.instance.isSubscribed;
  }

  /// Check if user has weekly subscription
  static bool get isWeeklyPremium {
    // First check subscription manager
    final tier = SubscriptionManager.instance.subscriptionTier;
    if (tier != null && tier.contains('weekly')) {
      return true;
    }
    
    // Check through subscription tier getter as fallback
    return subscriptionTier?.contains('weekly') ?? false;
  }

  /// Check if user has monthly subscription
  static bool get isMonthlyPremium {
    // First check subscription manager
    final tier = SubscriptionManager.instance.subscriptionTier;
    if (tier != null && tier.contains('monthly')) {
      return true;
    }
    
    // Check through subscription tier getter as fallback
    return subscriptionTier?.contains('monthly') ?? false;
  }

  /// Check if user has yearly subscription
  static bool get isYearlyPremium {
    // First check subscription manager
    final tier = SubscriptionManager.instance.subscriptionTier;
    if (tier != null && tier.contains('yearly')) {
      return true;
    }
    
    // Check through subscription tier getter as fallback
    return subscriptionTier?.contains('yearly') ?? false;
  }

  /// Get subscription tier (null if not subscribed)
  static String? get subscriptionTier {
    return SubscriptionManager.instance.subscriptionTier;
  }

  /// Get days left in the subscription (0 if not subscribed)
  static int get daysLeft {
    return SubscriptionManager.instance.daysLeft;
  }

  /// Check if user has dream analysis benefit
  static bool get hasDreamAnalysis {
    return SubscriptionManager.instance.hasBenefit('dream_analysis');
  }

  /// Check if user has exclusive themes benefit
  /// This controls temporary access to premium backgrounds
  static bool get hasExclusiveThemes {
    return SubscriptionManager.instance.hasBenefit('exclusive_themes');
  }

  /// Check if user has ad-free benefit
  static bool get hasAdFree {
    return SubscriptionManager.instance.hasBenefit('ad_free');
  }

  /// Check if user has zen mode benefit
  static bool get hasZenMode {
    return SubscriptionManager.instance.hasBenefit('zen_mode');
  }

  /// Check if user has priority support benefit
  static bool get hasPrioritySupport {
    return SubscriptionManager.instance.hasBenefit('priority_support');
  }

  /// Get all active benefits
  static List<String> get benefits {
    return SubscriptionManager.instance.benefits;
  }

  /// Get the number of bonus coins the user has access to
  static int getBonusCoins() {
    // First check subscription manager
    final benefits = SubscriptionManager.instance.benefits;
    for (final benefit in benefits) {
      if (benefit == 'bonus_coins_1000') return 1000;
      if (benefit == 'bonus_coins_250') return 250;
      if (benefit == 'bonus_coins_150') return 150;
    }
    
    // Fallback to checking subscription tier
    if (isYearlyPremium) return 1000;
    if (isMonthlyPremium) return 250;
    if (isWeeklyPremium) return 150;
    
    return 0;
  }

  /// Check if the user has a specific benefit
  static bool hasBenefit(String benefitId) {
    // Check through subscription manager
    if (SubscriptionManager.instance.hasBenefit(benefitId)) {
      return true;
    }
    
    // Direct check for essential benefits
    if (isPremium) {
      if (benefitId == 'dream_analysis' || 
          benefitId == 'exclusive_themes' || 
          benefitId == 'ad_free') {
        return true;
      }
      
      // Some benefits require monthly/yearly
      if ((isMonthlyPremium || isYearlyPremium) && 
          benefitId == 'zen_mode') {
        return true;
      }
      
      // Priority support only for yearly
      if (isYearlyPremium && benefitId == 'priority_support') {
        return true;
      }
    }
    
    return false;
  }
}
