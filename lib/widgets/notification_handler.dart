import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/services/notification_service.dart';
import '/services/app_state_tracker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler>
    with WidgetsBindingObserver {
  StreamSubscription<NotificationPayload>? _notificationSubscription;
  bool _isAppActive = true;

  // Overlay entry for debug button
  OverlayEntry? _debugButtonOverlay;

  @override
  void initState() {
    super.initState();

    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    _isAppActive =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        
    // Update app state
    if (_isAppActive) {
      AppStateTracker().setForeground();
      
      // Clear badge count when app starts
      NotificationService().clearIOSBadgeCount();
    } else {
      AppStateTracker().setBackground();
    }

    // Subscribe to notification events in a safe way
    _setupNotificationListener();

    // Add debug button overlay after layout is complete
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addDebugButtonOverlay();
      });
    }
  }

  void _addDebugButtonOverlay() {
    // Don't add if already exists
    if (_debugButtonOverlay != null) return;

    // Ensure we have a valid context
    if (!mounted) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _debugButtonOverlay = OverlayEntry(
      builder: (context) => Positioned(
        right: 16,
        bottom: 100,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              // Show an in-app notification instead
              NotificationService().showInAppNotification(
                NotificationPayload(
                  title: 'Debug Notification',
                  body: 'This is a test notification',
                  type: 'test',
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_debugButtonOverlay!);
  }

  void _removeDebugButtonOverlay() {
    _debugButtonOverlay?.remove();
    _debugButtonOverlay = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;

    // Update app state in Firestore based on lifecycle
    if (_isAppActive) {
      // App became active
      AppStateTracker().setForeground();
      
      // Clear badge count when app becomes active
      NotificationService().clearIOSBadgeCount();
      
      // App became active, we can listen to notifications
      _setupNotificationListener();

      // Re-add debug button if in debug mode
      if (kDebugMode) {
        _addDebugButtonOverlay();
      }
    } else {
      // App is going to background
      AppStateTracker().setBackground();
      
      // App is going to background, cancel subscription to avoid issues
      _notificationSubscription?.cancel();
      _notificationSubscription = null;

      // Remove debug button overlay
      _removeDebugButtonOverlay();
    }
  }

  void _setupNotificationListener() {
    // Don't set up listener if app is not active
    if (!_isAppActive) return;

    // Cancel any existing subscription first
    _notificationSubscription?.cancel();

    try {
      // Subscribe to notification events
      _notificationSubscription =
          NotificationService().notificationStream.listen(_handleNotification);
    } catch (e) {
      print('Error setting up notification listener: $e');
    }
  }

  @override
  void dispose() {
    // Always cancel subscription in dispose
    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    // Remove debug button overlay
    _removeDebugButtonOverlay();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void _handleNotification(NotificationPayload notification) {
    // The actual snackbar display is handled in NotificationService._showSnackbar
    // This widget just listens to the stream for any additional handling
    // we might want to add in the future

    // Note: don't use context here to avoid deactivated widget issues
    if (!mounted || !_isAppActive) return;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have access to Overlay by wrapping in Material
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => GestureDetector(
                onTap: () {
                  // This will dismiss the keyboard when tapping anywhere outside a text field
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to clear iOS badge count
  Future<void> _clearIOSBadgeCount() async {
    if (Platform.isIOS) {
      try {
        // Clear the badge using Flutter Local Notifications plugin
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
            FlutterLocalNotificationsPlugin();
            
        // Clear iOS badge count by setting it to 0
        final iOSDetails = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
            
        if (iOSDetails != null) {
          // Request permissions and clear badge
          await iOSDetails.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
        
        // Set badge to 0 on notification plugin
        await flutterLocalNotificationsPlugin.initialize(
          InitializationSettings(
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
              defaultPresentBadge: false,
            ),
            android: AndroidInitializationSettings('@drawable/notification_icon'),
          ),
          onDidReceiveNotificationResponse: (details) async {},
        );
        
        // Also try using Firebase Messaging
        try {
          await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            badge: false,
          );
        } catch (e) {
          print('Error configuring Firebase Messaging: $e');
        }
        
        print('iOS badge count cleared successfully');
      } catch (e) {
        print('Error clearing iOS badge count: $e');
      }
    }
  }
}
