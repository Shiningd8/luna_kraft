import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/schema/notifications_record.dart';
import '/flutter_flow/nav/nav.dart';
import '/widgets/modern_notification_toast.dart';
import '/pages/notification_page/notification_page_widget.dart';

// Handle background messages when app is closed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure you've initialized Firebase
  // await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream controller for in-app notification events
  final StreamController<NotificationPayload> _notificationStreamController =
      StreamController<NotificationPayload>.broadcast();

  // Expose stream for listening to notification events in the app
  Stream<NotificationPayload> get notificationStream =>
      _notificationStreamController.stream;

  // Store notification permission status
  bool _hasNotificationPermission = false;
  bool get hasNotificationPermission => _hasNotificationPermission;

  // Initialize notification service
  Future<void> initialize() async {
    // Set up handling messages in background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up foreground notification handling
    await _setupForegroundNotificationHandling();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permissions and register device
    await requestPermission();

    // Set up message handlers
    _setupMessageHandlers();

    // Handle initial notification if app was opened from a notification
    await _handleInitialNotification();

    // Save FCM token to user's Firestore record if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _registerDeviceWithFCM();
    }
  }

  // Debug method to print FCM token - kept for development purposes
  Future<String?> debugPrintFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('FCM TOKEN: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      // Try with custom notification icon first
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(
        'notification_icon',
      ); // Without @drawable prefix

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create notification channel (Android only)
      await _createNotificationChannel();

      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing with custom icon: $e');

      // Try with default app icon as fallback
      try {
        const AndroidInitializationSettings fallbackSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        final DarwinInitializationSettings fallbackSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

        final InitializationSettings fallbackSettings = InitializationSettings(
          android: fallbackSettingsAndroid,
          iOS: fallbackSettingsIOS,
        );

        await _flutterLocalNotificationsPlugin.initialize(
          fallbackSettings,
          onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        );

        // Create notification channel (Android only)
        await _createNotificationChannel();

        print('Local notifications initialized with fallback icon');
      } catch (fallbackError) {
        print(
          'Failed to initialize notifications even with fallback: $fallbackError',
        );
      }
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      try {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'luna_kraft_channel',
          'LunaKraft Notifications',
          description: 'Social interaction notifications for LunaKraft',
          importance: Importance.max,
          enableLights: true,
          enableVibration: true,
          showBadge: true,
        );

        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(channel);

          // Force clear existing notifications to update icon
          await androidPlugin.cancelAll();

          print('Notification channel created successfully');
        } else {
          print('Android notification plugin not available');
        }
      } catch (e) {
        print('Error creating notification channel: $e');
      }
    }
  }

  // Handle notification taps
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = json.decode(payload);
        _handleNotificationTap(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Set up foreground notification handling
  Future<void> _setupForegroundNotificationHandling() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Set up all message handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when user taps on notification and app is in background but open
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Extract notification data
      final notificationData = _extractNotificationData(message);

      // When app is in foreground, only show in-app notification, not system notification
      showInAppNotification(notificationData);

      // No longer show system notification when app is in foreground
      // This prevents duplicate notifications (in-app and system)
    }
  }

  // Handle when app is opened from notification when in background
  Future<void> _handleNotificationOpenedApp(RemoteMessage message) async {
    print('Notification opened app from background state!');
    print('Message data: ${message.data}');

    _handleNotificationTap(message.data);
  }

  // Handle initial notification if app was opened from a notification
  Future<void> _handleInitialNotification() async {
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('App started by notification: ${initialMessage.data}');
      _handleNotificationTap(initialMessage.data);
    }
  }

  // Handle notification tap navigation and actions
  void _handleNotificationTap(Map<String, dynamic> data) {
    final notificationData = _extractNotificationDataFromMap(data);

    // Get build context from the global navigator key
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      print('No active context available for navigation');
      return;
    }

    // Navigate based on notification type
    if (notificationData.isFollowRequest) {
      context.pushNamed(
        'Userpage',
        queryParameters: {'profileparameter': notificationData.madeById},
      );
    } else if (notificationData.postId != null) {
      context.pushNamed(
        'Detailedpost',
        queryParameters: {
          'docref': notificationData.postId,
          'userref': notificationData.madeById,
          'showComments': (!notificationData.isLike).toString(),
        },
      );
    } else {
      // Use the same navigation approach as the bell icon
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const NotificationPageWidget(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  // Extract notification data from FCM message
  NotificationPayload _extractNotificationData(RemoteMessage message) {
    return _extractNotificationDataFromMap(message.data);
  }

  // Extract notification data from map
  NotificationPayload _extractNotificationDataFromMap(
    Map<String, dynamic> data,
  ) {
    return NotificationPayload(
      title: data['title'] ?? 'New Notification',
      body: data['body'] ?? '',
      isLike: data['is_a_like'] == 'true',
      isFollowRequest: data['is_follow_request'] == 'true',
      isReply: data['is_reply'] == 'true',
      postId: data['post_ref'],
      madeById: data['made_by'],
      type: data['type'] ?? 'general',
    );
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Try to use our custom icon, with multiple possible path formats
      const String notificationIcon =
          '@drawable/notification_icon'; // Use explicit drawable path

      // Android notification details
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'luna_kraft_channel',
        'LunaKraft Notifications',
        channelDescription: 'Social interaction notifications for LunaKraft',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: notificationIcon, // Use explicit drawable path
        enableLights: true,
        enableVibration: true,
        color: const Color(0xFFE040FB), // Match purple color from manifest
        colorized: true,
        largeIcon: const DrawableResourceAndroidBitmap(
          '@mipmap/ic_launcher',
        ), // App icon as large icon
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond, // Unique ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      print('Local notification shown successfully');
    } catch (e) {
      print('Error showing local notification: $e');

      // Try again with the default app icon if the custom icon failed
      try {
        const DarwinNotificationDetails fallbackIOSDetails =
            DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final AndroidNotificationDetails fallbackAndroidDetails =
            AndroidNotificationDetails(
          'luna_kraft_channel',
          'LunaKraft Notifications',
          channelDescription: 'Social interaction notifications for LunaKraft',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher', // Fallback to launcher icon
          enableLights: true,
          enableVibration: true,
          color: const Color(0xFFE040FB), // Match purple color
          colorized: true,
        );

        final NotificationDetails fallbackDetails = NotificationDetails(
          android: fallbackAndroidDetails,
          iOS: fallbackIOSDetails,
        );

        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecond,
          title,
          body,
          fallbackDetails,
          payload: payload,
        );
        print('Fallback notification shown successfully');
      } catch (fallbackError) {
        print('Even fallback notification failed: $fallbackError');
        // Fallback to just showing the in-app notification
        final notification = NotificationPayload(
          title: title,
          body: body,
          type: 'test',
        );
        showInAppNotification(notification);
      }
    }
  }

  // Show an in-app notification
  void showInAppNotification(NotificationPayload notification) {
    try {
      // First, send to stream for any listeners
      _notificationStreamController.add(notification);

      // Get the app's navigator context
      final context = appNavigatorKey.currentContext;
      if (context != null) {
        // Try using the ModernNotificationOverlay first
        try {
          // Use the modern notification overlay
          ModernNotificationOverlay.show(
            context: context,
            notification: notification,
            onTap: () {
              _handleNotificationTap({
                'title': notification.title,
                'body': notification.body,
                'is_a_like': notification.isLike.toString(),
                'is_follow_request': notification.isFollowRequest.toString(),
                'is_reply': notification.isReply.toString(),
                'post_ref': notification.postId,
                'made_by': notification.madeById,
                'type': notification.type,
              });
            },
          );
        } catch (overlayError) {
          print('Error showing overlay notification: $overlayError');

          // Fallback to basic SnackBar if the overlay fails
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${notification.title}: ${notification.body}'),
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'VIEW',
                  onPressed: () {
                    _handleNotificationTap({
                      'title': notification.title,
                      'body': notification.body,
                      'is_a_like': notification.isLike.toString(),
                      'is_follow_request':
                          notification.isFollowRequest.toString(),
                      'is_reply': notification.isReply.toString(),
                      'post_ref': notification.postId,
                      'made_by': notification.madeById,
                      'type': notification.type,
                    });
                  },
                ),
              ),
            );
          } catch (snackbarError) {
            print('Error showing fallback snackbar: $snackbarError');
          }
        }
      } else {
        print('No valid context available for showing in-app notification');
      }
    } catch (e) {
      print('Error in showInAppNotification: $e');
    }
  }

  // Request notification permissions
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      // Request permissions for iOS
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      _hasNotificationPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
    } else {
      // For Android 13+ (API 33+), we need to explicitly request POST_NOTIFICATIONS permission
      try {
        // First request FCM permission
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // Then request system permission
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Force the system dialog by showing a notification
          await _requestAndroidNotificationPermission(androidPlugin);
        } else {
          // For older Android versions
          _hasNotificationPermission = true;
        }
      } catch (e) {
        print('Error requesting notification permission: $e');
        _hasNotificationPermission = false;
      }
    }

    // Save permission status to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'notification_permission_granted', _hasNotificationPermission);

    if (_hasNotificationPermission) {
      // Register with FCM
      await _registerDeviceWithFCM();
    }

    return _hasNotificationPermission;
  }

  // Request Android notification permission (specifically for Android 13+)
  Future<void> _requestAndroidNotificationPermission(
      AndroidFlutterLocalNotificationsPlugin androidPlugin) async {
    try {
      // First check if permission is already granted
      final permissionResult = await androidPlugin.areNotificationsEnabled();
      final hasPermission = permissionResult ?? false;

      if (hasPermission) {
        _hasNotificationPermission = true;
        return;
      }

      // For some Android devices, we need to show a notification to trigger the system dialog
      print('Requesting Android notification permission');

      // Since the plugin doesn't have direct permission request methods,
      // we need to use the approach of opening the app settings
      try {
        // Try to open notification settings
        final result = await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'luna_kraft_channel',
            'LunaKraft Notifications',
            description: 'Social interaction notifications for LunaKraft',
            importance: Importance.max,
          ),
        );

        print('Notification channel created to prompt for permission');

        // Show a sample notification to trigger the permission dialog
        await _showLocalNotification(
          title: 'Permission Required',
          body: 'Please allow notifications for Luna Kraft',
          payload: '{}',
        );

        // Check permission status again
        final updatedResult = await androidPlugin.areNotificationsEnabled();
        _hasNotificationPermission = updatedResult ?? false;
      } catch (e) {
        print('Error in permission request approach: $e');

        // Fallback to just showing a notification to trigger the system dialog
        await _showLocalNotification(
          title: 'Permission Required',
          body: 'Please allow notifications for Luna Kraft',
          payload: '{}',
        );

        // Check permission status again
        final finalResult = await androidPlugin.areNotificationsEnabled();
        _hasNotificationPermission = finalResult ?? false;
      }

      print(
          'Final Android notification permission status: $_hasNotificationPermission');
    } catch (e) {
      print('Error in _requestAndroidNotificationPermission: $e');
      // Fallback to assuming permission granted on error
      _hasNotificationPermission = true;
    }
  }

  // Register the device with Firebase Cloud Messaging
  Future<void> _registerDeviceWithFCM() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String? token = await _firebaseMessaging.getToken();
    if (token == null) return;

    print('FCM Token: $token');

    // Save the token to the user's record in Firestore
    await UserRecord.collection.doc(user.uid).update({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final notificationRef = NotificationsRecord.collection.doc(notificationId);
    await notificationRef.update({'is_read': true});
  }

  // Test notification method - useful for debugging on emulators
  Future<void> showTestNotification() async {
    print('Showing test notification');

    try {
      // First ensure in-app notification is shown (most reliable)
      showInAppNotification(
        NotificationPayload(
          title: 'Test Notification',
          body: 'This is a test notification to verify your setup',
          type: 'test',
        ),
      );

      print('In-app notification shown successfully');

      // Then try to show a local notification
      try {
        await _showLocalNotification(
          title: 'Test Notification',
          body: 'This is a test notification to verify your setup',
          payload: json.encode({
            'title': 'Test Notification',
            'body': 'This is a test notification',
            'type': 'test',
            'is_a_like': 'false',
            'is_follow_request': 'false',
            'is_reply': 'false',
          }),
        );
        print('System notification sent successfully');
      } catch (e) {
        print('Error showing system notification: $e');
        print('Only the in-app notification was shown');
      }
    } catch (e) {
      print('Failed to show any notifications: $e');
    }
  }

  // Debug notification icons to verify they exist
  Future<void> debugNotificationIcons() async {
    print('\n===== NOTIFICATION ICON DEBUG =====');
    try {
      // Check if the plugin is available
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        print('Android platform-specific implementation not available');
      } else {
        print('Android notification plugin is available');
      }

      // Log the icon resources we're trying to use
      print('Primary icon resource path: @drawable/notification_icon');
      print('Fallback icon resource path: @mipmap/ic_launcher');

      // Output debug information about the current channel
      if (Platform.isAndroid) {
        try {
          final List<AndroidNotificationChannel>? channels =
              await androidPlugin?.getNotificationChannels();

          print('Available notification channels: ${channels?.length ?? 0}');
          if (channels != null) {
            for (final channel in channels) {
              print('Channel ID: ${channel.id}');
              print('Channel Name: ${channel.name}');
              print('Channel Importance: ${channel.importance.value}');
            }
          }
        } catch (e) {
          print('Error retrieving channels: $e');
        }
      }

      print('===== NOTIFICATION ICON DEBUG END =====\n');
    } catch (e) {
      print('Error in debug notification icons: $e');
    }
  }

  // Alternative method to show test notification without using flutter_local_notifications
  Future<void> showTestNotificationAlternative() async {
    print('Showing alternative test notification');

    // First show the in-app notification
    showInAppNotification(
      NotificationPayload(
        title: 'Test Notification',
        body: 'This is a test notification to verify your setup',
        type: 'test',
      ),
    );

    try {
      // Send a direct Firebase message to the device (this is a "self-message")
      // This is useful for testing FCM functionality directly
      final messaging = FirebaseMessaging.instance;

      // Get the FCM token of the current device
      final token = await messaging.getToken();

      if (token != null) {
        print('Sending test FCM message to token: $token');

        // Create a notification for Firestore to trigger the Cloud Function
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await NotificationsRecord.collection.add({
              'title': 'Test Notification',
              'body': 'This is a test FCM notification',
              'is_read': false,
              'made_by': user.uid,
              'made_to': user.uid,
              'date': FieldValue.serverTimestamp(),
              'is_a_like': false,
              'is_follow_request': false,
              'is_reply': false,
              'type': 'test',
            });
            print('Test notification document created in Firestore');
          } catch (e) {
            print('Error creating test notification in Firestore: $e');
          }
        }
      } else {
        print('No FCM token available for self-testing');
      }
    } catch (e) {
      print('Error sending alternative test notification: $e');
    }
  }

  // Simple notification test that avoids most potential issues
  Future<void> showSimpleTestNotification() async {
    print('Showing simple test notification');

    // First show an in-app notification which uses our improved error handling
    final testNotification = NotificationPayload(
      title: 'Simple Test',
      body: 'This is a simple test notification',
      type: 'test',
    );
    showInAppNotification(testNotification);

    // Then try to show a system notification
    try {
      // First make sure the channel exists
      if (Platform.isAndroid) {
        try {
          await _createNotificationChannel();
          print('Created notification channel successfully');
        } catch (channelError) {
          print('Error creating channel: $channelError');
        }

        // Then try to show a notification with minimal properties
        try {
          final AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails(
            'luna_kraft_channel', // channel id
            'LunaKraft Notifications', // channel name
            channelDescription:
                'Social interaction notifications for LunaKraft',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/notification_icon',
          );

          final NotificationDetails platformDetails = NotificationDetails(
            android: androidDetails,
          );

          await _flutterLocalNotificationsPlugin.show(
            1, // Use a simple ID
            'Simple Test',
            'This is a simple test notification',
            platformDetails,
          );

          print('Simple notification shown successfully');
        } catch (e) {
          print('Error showing basic notification: $e');
        }
      }
    } catch (e) {
      print('Error in showSimpleTestNotification: $e');
    }
  }

  // Test notifications with different icon approaches
  Future<void> testNotificationIcons() async {
    print('\n===== TESTING NOTIFICATION ICONS =====');

    // First approach - direct name without path
    try {
      await _flutterLocalNotificationsPlugin.show(
        101,
        'Icon Test 1',
        'Testing notification_icon directly',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_kraft_channel',
            'LunaKraft Notifications',
            channelDescription:
                'Social interaction notifications for LunaKraft',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'notification_icon',
            color: const Color(0xFFE040FB), // Match purple color
            colorized: true,
          ),
        ),
      );
      print('Showed notification with icon: notification_icon');
    } catch (e) {
      print('Error showing notification with direct icon: $e');
    }

    // Second approach - with drawable prefix
    try {
      await _flutterLocalNotificationsPlugin.show(
        102,
        'Icon Test 2',
        'Testing @drawable/notification_icon path',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_kraft_channel',
            'LunaKraft Notifications',
            channelDescription:
                'Social interaction notifications for LunaKraft',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/notification_icon',
            color: const Color(0xFFE040FB), // Match purple color
            colorized: true,
          ),
        ),
      );
      print('Showed notification with icon: @drawable/notification_icon');
    } catch (e) {
      print('Error showing notification with drawable path: $e');
    }

    // Third approach - launcher icon fallback
    try {
      await _flutterLocalNotificationsPlugin.show(
        103,
        'Icon Test 3',
        'Testing launcher icon fallback',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_kraft_channel',
            'LunaKraft Notifications',
            channelDescription:
                'Social interaction notifications for LunaKraft',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFE040FB), // Match purple color
            colorized: true,
          ),
        ),
      );
      print('Showed notification with launcher icon fallback');
    } catch (e) {
      print('Error showing notification with launcher icon: $e');
    }

    print('===== NOTIFICATION ICON TESTS COMPLETE =====\n');
  }

  // Manual test notification function - call this from UI when needed for testing
  Future<void> manualTestNotification() async {
    print('Manually testing notification');

    try {
      // First show an in-app notification
      showInAppNotification(
        NotificationPayload(
          title: 'Test Notification',
          body: 'This is a manual test notification',
          type: 'test',
        ),
      );

      // Then show a system notification
      await _showLocalNotification(
        title: 'Test Notification',
        body: 'This is a manual test notification',
        payload: json.encode({'type': 'test'}),
      );
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }
}

// Class to represent notification payload
class NotificationPayload {
  final String title;
  final String body;
  final bool isLike;
  final bool isFollowRequest;
  final bool isReply;
  final String? postId;
  final String? madeById;
  final String type;

  NotificationPayload({
    required this.title,
    required this.body,
    this.isLike = false,
    this.isFollowRequest = false,
    this.isReply = false,
    this.postId,
    this.madeById,
    this.type = 'general',
  });
}
