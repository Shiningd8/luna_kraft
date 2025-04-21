import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_kraft/onboarding/onboarding_screen.dart';

/// Manager class for handling the app's onboarding flow
class OnboardingManager {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _userProfileTypeKey = 'user_profile_type';

  /// Check if the user has completed the onboarding process
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  /// Mark the onboarding as completed
  static Future<void> markOnboardingComplete(
      {String profileType = 'Dreamer'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    await prefs.setString(_userProfileTypeKey, profileType);
  }

  /// Reset onboarding status (for testing)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, false);
  }

  /// Get the user's selected profile type
  static Future<String> getUserProfileType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userProfileTypeKey) ?? 'Dreamer';
  }

  /// Handle onboarding flow - shows onboarding if needed or proceeds to main app
  static Future<Widget> handleOnboarding({
    required Widget mainApp,
    bool forceShow = false,
  }) async {
    if (forceShow) {
      return OnboardingScreen(
        onComplete: () async {
          await markOnboardingComplete();
          // Navigation will be handled by the calling widget
        },
      );
    }

    final hasCompleted = await hasCompletedOnboarding();
    if (!hasCompleted) {
      return OnboardingScreen(
        onComplete: () async {
          await markOnboardingComplete();
          // Navigation will be handled by the calling widget
        },
      );
    }

    return mainApp;
  }
}
