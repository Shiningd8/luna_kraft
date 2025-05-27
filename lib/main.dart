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
      print('Firebase initialized in background handler');
    }
    
    print('Handling a background message: ${message.messageId}');
    print('Background message data: ${message.data}');

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

    print('Background notification displayed successfully');
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

  // Initialize Firebase properly with options first - before any Firebase usage
  try {
    // This ensures Firebase is initialized once
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully - first initialization');
    } else {
      print('Firebase was already initialized');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Initialize dynamic links handler
  try {
    await DeepLinkHelper.initDynamicLinks();
    print('Dynamic links handler initialized');
  } catch (e) {
    print('Error initializing dynamic links handler: $e');
  }
  
  // Register background handler after Firebase initialization
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service early
  await NotificationService().initialize();
  
  // Initialize app state tracker
  AppStateTracker().initialize();

  // Configure Firebase App Check safely
  await _configureFirebaseAppCheck();

  // Request permission for notifications early
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print(
        'User notification permission status: ${settings.authorizationStatus}');

    // Print FCM token for debugging
    final token = await FirebaseMessaging.instance.getToken();
    print(
        'FCM Token: ${token != null ? token.substring(0, 10) + '...' : 'null'}');
  } catch (e) {
    print('Error requesting notification permissions: $e');
  }

  // Initialize NetworkService for better Firebase connectivity handling
  try {
    // Initialize NetworkService singleton
    final networkService = NetworkService();

    // Set up initial connectivity check
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      // Only try to verify Firestore if we have connectivity
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .get()
              .timeout(Duration(seconds: 5));
          print('Initial Firestore connection verified');
        } catch (e) {
          print('Initial Firestore verification failed: $e');
        }
      }
    }

    print('Network service initialized successfully');
  } catch (e) {
    print('Error initializing network service: $e');
  }

  // Preload onboarding status
  try {
    await OnboardingManager.hasCompletedOnboarding();
    print('Onboarding status preloaded');
  } catch (e) {
    print('Error preloading onboarding status: $e');
  }

  // Initialize subscription service
  try {
    print('Starting RevenueCat initialization...');
    
    // First configure RevenueCat
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration('appl_aUbICkbeGteMFoiMsBOJzdjVoTE'));
    
    // Wait to ensure RevenueCat is fully initialized
    await Future.delayed(Duration(seconds: 1));
    
    // Now call our PurchaseService init which handles caching and other setup
    await PurchaseService.init();
    
    print('RevenueCat configuration complete');
    
    if (kDebugMode) {
      print('Subscription service initialized in DEBUG MODE - Using mock purchases');
    } else {
      print('Subscription service initialized successfully');
    }
    
    // Explicitly verify initialization is successful
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      print('✅ RevenueCat customer info successfully retrieved: ${customerInfo.originalAppUserId}');
    } catch (verifyError) {
      print('⚠️ RevenueCat verification check failed, but continuing: $verifyError');
    }
  } catch (e) {
    print('Error initializing subscription service: $e');
    
    // Fallback approach - try direct configuration 
    try {
      print('Attempting fallback initialization of RevenueCat...');
      await Purchases.configure(PurchasesConfiguration('appl_aUbICkbeGteMFoiMsBOJzdjVoTE'));
      print('Fallback initialization completed');
    } catch (fallbackError) {
      print('Fallback initialization also failed: $fallbackError');
    }
  }

  // Initialize subscription manager
  try {
    await SubscriptionManager.instance.initialize();
    print('Subscription manager initialized successfully');
  } catch (e) {
    print('Error initializing subscription manager: $e');
  }

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  // Initialize our custom AppState for music
  final musicAppState = custom_app_state.AppState();

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
    platform: TargetPlatform.android,
    
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
    child: MyApp(theme: theme),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.entryPage, required this.theme});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  final Widget? entryPage;
  final ThemeData theme;
}

class _MyAppState extends State<MyApp> {
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
    
    // Set app state to foreground when app starts
    AppStateTracker().setForeground();
  }

  Future<void> _initializeApp() async {
    try {
      print('Starting app initialization...');

      // Initialize FlutterFlow theme
      print('Initializing FlutterFlow theme...');
      await FlutterFlowTheme.initialize();
      print('FlutterFlow theme initialized');

      // Setup app state and router
      print('Setting up app state and router...');
      _appStateNotifier = AppStateNotifier.instance;
      _router = createRouter(_appStateNotifier, widget.entryPage);
      print('App state and router setup complete');

      print('Setting up user stream...');
      userStream = lunaKraftFirebaseUserStream()
        ..listen((user) {
          print('AUTH STATE CHANGED: User logged in: ${user.loggedIn}');
          if (user.loggedIn) {
            print('Authenticated user: ${user.email}');
          } else {
            print('User logged out or not authenticated');
          }
          _appStateNotifier.update(user);
        });
      print('User stream setup complete');

      // Add debug logging for JWT token changes
      jwtTokenStream.listen((jwt) {
        print(
            'JWT token refreshed: ${jwt != null ? 'Token present' : 'No token'}');
      });

      print('Stopping splash image...');
      _appStateNotifier.stopShowingSplashImage();
      print('Splash image stopped');

      if (mounted) {
        print('Setting initialized state...');
        setState(() {
          _initialized = true;
        });
        print('App initialization complete');
      }

      // Auto-hide splash screen after a timeout (as a fallback)
      Timer(Duration(seconds: 5), () {
        if (mounted) {
          print('Auto-hiding splash screen...');
          setState(() {
            _showSplashScreen = false;
          });
          print('Splash screen hidden');
        }
      });
    } catch (e, stackTrace) {
      print('Error initializing app: $e');
      print('Stack trace: $stackTrace');
      // Show error state if initialization fails
      if (mounted) {
        setState(() {
          _initialized = true;
          _showSplashScreen = false;
        });
      }
    }
  }

  @override
  void dispose() {
    authUserSub.cancel();
    _router.dispose();
    _showSplashScreen = true;

    // Clean up app state tracker
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
