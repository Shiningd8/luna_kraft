import '/services/subscription_manager.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for checking subscription status and features
class SubscriptionUtil {
  /// Check if the user has any active subscription
  static bool get isPremium {
    // Primary check - use the subscription manager
    if (SubscriptionManager.instance.isSubscribed) {
      return true;
    }
    
    // Secondary check - look directly at Firestore data if available
    if (currentUserDocument != null) {
      try {
        // Access the document data as a Map
        final userData = FirebaseFirestore.instance
            .doc(currentUserReference!.path)
            .get()
            .then((doc) => doc.data() as Map<String, dynamic>?);
            
        // Since userData is a Future, we can't directly use it here
        // Just rely on the subscription manager in this case
      } catch (e) {
        // Ignore errors and fall back to subscription manager
      }
    }
    
    return false;
  }

  /// Check if user has weekly subscription
  static bool get isWeeklyPremium {
    final tier = SubscriptionManager.instance.subscriptionTier;
    return tier != null && tier.contains('weekly');
  }

  /// Check if user has monthly subscription
  static bool get isMonthlyPremium {
    final tier = SubscriptionManager.instance.subscriptionTier;
    return tier != null && tier.contains('monthly');
  }

  /// Check if user has yearly subscription
  static bool get isYearlyPremium {
    final tier = SubscriptionManager.instance.subscriptionTier;
    return tier != null && tier.contains('yearly');
  }

  /// Check if user has access to dream analysis
  static bool get hasDreamAnalysis {
    if (SubscriptionManager.instance.hasBenefit('dream_analysis')) {
      return true;
    }
    
    // Check if user has any valid subscription (as all should include dream analysis)
    return isPremium;
  }

  /// Check if user has access to exclusive themes
  static bool get hasExclusiveThemes {
    if (SubscriptionManager.instance.hasBenefit('exclusive_themes')) {
      return true;
    }
    
    // Check if user has any valid subscription
    return isPremium;
  }

  /// Check if user has ad-free experience
  static bool get isAdFree {
    if (SubscriptionManager.instance.hasBenefit('ad_free')) {
      return true;
    }
    
    // Check if user has any valid subscription
    return isPremium;
  }

  /// Check if user has access to zen mode
  static bool get hasZenMode {
    if (SubscriptionManager.instance.hasBenefit('zen_mode')) {
      return true;
    }
    
    // Check if user has monthly or yearly subscription
    return isMonthlyPremium || isYearlyPremium;
  }

  /// Check if user has priority support
  static bool get hasPrioritySupport {
    if (SubscriptionManager.instance.hasBenefit('priority_support')) {
      return true;
    }
    
    // Only yearly gets priority support
    return isYearlyPremium;
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

  /// Get the days left in the subscription
  static int get daysLeft {
    // First try subscription manager
    final managerDaysLeft = SubscriptionManager.instance.daysLeft;
    if (managerDaysLeft > 0) {
      return managerDaysLeft;
    }
    
    return 0;
  }

  /// Get the subscription tier name
  static String? get subscriptionTier {
    // Try subscription manager first
    final managerTier = SubscriptionManager.instance.subscriptionTier;
    if (managerTier != null) {
      return managerTier;
    }
    
    // Fall back to default tier
    return null;
  }
}
