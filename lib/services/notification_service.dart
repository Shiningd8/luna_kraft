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

    // Set up the lifecycle observer to handle app state changes
    _setupLifecycleObserver();

    // Set up connectivity monitoring
    _setupConnectivityMonitor();

    // Set up a listener for notifications to ensure we catch all of them
    _setupNotificationListener();

    // Set up FCM token refresh monitoring for more reliable notifications
    _setupTokenRefreshMonitoring();
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

      // Show both in-app and system notification
      showInAppNotification(notificationData);

      // Also show system notification
      await _showLocalNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? 'You have a new notification',
        payload: message.data.isNotEmpty ? json.encode(message.data) : null,
      );
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
        });
        updateSuccess = true;
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
              'made_by': UserRecord.collection.doc(user.uid),
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

  // Manual test notification function with additional debugging
  Future<void> manualTestNotification() async {
    print('Manually testing notification');

    try {
      // Create test notification payload
      final testPayload = NotificationPayload(
        title: 'Test Notification',
        body: 'This is a test notification',
        isLike: true, // Test like notification
        postId: '12345', // Simple test post ID
        madeById: 'testuser',
        type: 'test',
      );

      // First show an in-app notification
      print('Showing in-app test notification');
      showInAppNotification(testPayload);

      // Create a more realistic notification for testing
      print('Creating test notification with all parameters filled');
      showInAppNotification(
        NotificationPayload(
          title: 'Like Notification',
          body: 'User123 liked your post',
          isLike: true,
          isFollowRequest: false,
          isReply: false,
          postId: 'postID123',
          madeById: 'userID456',
          type: 'like',
        ),
      );

      // Print out current contexts and routes for debugging
      final context = appNavigatorKey.currentContext;
      print('Current context available: ${context != null}');
      if (context != null) {
        print('Current route: ${ModalRoute.of(context)?.settings.name}');
      }

      print('Test notifications shown successfully');
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }

  // Add a lifecycle observer to handle notifications properly
  void _setupLifecycleObserver() {
    WidgetsBinding.instance.addObserver(new _AppLifecycleObserver(this));
  }

  // Comprehensive debug method to test all notification states
  Future<void> debugNotificationSystem() async {
    print('\n===== NOTIFICATION SYSTEM DEBUG =====');

    // 1. Check FCM Token
    try {
      final token = await _firebaseMessaging.getToken();
      print('FCM Token Status: ${token != null ? "Valid" : "Missing"}');
      print('FCM Token: $token');
    } catch (e) {
      print('Error getting FCM token: $e');
    }

    // 2. Check Notification Permissions
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      print('\nNotification Permission Status:');
      print('Authorization Status: ${settings.authorizationStatus}');
      print('Alert Enabled: ${settings.alert}');
      print('Badge Enabled: ${settings.badge}');
      print('Sound Enabled: ${settings.sound}');

      if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          print('Android System Notifications Enabled: $enabled');
        }
      }
    } catch (e) {
      print('Error checking notification permissions: $e');
    }

    // 3. Check Notification Channel (Android)
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final channels = await androidPlugin.getNotificationChannels();
          print('\nNotification Channels:');
          if (channels != null) {
            for (final channel in channels) {
              print('Channel ID: ${channel.id}');
              print('Channel Name: ${channel.name}');
              print('Channel Importance: ${channel.importance}');
              print('Channel Description: ${channel.description}');
              print('---');
            }
          } else {
            print('No notification channels found');
          }
        }
      } catch (e) {
        print('Error checking notification channels: $e');
      }
    }

    // 4. Test Different Notification Types
    print('\nTesting notification types:');

    // Test in-app notification
    try {
      showInAppNotification(
        NotificationPayload(
          title: 'Debug Test',
          body: 'Testing in-app notification',
          type: 'debug',
        ),
      );
      print('In-app notification test: SUCCESS');
    } catch (e) {
      print('In-app notification test: FAILED - $e');
    }

    // Test local notification
    try {
      await _showLocalNotification(
        title: 'Debug Test',
        body: 'Testing local notification',
        payload: json.encode({
          'title': 'Debug Test',
          'body': 'Testing local notification',
          'type': 'debug',
        }),
      );
      print('Local notification test: SUCCESS');
    } catch (e) {
      print('Local notification test: FAILED - $e');
    }

    // Test FCM notification
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationsRecord.collection.add({
          'title': 'Debug Test',
          'body': 'Testing FCM notification',
          'is_read': false,
          'made_by': UserRecord.collection.doc(user.uid),
          'made_to': user.uid,
          'date': FieldValue.serverTimestamp(),
          'is_a_like': false,
          'is_follow_request': false,
          'is_reply': false,
          'type': 'debug',
        });
        print('FCM notification test: SUCCESS (document created)');
      } else {
        print('FCM notification test: SKIPPED (no user logged in)');
      }
    } catch (e) {
      print('FCM notification test: FAILED - $e');
    }

    print('===== NOTIFICATION SYSTEM DEBUG END =====\n');
  }

  // Add this new method
  void _setupNotificationListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen for notifications where the current user is the recipient
    NotificationsRecord.collection
        .where('made_to', isEqualTo: user.uid)
        .where('is_read', isEqualTo: false)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      // Process any new notifications
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notification = NotificationsRecord.fromSnapshot(change.doc);
          print(
              'New notification detected locally: ${notification.reference.id}');

          // Skip if already processed (use a timestamp check to avoid duplicates)
          final now = DateTime.now();
          final notificationTime = notification.date ?? now;
          final timeDiff = now.difference(notificationTime).inMinutes;

          // Only process notifications from the last 5 minutes to avoid old ones
          if (timeDiff <= 5) {
            _processLocalNotification(notification);
          }
        }
      }
    }, onError: (error) {
      print('Error listening for notifications: $error');
    });

    print('Notification listener set up for user: ${user.uid}');
  }

  // Add this new method to process notifications detected locally
  Future<void> _processLocalNotification(
      NotificationsRecord notification) async {
    try {
      print('Processing local notification: ${notification.reference.id}');

      // Get sender username
      String senderUsername = notification.madeByUsername;
      if (senderUsername.isEmpty && notification.madeBy != null) {
        try {
          final senderDoc = await notification.madeBy!.get();
          if (senderDoc.exists) {
            final userData = senderDoc.data() as Map<String, dynamic>?;
            senderUsername =
                userData?['user_name'] ?? userData?['userName'] ?? 'Someone';
          }
        } catch (e) {
          print('Error fetching sender details: $e');
          senderUsername = 'Someone';
        }
      }

      // Construct notification message based on type
      String title = 'New Notification';
      String body = '';

      if (notification.isALike) {
        title = 'New Like';
        body = '$senderUsername liked your post';
      } else if (notification.isFollowRequest) {
        if (notification.status == 'pending') {
          title = 'Follow Request';
          body = '$senderUsername requested to follow you';
        } else {
          title = 'New Follower';
          body = '$senderUsername started following you';
        }
      } else if (notification.isReply) {
        title = 'New Reply';
        body = '$senderUsername replied to your comment';
      } else {
        title = 'New Comment';
        body = '$senderUsername commented on your post';
      }

      // Extract user ID and post ID from DocumentReferences
      String? madeById;
      String? postId;

      // Handle madeBy reference
      if (notification.madeBy != null) {
        madeById = notification.madeBy!.id;
      }

      // Handle postRef reference
      if (notification.postRef != null) {
        postId = notification.postRef!.path;
      }

      // Create a payload for the notification
      final payload = NotificationPayload(
        title: title,
        body: body,
        isLike: notification.isALike,
        isFollowRequest: notification.isFollowRequest,
        isReply: notification.isReply,
        postId: postId,
        madeById: madeById,
        type: notification.isALike
            ? 'like'
            : notification.isFollowRequest
                ? 'follow'
                : notification.isReply
                    ? 'reply'
                    : 'comment',
      );

      // Show in-app notification
      showInAppNotification(payload);

      // Also show a local notification if app is in background
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await _showLocalNotification(
          title: title,
          body: body,
          payload: json.encode({
            'title': title,
            'body': body,
            'is_a_like': notification.isALike.toString(),
            'is_follow_request': notification.isFollowRequest.toString(),
            'is_reply': notification.isReply.toString(),
            'post_ref': postId,
            'made_by': madeById,
            'type': notification.isALike
                ? 'like'
                : notification.isFollowRequest
                    ? 'follow'
                    : notification.isReply
                        ? 'reply'
                        : 'comment',
          }),
        );
      }

      print('Local notification processed successfully');
    } catch (e) {
      print('Error processing local notification: $e');
    }
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
