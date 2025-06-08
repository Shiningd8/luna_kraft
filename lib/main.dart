import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:go_router/go_router.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'auth/firebase_auth/firebase_app_check_stub.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
// import 'package:unity_ads_plugin/unity_ads_plugin.dart';
// import 'services/unity_ads_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';
import 'flutter_flow/nav/nav.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import 'services/app_state.dart' as custom_app_state;
import '/components/base_layout.dart';
import '/flutter_flow/flutter_flow_widget_state.dart' as ff;
import '/utils/logging_config.dart';
import '/splash_screen.dart';
import '/services/purchase_service.dart';
import '/services/subscription_manager.dart';
import '/onboarding/onboarding_manager.dart';
import '/services/notification_service.dart';
import '/services/network_service.dart';
import '/services/app_state_tracker.dart';
import '/widgets/notification_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import '/utils/deep_link_helper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// import 'services/ads_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized since this can run when app is terminated
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // print('Firebase initialized in background handler');
    }
    
    // print('Handling a background message: ${message.messageId}');
    // print('Background message data: ${message.data}');

    // Create notification plugin instance for background notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notification plugin for background notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

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
    );

    // Create notification channel (Android only)
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

      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new notification',
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'luna_kraft_channel',
          'LunaKraft Notifications',
          channelDescription: 'Social interaction notifications for LunaKraft',
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

    // print('Background notification displayed successfully');
  } catch (e) {
    print('Error in background message handler: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style to prevent text selection grey boxes
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize log filtering
  LoggingConfig.initialize();

  bool subscriptionServicesInitialized = false;

  try {
    // Initialize Firebase first, before any other Firebase-dependent services
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firebase App Check after core initialization
    await _configureFirebaseAppCheck();

    // Initialize Firebase Messaging
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      if (kDebugMode) {
        final token = await messaging.getToken();
        print('FCM Token: ${token != null ? token.substring(0, 10) + '...' : 'null'}');
      }
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }

    // Initialize core services sequentially
    await FlutterFlowTheme.initialize();
    await DeepLinkHelper.initDynamicLinks();
    
    // Initialize AppStateTracker (void return type)
    AppStateTracker().initialize();
    
    // Initialize NotificationService last, after Firebase Messaging is ready
    await NotificationService().initialize();

    // Initialize subscription services with retry logic
    for (int i = 0; i < 3; i++) {
      try {
        await _initializeSubscriptionServices();
        subscriptionServicesInitialized = true;
        print('✅ Subscription services initialized successfully');
        break;
      } catch (e) {
        print('Attempt ${i + 1} to initialize subscription services failed: $e');
        if (i < 2) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        }
      }
    }

    if (!subscriptionServicesInitialized) {
      print('⚠️ Warning: Failed to initialize subscription services after 3 attempts');
    }

  } catch (e, stack) {
    print('Error during initialization: $e');
    print('Stack trace: $stack');
  }

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  // Initialize our custom AppState for music
  final musicAppState = custom_app_state.AppState();

  // Store subscription initialization status
  appState.update(() {
    // You'll need to add this property to your FFAppState class
    // appState.subscriptionServicesInitialized = subscriptionServicesInitialized;
  });

  // Customize text selection controls to prevent large grey box
  final ThemeData theme = ThemeData(
    // Default brightness and colors
    brightness: Brightness.light,
    primaryColor: Color(0xFF7963DF),
    primarySwatch: MaterialColor(0xFF7963DF, {
      50: Color(0xFFEEEBFA),
      100: Color(0xFFD4CDF2),
      200: Color(0xFFB8ACE9),
      300: Color(0xFF9C8AE0),
      400: Color(0xFF8A77DA),
      500: Color(0xFF7963DF),
      600: Color(0xFF715BCA),
      700: Color(0xFF6651B4),
      800: Color(0xFF5B479F),
      900: Color(0xFF4B3577),
    }),
    
    // Text selection configuration
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Color(0xFF7963DF).withOpacity(0.2),
      cursorColor: Color(0xFF7963DF),
      selectionHandleColor: Color(0xFF7963DF),
    ),
    
    // Platform setting
    platform: TargetPlatform.iOS,
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF7963DF), width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      fillColor: Colors.white.withOpacity(0.05),
      filled: true,
    ),
    
    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF7963DF),
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    
    // Material 2 design
    useMaterial3: false,
    
    // Cupertino theme overrides
    cupertinoOverrideTheme: CupertinoThemeData(
      primaryColor: Color(0xFF7963DF),
      textTheme: CupertinoTextThemeData(
        primaryColor: Color(0xFF7963DF),
      ),
    ),
    
    // Enhanced visual density and typography
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => appState),
      ChangeNotifierProvider(create: (context) => musicAppState),
    ],
    child: MyApp(
      theme: theme,
      subscriptionServicesInitialized: subscriptionServicesInitialized,
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key, 
    this.entryPage, 
    required this.theme,
    required this.subscriptionServicesInitialized,
  });

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  final Widget? entryPage;
  final ThemeData theme;
  final bool subscriptionServicesInitialized;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  late Stream<BaseAuthUser> userStream;
  final authUserSub = authenticatedUserStream.listen((_) {});
  bool _showSplashScreen = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    
    // Set default theme to dark mode
    _themeMode = ThemeMode.dark;
    FlutterFlowTheme.saveThemeMode(ThemeMode.dark);
    
    // Set app state to foreground when app starts
    AppStateTracker().setForeground();
    
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // Reset notification badge on iOS
    _resetIOSBadgeCount();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize FlutterFlow theme
      await FlutterFlowTheme.initialize();

      // Setup app state and router
      _appStateNotifier = AppStateNotifier.instance;
      _router = createRouter(_appStateNotifier, widget.entryPage);

      // Setup user stream
      userStream = lunaKraftFirebaseUserStream()
        ..listen((user) {
          if (user.loggedIn) {
            // If subscription services failed to initialize, try to initialize them again
            if (!widget.subscriptionServicesInitialized) {
              _retrySubscriptionServices();
            }
          }
          _appStateNotifier.update(user);
        });

      // Add debug logging for JWT token changes
      jwtTokenStream.listen((jwt) {
        // print('JWT token refreshed: ${jwt != null ? 'Token present' : 'No token'}');
      });

      _appStateNotifier.stopShowingSplashImage();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }

      // Auto-hide splash screen after a timeout (as a fallback)
      Timer(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showSplashScreen = false;
          });
        }
      });
    } catch (e, stackTrace) {
      print('Error initializing app: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _initialized = true;
          _showSplashScreen = false;
        });
      }
    }
  }

  // Helper method to retry subscription services initialization
  Future<void> _retrySubscriptionServices() async {
    try {
      await _initializeSubscriptionServices();
      print('✅ Successfully reinitialized subscription services');
    } catch (e) {
      print('❌ Failed to reinitialize subscription services: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    authUserSub.cancel();
    _router.dispose();
    _showSplashScreen = true;
    AppStateTracker().dispose();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  void hideSplashScreen() {
    setState(() {
      _showSplashScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_showSplashScreen) {
      return MaterialApp(
        title: 'LunaKraft',
        theme: widget.theme,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onAnimationComplete: hideSplashScreen,
        ),
      );
    }

    return NotificationHandler(
      child: MaterialApp.router(
        title: 'LunaKraft',
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        theme: widget.theme.copyWith(
          cupertinoOverrideTheme: CupertinoThemeData(
            primaryColor: Color(0xFF7963DF),
            textTheme: CupertinoTextThemeData(
              primaryColor: Color(0xFF7963DF),
            ),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: false,
          cupertinoOverrideTheme: CupertinoThemeData(
            primaryColor: Color(0xFF7963DF),
            textTheme: CupertinoTextThemeData(
              primaryColor: Color(0xFF7963DF),
            ),
          ),
        ),
        themeMode: _themeMode,
        routerConfig: _router,
        builder: (context, child) {
          if (child == null) {
            return Center(child: CircularProgressIndicator());
          }
          return ScaffoldMessenger(
            child: Builder(
              builder: (context) => ImprovedConnectivityBanner(child: child),
            ),
          );
        },
      ),
    );
  }

  // Add method to reset iOS badge count
  Future<void> _resetIOSBadgeCount() async {
    if (Platform.isIOS) {
      try {
        // Reset badge count to zero using FlutterLocalNotificationsPlugin
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
            FlutterLocalNotificationsPlugin();
        
        // Initialize if needed (minimal initialization)
        const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: true,
          requestSoundPermission: false,
        );
        await flutterLocalNotificationsPlugin.initialize(
          const InitializationSettings(iOS: iosSettings),
        );
        
        // Request permissions and clear all notifications which also clears the badge
        final iOSImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
                
        if (iOSImplementation != null) {
          await iOSImplementation.requestPermissions(
            alert: false,
            badge: true,
            sound: false,
          );
          
          // Cancel all notifications which clears the badge
          await iOSImplementation.cancelAll();
        }
            
        // Also try to clear using Firebase Messaging
        try {
          await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            badge: false,
          );
        } catch (e) {
          print('Error updating Firebase Messaging options: $e');
        }
        
        print('iOS badge count reset successfully');
      } catch (e) {
        print('Error resetting iOS badge count: $e');
      }
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - reset badge count
      NotificationService().clearIOSBadgeCount();
    }
  }
}

// Configure Firebase App Check with robust error handling
Future<void> _configureFirebaseAppCheck() async {
  try {
    // Debug mode - completely skip App Check to avoid any issues
    if (kDebugMode) {
      print('⚠️ DEBUG MODE: App Check is disabled to allow development login');

      // Set a flag that auth methods can check
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_check_skipped', true);

      // Do NOT call FirebaseAppCheck.instance.activate() in debug mode
      return;
    }

    // Only activate App Check in PRODUCTION
    print('PRODUCTION MODE: Activating App Check with proper attestation');

    // Debug token for development only (not used in this flow)
    const String webRecaptchaKey = '6LerFOQpAAAAADbNfQ-i6oJ6AYm1hnfOCkHHUfg2';

    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(webRecaptchaKey),
      );
    } else if (Platform.isAndroid) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: true, // Use boolean for stub implementation
      );
    } else if (Platform.isIOS) {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.deviceCheck,
      );
    }

    // Enable token auto-refresh in production
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    print('Firebase App Check initialization error: $e');
    print('Continuing without App Check - some operations may fail');

    // Also set the flag in case of error
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_check_skipped', true);
  }
}

