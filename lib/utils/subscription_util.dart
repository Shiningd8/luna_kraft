import '/services/subscription_manager.dart';

/// Utility class for checking subscription status and features
class SubscriptionUtil {
  /// Check if the user has any active subscription
  static bool get isPremium => SubscriptionManager.instance.isSubscribed;

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
  static bool get hasDreamAnalysis =>
      SubscriptionManager.instance.hasBenefit('dream_analysis');

  /// Check if user has access to exclusive themes
  static bool get hasExclusiveThemes =>
      SubscriptionManager.instance.hasBenefit('exclusive_themes');

  /// Check if user has ad-free experience
  static bool get isAdFree =>
      SubscriptionManager.instance.hasBenefit('ad_free');

  /// Check if user has access to zen mode
  static bool get hasZenMode =>
      SubscriptionManager.instance.hasBenefit('zen_mode');

  /// Check if user has priority support
  static bool get hasPrioritySupport =>
      SubscriptionManager.instance.hasBenefit('priority_support');

  /// Get the number of bonus coins the user has access to
  static int getBonusCoins() {
    final benefits = SubscriptionManager.instance.benefits;

    for (final benefit in benefits) {
      if (benefit == 'bonus_coins_1000') return 1000;
      if (benefit == 'bonus_coins_250') return 250;
      if (benefit == 'bonus_coins_150') return 150;
    }

    return 0;
  }

  /// Check if the user has a specific benefit
  static bool hasBenefit(String benefitId) =>
      SubscriptionManager.instance.hasBenefit(benefitId);

  /// Get the days left in the subscription
  static int get daysLeft => SubscriptionManager.instance.daysLeft;

  /// Get the subscription tier name
  static String? get subscriptionTier =>
      SubscriptionManager.instance.subscriptionTier;
}
