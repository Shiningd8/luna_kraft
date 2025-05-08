import 'package:flutter/material.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final String animationPath;
  final String backgroundImage;
  final String? ctaText;
  final AnimationType animationType;

  OnboardingPageData({
    required this.title,
    required this.description,
    this.animationPath = '',
    this.backgroundImage = '',
    this.ctaText,
    this.animationType = AnimationType.lottie,
  });
}

enum AnimationType {
  lottie,
  custom,
  imageSequence,
  particles,
}

final List<OnboardingPageData> onboardingPages = [
  // 1. Welcome Screen
  OnboardingPageData(
    title: "Welcome to Lunakraft 🌙",
    description:
        "A dream-sharing world where stories come alive, even the ones you barely remember.",
    backgroundImage: "assets/images/bg/starry_bg.png",
    animationType: AnimationType.particles,
  ),

  // 2. Dream Recreator
  OnboardingPageData(
    title: "Dream Recreator",
    description:
        "Forgot your dream? No worries.\nJust tell us what you remember — our AI will help craft your lost story.",
    animationPath: "assets/lottie/dream_text.json",
    animationType: AnimationType.lottie,
  ),

  // 3. Social Connections
  OnboardingPageData(
    title: "Social Connections",
    description:
        "Follow fellow dreamers, friends, or discover surreal stories from around the world.\nReact, comment, and stay connected in your dream universe.",
    animationPath: "assets/lottie/network.json",
    animationType: AnimationType.custom,
  ),

  // 4. Save & Collect Dreams
  OnboardingPageData(
    title: "Save & Collect Dreams",
    description:
        "Your dream collection awaits.\nBookmark the dreams you love and revisit them anytime.",
    animationPath: "assets/lottie/bookshelf.json",
    animationType: AnimationType.lottie,
  ),

  // LunaCoins Usage Page
  OnboardingPageData(
    title: "LunaCoins: Unlock More",
    description:
        "Earn and use LunaCoins to unlock premium features, exclusive dream themes, and special content.\nUpgrade your experience and personalize your dream world!",
    animationPath: "assets/images/lunacoin.png",
    animationType: AnimationType.custom,
  ),

  // 5. Premium Insights
  OnboardingPageData(
    title: "Premium Insights",
    description:
        "Unlock deep insights with Dream Analysis.\nSee how your dreams evolve over time with our premium tools.",
    animationPath: "assets/lottie/chart.json",
    animationType: AnimationType.lottie,
  ),

  // 6. Zen Mode
  OnboardingPageData(
    title: "Zen Mode",
    description:
        "Sleep soundly with Zen Mode.\nMix & match calming sounds to craft your perfect nightscape.",
    animationPath: "assets/lottie/sound.json",
    animationType: AnimationType.lottie,
  ),

  // 7. Permission Requests
  OnboardingPageData(
    title: "Stay in the Loop",
    description:
        "Get notified when someone reacts to your dream or when a new dream trend arises.",
    animationPath: "assets/lottie/notification.json",
    ctaText: "Allow Notifications",
    animationType: AnimationType.lottie,
  ),

  // 8. Final Screen
  OnboardingPageData(
    title: "You're ready to dream with us",
    description: "Start your Lunakraft journey.",
    backgroundImage: "assets/images/bg/starry_bg.png",
    animationType: AnimationType.particles,
    ctaText: "Enter Lunakraft",
  ),
];