Future<String?> _getDeviceInfo() async {
  try {
    // Simple approach using environment variables
    return Platform.environment['ANDROID_MANUFACTURER'] ?? 'unknown';
  } catch (e) {
    print('Error getting device info: $e');
    return null;
  }
}

class ImprovedConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ImprovedConnectivityBanner({Key? key, required this.child})
      : super(key: key);

  @override
  State<ImprovedConnectivityBanner> createState() =>
      _ImprovedConnectivityBannerState();
}

class _ImprovedConnectivityBannerState
    extends State<ImprovedConnectivityBanner> {
  late StreamSubscription<bool> _networkStatusSubscription;
  bool _isOffline = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Subscribe to network status from NetworkService
    _networkStatusSubscription =
        NetworkService().networkStatusStream.listen((isConnected) {
      final wasOffline = _isOffline;
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });

        // Show message when connection changes
        if (_isOffline && !wasOffline) {
          _showNoConnectionMessage();
        } else if (!_isOffline && wasOffline) {
          _showConnectionRestoredMessage();
        }
      }
    });
  }

  @override
  void dispose() {
    _networkStatusSubscription.cancel();
    super.dispose();
  }

  void _showNoConnectionMessage() {
    if (!mounted) return;

    try {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('No internet connection')),
            ],
          ),
          backgroundColor: Colors.redAccent.shade200,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: 24,
            left: 16,
            right: 16,
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error showing no connection message: $e');
    }
  }

  void _showConnectionRestoredMessage() {
    if (!mounted) return;

    try {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Connection restored')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: 24,
            left: 16,
            right: 16,
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error showing connection restored message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: widget.child,
    );
  }
}

