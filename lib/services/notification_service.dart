import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/schema/notifications_record.dart';
import '/flutter_flow/nav/nav.dart';
import '/widgets/modern_notification_toast.dart';
import '/pages/notification_page/notification_page_widget.dart';

// Handle background messages when app is closed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized since this can run when app is terminated
  try {
    // This is necessary even if it was initialized elsewhere
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
    print('Background message data: ${message.data}');

    // Get notification content
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? 'You have a new notification';

    // Create notification plugin instance for background notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notification plugin for background notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Don't provide callback here since app is in background
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'luna_kraft_channel', // Same ID as in manifest
        'LunaKraft Notifications',
        description: 'Social interaction notifications for LunaKraft',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      // Use unique ID based on timestamp
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'luna_kraft_channel', // Same channel ID used above
          'LunaKraft Notifications',
          channelDescription: 'Social interaction notifications for LunaKraft',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/notification_icon',
          // Add these for better visibility
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.isNotEmpty ? json.encode(message.data) : null,
    );

    print('Background notification displayed successfully');
  } catch (e) {
    print('Error in background message handler: $e');
  }
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

  // Method to handle background messages internally
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print(
        'NotificationService handling background message: ${message.messageId}');

    try {
      // Get notification content
      final title = message.notification?.title ?? 'New Notification';
      final body = message.notification?.body ?? 'You have a new notification';

      // Use the FlutterLocalNotificationsPlugin instance
      // Initialize notification plugin for background notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

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
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'luna_kraft_channel',
          'LunaKraft Notifications',
          description: 'Social interaction notifications for LunaKraft',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'luna_kraft_channel',
            'LunaKraft Notifications',
            channelDescription:
                'Social interaction notifications for LunaKraft',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@drawable/notification_icon',
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.isNotEmpty ? json.encode(message.data) : null,
      );

      print('Background notification displayed through service');
    } catch (e) {
      print('Error in _handleBackgroundMessage: $e');
    }
  }

  // Initialize notification service
  Future<void> initialize() async {
    try {
      print('Initializing NotificationService...');
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Set up foreground notification handling
      await _setupForegroundNotificationHandling();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // For iOS, configure APNs first with proper settings
      if (Platform.isIOS) {
        try {
          // Check APNs token
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          print('Initial APNS token: ${apnsToken ?? "null"}');
          
          // Clear badge count on iOS
          await clearIOSBadgeCount();
        } catch (e) {
          print('Error getting initial APNS token: $e');
        }
      }

      // Request permissions and register device
      await requestPermission();

      // Set up message handlers
      _setupMessageHandlers();

      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
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
          AndroidInitializationSettings('@drawable/notification_icon');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            'luna_kraft_category',
            actions: [
              DarwinNotificationAction.plain('open', 'Open'),
            ],
            options: {
              DarwinNotificationCategoryOption.allowAnnouncement,
            },
          ),
        ],
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
      
      // Clear iOS badge count when initializing notifications
      if (Platform.isIOS) {
        await clearIOSBadgeCount();
      }

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
        
        // Clear iOS badge count when initializing with fallback
        if (Platform.isIOS) {
          await clearIOSBadgeCount();
        }

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
          playSound: true,
          showBadge: true,
          ledColor: Color(0xFFE040FB),
        );

        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(channel);
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
    
    // Clear iOS badge when setting up foreground notifications
    if (Platform.isIOS) {
      await clearIOSBadgeCount();
    }
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

      // Only show in-app notification (don't trigger system notification)
      // This prevents duplicate notifications since our Cloud Function will
      // handle push notifications for background/terminated app states
      showInAppNotification(notificationData);
      
      // Don't show system notification in foreground
      // System notifications should only be shown when app is in background
      // await _showLocalNotification(
      //   title: message.notification?.title ?? 'New Notification',
      //   body: message.notification?.body ?? 'You have a new notification',
      //   payload: message.data.isNotEmpty ? json.encode(message.data) : null,
      // );
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
    print('\n==== NOTIFICATION TAP HANDLER ====');
    print('Raw notification data: $data');

    final notificationData = _extractNotificationDataFromMap(data);

    // Check app lifecycle state first - if app is not resumed, we should avoid UI operations
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      print('App is not in resumed state, delaying notification handling');

      // Schedule this to be handled when app becomes active again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _delayedHandleNotificationTap(notificationData);
      });
      return;
    }

    // Get build context from the global navigator key
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      print('No active context available for navigation');
      return;
    }

    // Use Future.microtask to avoid build/layout issues with immediate navigation
    Future.microtask(() {
      // Make sure context is still valid
      if (!context.mounted) return;

      _navigateBasedOnNotification(context, notificationData);
    });
    print('==== END NOTIFICATION TAP HANDLER ====\n');
  }

  // Method to handle notifications after a delay when app becomes active
  void _delayedHandleNotificationTap(NotificationPayload notificationData) {
    // Get build context from the global navigator key
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      print('No active context available for delayed navigation');
      return;
    }

    // Use Future.microtask to avoid build/layout issues with immediate navigation
    Future.microtask(() {
      if (!context.mounted) return;
      _navigateBasedOnNotification(context, notificationData);
    });
  }

  // Extracted navigation logic to avoid code duplication
  void _navigateBasedOnNotification(
      BuildContext context, NotificationPayload notificationData) {
    if (!context.mounted) return;

    print('\n==== NAVIGATING BASED ON NOTIFICATION ====');
    print('Notification type: ${notificationData.type}');
    print('Post ID: ${notificationData.postId}');
    print('User ID: ${notificationData.madeById}');
    print('Is follow request: ${notificationData.isFollowRequest}');
    print('Is like: ${notificationData.isLike}');

    // Navigate based on notification type
    if (notificationData.isFollowRequest) {
      try {
        print('Navigating to user profile: ${notificationData.madeById}');

        // Check if the madeById is a full document path or just an ID
        String userId = notificationData.madeById ?? '';
        if (userId.isEmpty) {
          print('No user ID found for navigation');
          return;
        }

        // Make sure we're always using a clean user ID (not a path)
        if (userId.contains('/')) {
          final parts = userId.split('/');
          userId = parts.last;
          print('Extracted user ID from path: $userId');
        }

        // Make sure we have a valid ID before navigating
        if (userId.isNotEmpty) {
          print('Navigating to profile with ID: $userId');

          // Use a direct push with the string ID parameter
          context.pushNamed(
            'Userpage',
            queryParameters: {'profileparameter': userId},
          );
        }
      } catch (e) {
        print('Error navigating to user profile: $e');
      }
      print('==== END NAVIGATION ====');
      return;
    }

    // Handle likes, comments, and replies - they all navigate to the post
    if (notificationData.isLike ||
        notificationData.isReply ||
        notificationData.type == 'comment') {
      String postId = notificationData.postId ?? '';
      if (postId.isEmpty) {
        print('No post ID found for navigation');
        print('==== END NAVIGATION ====');
        return;
      }

      print('Navigating to post: $postId');

      // Clean up the post ID if it's a full path
      if (postId.contains('/')) {
        final parts = postId.split('/');
        postId = parts.last;
        print('Extracted post ID from path: $postId');
      }

      // Verify that the post exists before navigating
      print('Fetching post document for verification');
      FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get()
          .then((postDoc) {
        if (!context.mounted) return;

        if (!postDoc.exists) {
          print('Post document not found, cannot navigate');
          _showErrorDialog(context, 'Post not found',
              'The post you were trying to view no longer exists.');
          print('==== END NAVIGATION ====');
          return;
        }

        print('Post exists. Post data: ${postDoc.data()}');

        // Extract the user ID from the post document
        final posterReference = postDoc.data()?['poster'] as DocumentReference?;
        String? posterUserId;

        if (posterReference != null) {
          print(
              'Poster reference from post: $posterReference (type: ${posterReference.runtimeType})');
          posterUserId = posterReference.id;
          print('Extracted posterUserId from DocumentReference: $posterUserId');
        } else {
          print('No poster reference found in post document');
        }

        // For comments and replies, we want to scroll to the comments section
        bool showComments =
            notificationData.isReply || notificationData.type == 'comment';

        // Use the clean post ID and extracted user ID (or null if not found)
        print(
            'Pushing to Detailedpost with: docref=$postId, userref=$posterUserId, showComments=$showComments');

        // Navigate using string IDs rather than document references
        context.pushNamed(
          'Detailedpost',
          queryParameters: {
            'docref': postId,
            'userref': posterUserId ?? '',
            'showComments': showComments.toString(),
          },
        );

        print('==== END NAVIGATION ====');
      }).catchError((error) {
        print('Error fetching post document: $error');
        if (context.mounted) {
          _showErrorDialog(
              context, 'Error', 'There was a problem loading the post.');
        }
        print('==== END NAVIGATION ====');
      });

      return;
    }

    print(
        'No navigation action for notification type: ${notificationData.type}');
    print('==== END NAVIGATION ====');
  }

  // Show an error dialog with a title and message
  void _showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Extract notification data from FCM message
  NotificationPayload _extractNotificationData(RemoteMessage message) {
    return _extractNotificationDataFromMap(message.data);
  }

  // Extract notification data from map
  NotificationPayload _extractNotificationDataFromMap(
    Map<String, dynamic> data,
  ) {
    print('Extracting notification data: $data');

    // Extract and clean up the post ID to ensure it's usable
    String? postId;
    dynamic postValue = data['post_ref'];

    if (postValue != null) {
      // Handle document reference or string
      if (postValue is DocumentReference) {
        postId = postValue.id;
      } else if (postValue is String) {
        // If it contains slashes, extract the ID part
        if (postValue.contains('/')) {
          final parts = postValue.split('/');
          // Get the last part which should be the actual ID
          if (parts.length >= 2) {
            postId = parts.last;
          }
        } else {
          // Already an ID
          postId = postValue;
        }
      } else if (postValue is Map) {
        // Handle maps that might contain path or ID info
        if (postValue.containsKey('id')) {
          postId = postValue['id'].toString();
        } else if (postValue.containsKey('_path') &&
            postValue['_path'] is String) {
          final path = postValue['_path'] as String;
          final parts = path.split('/');
          if (parts.length >= 2) {
            postId = parts.last;
          }
        }
      }
    }

    // Extract and clean up the madeById to ensure it's usable
    dynamic madeByValue = data['made_by'];
    String? madeById;

    // Handle different formats of made_by data
    if (madeByValue != null) {
      // Handle DocumentReference directly
      if (madeByValue is DocumentReference) {
        madeById = madeByValue.id;
      }
      // Convert to string if it's not already
      else if (madeByValue is String) {
        madeById = madeByValue;

        // If it's a document path like "/User/abc123"
        if (madeById.contains('/')) {
          final parts = madeById.split('/');
          // Get the last part which should be the actual ID
          if (parts.length >= 2) {
            madeById = parts.last;
          }
        }
      }
      // Handle case where we might have a document reference or map object
      else if (madeByValue is Map) {
        if (madeByValue.containsKey('id')) {
          madeById = madeByValue['id'].toString();
        } else if (madeByValue.containsKey('_path') &&
            madeByValue['_path'] is String) {
          String path = madeByValue['_path'];
          final parts = path.split('/');
          if (parts.length >= 2) {
            madeById = parts.last;
          }
        }
      }
      // Try to get the id if it's some other object with id property
      else {
        try {
          madeById = madeByValue.toString();
        } catch (_) {
          madeById = null;
        }
      }
    }

    print('Extracted postId: $postId, madeById: $madeById');

    // Create and return the payload
    return NotificationPayload(
      title: data['title'] ?? 'New Notification',
      body: data['body'] ?? '',
      isLike: data['is_a_like'] == 'true' || data['is_a_like'] == true,
      isFollowRequest: data['is_follow_request'] == 'true' ||
          data['is_follow_request'] == true,
      isReply: data['is_reply'] == 'true' || data['is_reply'] == true,
      postId: postId,
      madeById: madeById,
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
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'luna_kraft_channel',
            'LunaKraft Notifications',
            channelDescription:
                'Social interaction notifications for LunaKraft',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@drawable/notification_icon',
            enableLights: true,
            enableVibration: true,
            playSound: true,
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'luna_kraft_category',
          ),
        ),
        payload: payload,
      );
      print('Local notification shown successfully');
    } catch (e) {
      print('Error showing local notification: $e');

      // Try fallback without custom icon
      try {
        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title,
          body,
          NotificationDetails(
            android: const AndroidNotificationDetails(
              'luna_kraft_channel',
              'LunaKraft Notifications',
              channelDescription:
                  'Social interaction notifications for LunaKraft',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: payload,
        );
        print('Fallback notification shown successfully');
      } catch (fallbackError) {
        print('Error showing fallback notification: $fallbackError');
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
      if (context != null && context.mounted) {
        // Try using the ModernNotificationOverlay first
        try {
          // Use the modern notification overlay
          // This is safer as it uses a stateful widget with proper lifecycle management
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
            // Make sure we're using a valid context for ScaffoldMessenger
            // and check that the scaffold is still mounted
            if (context.mounted) {
              final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
              if (scaffoldMessenger != null) {
                // Use hideCurrentSnackBar to prevent stacking issues
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('${notification.title}: ${notification.body}'),
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
              } else {
                print('No ScaffoldMessenger found in context');
              }
            } else {
              print('Context is no longer mounted for Snackbar');
            }
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
    try {
      // Request FCM permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
      _hasNotificationPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      // Request local notification permissions on iOS
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      // Get FCM token and save it
      if (_hasNotificationPermission) {
        await _registerDeviceWithFCM();
      }

      return _hasNotificationPermission;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      _hasNotificationPermission = false;
      return false;
    }
  }

  // Monitor connectivity changes
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isConnected = true;

  void _setupConnectivityMonitor() {
    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isConnected = result != ConnectivityResult.none;
      print(
          'Initial connectivity status: ${_isConnected ? 'Connected' : 'Disconnected'}');
    });

    // Listen for connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;

      print(
          'Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}');

      // If we just regained connection, try to reconnect Firestore and re-register FCM
      if (!wasConnected && _isConnected) {
        print('Network reconnected, refreshing Firebase connections');

        // Re-register device with FCM if user is logged in
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _registerDeviceWithFCM().catchError((e) {
            print('Error re-registering device with FCM: $e');
          });
        }
      }
    });
  }

  // Clean up resources
  Future<void> dispose() async {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // Register the device with Firebase Cloud Messaging with retry logic
  Future<void> _registerDeviceWithFCM() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Add retry logic for getting the FCM token
    String? token;
    int retryCount = 0;
    const maxRetries = 3;

    while (token == null && retryCount < maxRetries) {
      try {
        // For iOS, check if we have APNS token first
        if (Platform.isIOS) {
          // Try to get APNS token first if we're on iOS
          try {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            print('Current APNS token: $apnsToken');
            
            if (apnsToken == null) {
              // If APNS token is not available, wait a bit and try again
              print('APNS token not available yet, waiting...');
              retryCount++;
              await Future.delayed(Duration(seconds: 2 * retryCount));
              continue;
            }
            
            // Ensure we have proper background notification permissions
            await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
            
            // Configure requested notification permissions explicitly
            NotificationSettings settings = await _firebaseMessaging.requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: true,  // Allow provisional in case user hasn't allowed yet
              sound: true,
            );
            print('iOS Notification settings status: ${settings.authorizationStatus}');
          } catch (e) {
            print('Error getting APNS token: $e');
          }
        }
        
        // Now try to get FCM token
        token = await _firebaseMessaging.getToken();
        if (token == null) {
          retryCount++;
          await Future.delayed(
              Duration(seconds: 2 * retryCount)); // Exponential backoff
          continue;
        }
      } catch (e) {
        print('Error getting FCM token (attempt ${retryCount + 1}): $e');
        retryCount++;
        await Future.delayed(Duration(seconds: 2 * retryCount));
        continue;
      }
    }

    if (token == null) {
      print('Failed to get FCM token after $maxRetries attempts');
      return;
    }

    print('FCM Token: $token');

    // Add retry logic for Firestore operations
    retryCount = 0;
    bool updateSuccess = false;

    while (!updateSuccess && retryCount < maxRetries) {
      try {
        // Try to save the token to the user's record in Firestore
        await UserRecord.collection.doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'devicePlatform': Platform.isIOS ? 'iOS' : 'Android',  // Store platform to send appropriate payloads
          'notificationsEnabled': true,  // Track that notifications are enabled
        });
        updateSuccess = true;
        
        // Store token in SharedPreferences for reliable recovery
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        
      } catch (e) {
        print(
            'Error updating FCM token in Firestore (attempt ${retryCount + 1}): $e');
        retryCount++;

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }
    }

    if (!updateSuccess) {
      print(
          'Failed to update FCM token in Firestore after $maxRetries attempts');
    }
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

  // Add a lifecycle observer to handle notifications properly
  void _setupLifecycleObserver() {
    WidgetsBinding.instance.addObserver(new _AppLifecycleObserver(this));
  }

  // Set up token refresh monitoring
  void _setupTokenRefreshMonitoring() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCM token refreshed: ${newToken.substring(0, 10)}...');

      // Update token in Firestore for the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          FirebaseFirestore.instance.collection('User').doc(user.uid).update({
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });

          print('FCM token updated in Firestore');
        } catch (e) {
          print('Error updating FCM token in Firestore: $e');
        }
      }
    }, onError: (e) {
      print('Error in FCM token refresh listener: $e');
    });
  }

  // Method to clear iOS badge count
  Future<void> clearIOSBadgeCount() async {
    if (!Platform.isIOS) return;
    
    try {
      // Clear iOS badge count using the FlutterLocalNotificationsPlugin
      final iOSPlatformSpecific = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
              
      if (iOSPlatformSpecific != null) {
        // Request badge permission
        await iOSPlatformSpecific.requestPermissions(
          alert: true, 
          badge: true, 
          sound: true,
        );
        
        // Clear all notifications which also clears the badge
        await iOSPlatformSpecific.cancelAll();
      }
      
      // Also use Firebase Messaging to clear badge
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        badge: false,
      );
      
      print('iOS badge count cleared successfully');
    } catch (e) {
      print('Error clearing iOS badge count: $e');
    }
  }
}

// Lifecycle observer to handle app state changes for notifications
class _AppLifecycleObserver with WidgetsBindingObserver {
  final NotificationService _notificationService;

  _AppLifecycleObserver(this._notificationService) {
    // Register immediately upon creation
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      // App came back to the foreground
      print('App resumed - handling any pending notifications');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App went to background or was killed
      print('App paused or detached - removing any active notifications');
      // Clear any overlay notifications
      ModernNotificationOverlay.dismiss();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
