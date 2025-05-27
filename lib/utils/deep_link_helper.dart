import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'dart:io' show Platform;

/// A helper class for generating and handling deep links
class DeepLinkHelper {
  static const String APP_PACKAGE_NAME = "com.flutterflow.lunakraft";
  static const String IOS_APP_STORE_ID = "your-app-store-id"; // Replace with actual App Store ID
  
  /// Generate a deep link for a user profile
  static String generateUserProfileLink(DocumentReference userRef) {
    final userId = userRef.id;
    
    // Create a universal deep link
    return 'lunakraft://lunakraft.com/profile/$userId';
  }
  
  /// Generate a shareable link that includes both app and web URLs
  static String generateShareableProfileLink(DocumentReference userRef) {
    final userId = userRef.id;
    
    // Direct app URL
    final appUrl = 'lunakraft://lunakraft.com/profile/$userId';
    
    // Web URL for app store fallback
    final webUrl = 'https://lunakraft.com/download?referral=profile&id=$userId';
    
    return 'Check out this profile on Luna Kraft!\n\n'
        'Open in app: $appUrl\n\n'
        'Don\'t have the app? Download it here: $webUrl';
  }

  /// Initialize deep link handling
  static Future<void> initDynamicLinks() async {
    // In a real implementation, you would set up Firebase Dynamic Links here
    // This is a simplified version without the Firebase Dynamic Links package
    print('Deep link handling initialized.');
  }
  
  /// Handle a deep link URI when the app is launched from a link
  static void handleDeepLink(BuildContext context, Uri uri) {
    print('Handling deep link: $uri');
    
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length >= 2 && pathSegments[0] == 'profile') {
      final userId = pathSegments[1];
      
      // Navigate to the user profile using GoRouter
      context.pushNamed('Profile', pathParameters: {'userId': userId});
    }
  }
  
  /// Build an App Store URL for iOS
  static String getiOSAppStoreUrl() {
    return 'https://apps.apple.com/app/id$IOS_APP_STORE_ID';
  }
  
  /// Build a Play Store URL for Android
  static String getAndroidPlayStoreUrl() {
    return 'https://play.google.com/store/apps/details?id=$APP_PACKAGE_NAME';
  }
  
  /// Launch the appropriate app store based on platform
  static Future<void> launchAppStore() async {
    final storeUrl = Platform.isIOS 
        ? getiOSAppStoreUrl() 
        : getAndroidPlayStoreUrl();
        
    await url_launcher.launchUrl(Uri.parse(storeUrl));
  }
} 