// Helper function to initialize subscription-related services
Future<void> _initializeSubscriptionServices() async {
  try {
    // Configure RevenueCat with debug logging
    await Purchases.setLogLevel(LogLevel.debug);
    
    // Configure RevenueCat with your API key based on platform
    if (Platform.isIOS) {
      await Purchases.configure(
        PurchasesConfiguration('appl_aUbICkbeGteMFoiMsBOJzdjVoTE')
          ..appUserID = null // Let RevenueCat generate a stable ID
          ..observerMode = false // Enable real purchases
          ..usesStoreKit2IfAvailable = true // Use StoreKit 2 on iOS 15+
      );
    } else if (Platform.isAndroid) {
      await Purchases.configure(
        PurchasesConfiguration('goog_YOUR_GOOGLE_API_KEY') // Replace with your Android key
          ..appUserID = null
          ..observerMode = false
      );
    }
    
    // Verify configuration was successful
    final configuredAppUserID = await Purchases.appUserID;
    print('RevenueCat configured successfully with app user ID: $configuredAppUserID');
    
    // Initialize PurchaseService
    await PurchaseService.init();
    
    // Initialize other subscription-related services
    await Future.wait([
      SubscriptionManager.instance.initialize(),
    ]);
    
    // Verify offerings are available
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        print('RevenueCat offerings loaded successfully');
      } else {
        print('Warning: No current offering available');
      }
    } catch (e) {
      print('Warning: Failed to load initial offerings: $e');
      // Don't throw here - the app can still function without initial offerings
    }
    
  } catch (e, stack) {
    print('Error initializing subscription services: $e');
    print('Stack trace: $stack');
    // Rethrow to let the app handle the error appropriately
    rethrow;
  }
}
