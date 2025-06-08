import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'dart:io' show Platform;

/// A helper class for generating and handling deep links
class DeepLinkHelper {
  static const String APP_PACKAGE_NAME = "com.flutterflow.lunakraft";
  static const String IOS_APP_STORE_ID = "your-app-store-id"; // Replace with actual App Store ID
  static const String BASE_DOMAIN = "lunakraft.com";
  
  /// Generate a deep link for a user profile
  static String generateUserProfileLink(DocumentReference userRef) {
    final userId = userRef.id;
    
    // Create a universal deep link
    return 'lunakraft://$BASE_DOMAIN/profile/$userId';
  }
  
  /// Generate a deep link for a specific post
  static String generatePostLink(DocumentReference postRef, {DocumentReference? userRef}) {
    final postId = postRef.id;
    final userId = userRef?.id;
    
    // Create a universal deep link for the post
    if (userId != null) {
      return 'lunakraft://$BASE_DOMAIN/post/$postId?user=$userId';
    } else {
      return 'lunakraft://$BASE_DOMAIN/post/$postId';
    }
  }
  
  /// Generate a shareable web link for a post that redirects to app or store
  static String generateShareablePostLink(DocumentReference postRef, {DocumentReference? userRef}) {
    final postId = postRef.id;
    final userId = userRef?.id;
    
    // Create a web URL that will redirect to the app or app store
    // This requires the web redirect page to be deployed at lunakraft.com
    if (userId != null) {
      return 'https://$BASE_DOMAIN/post/$postId?user=$userId&utm_source=instagram_story';
    } else {
      return 'https://$BASE_DOMAIN/post/$postId?utm_source=instagram_story';
    }
  }
  
  /// Generate a shareable link that includes both app and web URLs
  static String generateShareableProfileLink(DocumentReference userRef) {
    final userId = userRef.id;
    
    // Direct app URL
    final appUrl = 'lunakraft://lunakraft.com/profile/$userId';
    
    // Create a comprehensive share message
    return 'Check out this profile on Luna Kraft! ✨\n\n'
        'Open in app: $appUrl\n\n'
        'Don\'t have the app? Download Luna Kraft:\n'
        '📱 iOS: https://apps.apple.com/app/luna-kraft\n'
        '🤖 Android: https://play.google.com/store/apps/details?id=com.flutterflow.lunakraft\n\n'
        'Join the dreamy community at lunakraft.com';
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
    final queryParams = uri.queryParameters;
    
    if (pathSegments.length >= 2) {
      final linkType = pathSegments[0];
      final resourceId = pathSegments[1];
      
      switch (linkType) {
        case 'profile':
          // Navigate to user profile
          context.pushNamed('UserProfile', pathParameters: {'userId': resourceId});
          break;
          
        case 'post':
          // Navigate to specific post
          final userId = queryParams['user'];
          
          print('Navigating to post: $resourceId with user: $userId');
          
          // Navigate to the detailed post page
          context.pushNamed(
            'Detailedpost',
            queryParameters: {
              'docref': resourceId,
              if (userId != null) 'userref': userId,
            },
          );
          break;
          
        default:
          print('Unknown deep link type: $linkType');
          // Navigate to home page as fallback
          context.go('/');
      }
    } else {
      print('Invalid deep link format, navigating to home');
      context.go('/');
    }
  }
  
  /// Handle web-based deep links (for users who don't have the app installed)
  static void handleWebDeepLink(BuildContext context, Uri uri) {
    print('Handling web deep link: $uri');
    
    final pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;
    
    // Check if this is a post link
    if (pathSegments.length >= 2 && pathSegments[0] == 'post') {
      final postId = pathSegments[1];
      final userId = queryParams['user'];
      
      // Try to open the app first
      final appLink = generatePostLink(
        FirebaseFirestore.instance.collection('posts').doc(postId),
        userRef: userId != null 
          ? FirebaseFirestore.instance.collection('User').doc(userId)
          : null,
      );
      
      // Attempt to launch the app
      url_launcher.launchUrl(
        Uri.parse(appLink),
        mode: url_launcher.LaunchMode.externalApplication,
      ).catchError((error) {
        // If app launch fails, redirect to app store
        print('App not installed, redirecting to store');
        launchAppStore();
      });
    } else {
      // For other links, just redirect to app store
      launchAppStore();
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