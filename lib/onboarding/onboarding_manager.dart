import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_kraft/onboarding/onboarding_screen.dart';

/// Manager class for handling the app's onboarding flow
class OnboardingManager {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _userProfileTypeKey = 'user_profile_type';
  static const String _isNewUserKey = 'is_new_user';

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

    // Also mark that the user is no longer new
    await prefs.setBool(_isNewUserKey, false);
    print('Onboarding marked as completed and user marked as not new');
  }

  /// Reset onboarding status (for testing)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, false);
    await prefs.setBool('has_completed_profile_setup', false);
    await prefs.setBool(_isNewUserKey, true);
    print('Onboarding and profile setup statuses have been reset');
  }

  /// Get the user's selected profile type
  static Future<String> getUserProfileType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userProfileTypeKey) ?? 'Dreamer';
  }

  /// Check if the user has completed profile setup
  static Future<bool> hasCompletedProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('has_completed_profile_setup') ?? false;
    print('Checked profile setup status: $completed');
    return completed;
  }

  /// Mark profile setup as completed
  static Future<void> markProfileSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_profile_setup', true);
    // Don't change the isNewUser flag here - we want new users to remain "new" until after onboarding
    print('Profile setup marked as completed');
  }

  /// Check if this is a new user who needs onboarding
  static Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();

    // If we've explicitly marked the user as not new, return false
    if (prefs.containsKey(_isNewUserKey)) {
      return prefs.getBool(_isNewUserKey) ?? true;
    }

    // If the user has completed onboarding or profile setup, they're not new
    final hasOnboarded = prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    final hasProfile = prefs.getBool('has_completed_profile_setup') ?? false;

    // If neither key exists, assume this is a new user
    final isNew = !hasOnboarded && !hasProfile;

    // Save this status for future checks
    await prefs.setBool(_isNewUserKey, isNew);

    return isNew;
  }

  /// Explicitly mark a user as not new, regardless of other flags
  static Future<void> markUserAsNotNew() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isNewUserKey, false);
    print('User explicitly marked as not new');
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

    // Only show onboarding to new users
    final isNewUserFlag = await isNewUser();
    final hasCompleted = await hasCompletedOnboarding();

    if (isNewUserFlag && !hasCompleted) {
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
