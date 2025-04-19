class PurchaseConfig {
  // RevenueCat API Keys
  static const String revenueCatApiKeyIOS = 'YOUR_IOS_API_KEY';
  static const String revenueCatApiKeyAndroid = 'YOUR_ANDROID_API_KEY';

  // Product IDs for coins
  static const String coins100 = 'luna_100_coins';
  static const String coins500 = 'luna_500_coins';
  static const String coins1000 = 'luna_1000_coins';

  // Product IDs for memberships
  static const String membershipWeekly = 'luna_membership_weekly';
  static const String membershipMonthly = 'luna_membership_monthly';
  static const String membershipYearly = 'luna_membership_yearly';

  // Offering identifiers (HOW users can purchase)
  static const String coinsOffering = 'coins_offering';
  static const String membershipOffering = 'membership_offering';

  // Entitlement identifiers (WHAT users have access to)
  static const String premiumEntitlement = 'premium_access';
  static const String dreamAnalysisEntitlement = 'dream_analysis';
  static const String exclusiveThemesEntitlement = 'exclusive_themes';
  static const String adFreeEntitlement = 'ad_free';

  // Maps membership durations to their entitlements
  static const Map<String, List<String>> membershipEntitlements = {
    membershipWeekly: [
      premiumEntitlement,
      dreamAnalysisEntitlement,
      exclusiveThemesEntitlement,
      adFreeEntitlement,
    ],
    membershipMonthly: [
      premiumEntitlement,
      dreamAnalysisEntitlement,
      exclusiveThemesEntitlement,
      adFreeEntitlement,
    ],
    membershipYearly: [
      premiumEntitlement,
      dreamAnalysisEntitlement,
      exclusiveThemesEntitlement,
      adFreeEntitlement,
    ],
  };
}
