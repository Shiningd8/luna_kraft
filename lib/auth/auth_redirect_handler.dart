import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/onboarding/onboarding_manager.dart';
import '/signreg/profile_input/profile_input_widget.dart';
import '/signreg/signin/signin_widget.dart';
import '/home/home_page/home_page_widget.dart';
import '/flutter_flow/nav/nav.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Handler for redirecting authenticated users to the correct screen
/// based on their onboarding and profile setup status
class AuthRedirectHandler {
  /// Check if a newly authenticated user should be redirected
  /// to profile setup or onboarding before accessing the home page
  static Future<String?> checkNewUserRedirect(BuildContext context) async {
    try {
      // First check if the user is actually logged in
      if (!loggedIn || currentUser == null) {
        print('User is not logged in - redirecting to signin');
        return SigninWidget.routePath;
      }

      // Then check if the user has a profile document
      final hasProfileDoc = await checkUserProfileExists();

      // Get onboarding status
      final hasCompletedOnboarding =
          await OnboardingManager.hasCompletedOnboarding();
      final isNewUser = await OnboardingManager.isNewUser();

      print('Debug: Profile document exists: $hasProfileDoc');
      print('Debug: Onboarding completed: $hasCompletedOnboarding');
      print('Debug: Is new user: $isNewUser');

      // For new users or users without a profile, always go to profile input first
      if (!hasProfileDoc) {
        print('User has no profile document - redirecting to profile input');
        return ProfileInputWidget.routePath;
      }

      // User has a profile document, mark profile setup as complete
      await OnboardingManager.markProfileSetupComplete();

      // If profile exists, this is not a new user - force update this flag
      if (hasProfileDoc && isNewUser) {
        print(
            'User has a profile but is marked as new - correcting this status');
        await OnboardingManager.markUserAsNotNew();
      }

      // After profile is complete, check if they need to see onboarding
      if (!hasCompletedOnboarding) {
        // Only new users who haven't completed onboarding should see it
        // Since we just corrected the isNewUser flag, we need to check again
        final isStillNewUser = await OnboardingManager.isNewUser();

        if (isStillNewUser) {
          print('Confirmed new user who needs onboarding');
          return '/show-onboarding';
        } else {
          // Returning users should skip onboarding
          print(
              'Returning user - marking onboarding as complete and skipping it');
          await OnboardingManager.markOnboardingComplete();
          return null;
        }
      }

      // User has completed both, no redirect needed
      return null;
    } catch (e) {
      print('Error checking new user redirect: $e');
      return null;
    }
  }

  /// Manual navigation helper to ensure new users go through
  /// the proper flow after authentication
  static Future<void> navigateAfterAuth(BuildContext context) async {
    try {
      // Temporarily disable automatic auth change notifications to prevent
      // the app from automatically redirecting to HomePage
      AppStateNotifier.instance.updateNotifyOnAuthChange(false);
      print('Auth auto-navigation disabled for redirection checks');

      // Double check if the user is actually authenticated
      if (!loggedIn || currentUser == null) {
        print('User is not authenticated - returning to signin');
        if (context.mounted) {
          context.goNamed(SigninWidget.routeName);
        }
        return;
      }

      final redirectPath = await checkNewUserRedirect(context);
      print('Redirect path determined: $redirectPath');

      if (redirectPath != null && context.mounted) {
        // Need to redirect to profile or onboarding
        print('Redirecting to: $redirectPath');
        if (redirectPath == ProfileInputWidget.routePath) {
          context.goNamed(ProfileInputWidget.routeName);
        } else if (redirectPath == '/show-onboarding') {
          // Use the special onboarding route
          context.go('/show-onboarding');
        } else if (redirectPath == SigninWidget.routePath) {
          // If for some reason auth state is lost, go back to signin
          context.goNamed(SigninWidget.routeName);
        } else {
          context.goNamed(SigninWidget.routeName);
        }
      } else if (context.mounted) {
        // Proceed to home page - user has completed all required steps
        print('All steps completed, proceeding to HomePage');
        AppStateNotifier.instance.updateNotifyOnAuthChange(true);
        context.goNamed(HomePageWidget.routeName);
      }
    } catch (e) {
      print('Error navigating after auth: $e');
      // Re-enable auth navigation for fallback case
      AppStateNotifier.instance.updateNotifyOnAuthChange(true);

      // Return to signin as a fallback for safety
      if (context.mounted) {
        context.goNamed(SigninWidget.routeName);
      }
    }
  }
}
