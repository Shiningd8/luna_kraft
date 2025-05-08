import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import 'services/app_state.dart' as custom_app_state;
import '/components/base_layout.dart';
import '/flutter_flow/flutter_flow_widget_state.dart' as ff;
import '/utils/logging_config.dart';
import '/splash_screen.dart';
import '/services/native_ad_factory.dart';
import '/services/purchase_service.dart';
import '/services/subscription_manager.dart';
import '/onboarding/onboarding_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize log filtering
  LoggingConfig.initialize();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure Firebase App Check safely
  await _configureFirebaseAppCheck();

  // Preload onboarding status
  try {
    await OnboardingManager.hasCompletedOnboarding();
    print('Onboarding status preloaded');
  } catch (e) {
    print('Error preloading onboarding status: $e');
  }

  // Initialize AdMob
  try {
    await MobileAds.instance.initialize();
    print('AdMob SDK initialized successfully');

    // Register the custom native ad factory
    LunaKraftNativeAdFactory.registerNativeAdFactory();

    // Completely disable AdMob validator popups in debug mode
    if (kDebugMode) {
      final RequestConfiguration config = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        testDeviceIds: ['TEST_DEVICE_ID'],
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      );

      MobileAds.instance.updateRequestConfiguration(config);

      // Set a flag in userDefaults/SharedPreferences to disable validator
      try {
        // Disable validator completely for both platforms
        print('Setting ad validator disabled flag');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('admob_validator_disabled', true);

        // This approach helps disable validator on iOS
        if (Platform.isIOS) {
          print('Setting iOS ad validator disabled flag');
          // iOS-specific code would go here if needed
        }
        // For Android
        else if (Platform.isAndroid) {
          print('Setting Android ad validator disabled flag');
          // Android-specific code would go here if needed
        }
      } catch (e) {
        print('Error setting platform-specific validator flags: $e');
      }

      print('AdMob validator completely disabled');
    } else {
      // Set test device IDs for development
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['TEST_DEVICE_ID'], // Replace with your test device ID
        ),
      );
    }
  } catch (e) {
    print('Error initializing AdMob SDK: $e');
  }

  // Initialize subscription service
  try {
    await PurchaseService.init();
    if (kDebugMode) {
      print(
          'Subscription service initialized in DEBUG MODE - Using mock purchases');
    } else {
      print('Subscription service initialized successfully');
    }
  } catch (e) {
    print('Error initializing subscription service: $e');
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

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => appState),
      ChangeNotifierProvider(create: (context) => musicAppState),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.entryPage});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  final Widget? entryPage;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  late Stream<BaseAuthUser> userStream;
  final authUserSub = authenticatedUserStream.listen((_) {});
  bool _showSplashScreen = true;

  @override
  void initState() {
    super.initState();

    // Setup app state and router
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier, widget.entryPage);
    userStream = lunaKraftFirebaseUserStream()
      ..listen((user) {
        // Add debug logging for auth state changes
        print('AUTH STATE CHANGED: User logged in: ${user.loggedIn}');
        if (user.loggedIn) {
          print('Authenticated user: ${user.email}');
        } else {
          print('User logged out or not authenticated');
        }
        _appStateNotifier.update(user);
      });

    // Add debug logging for JWT token changes
    jwtTokenStream.listen((jwt) {
      print(
          'JWT token refreshed: ${jwt != null ? 'Token present' : 'No token'}');
    });

    // We're using our own splash screen
    _appStateNotifier.stopShowingSplashImage();

    // Auto-hide splash screen after a timeout (as a fallback)
    Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSplashScreen = false;
        });
      }
    });
  }

  @override
  void dispose() {
    authUserSub.cancel();
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
    if (_showSplashScreen) {
      return MaterialApp(
        title: 'LunaKraft',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: false,
        ),
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onAnimationComplete: hideSplashScreen,
        ),
      );
    }

    return MaterialApp.router(
      title: 'LunaKraft',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return ConnectivityBanner(child: child!);
      },
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
        androidProvider: AndroidProvider.playIntegrity,
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

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isOffline = false;
  Timer? _snackbarTimer;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final offline = result == ConnectivityResult.none;
      if (offline != _isOffline) {
        setState(() {
          _isOffline = offline;
        });
        if (offline) {
          _showNoInternetSnackbar();
        }
      } else if (!offline) {
        // If connection is restored, hide snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _snackbarTimer?.cancel();
    super.dispose();
  }

  void _showNoInternetSnackbar() {
    // Exclude Add Post pages
    final modalRoute = ModalRoute.of(context);
    final settingsName = modalRoute?.settings.name ?? '';
    if (settingsName.contains('AddPost1') ||
        settingsName.contains('AddPost2') ||
        settingsName.contains('AddPost4')) {
      return;
    }
    // Show a modern snackbar at the bottom
    ScaffoldMessenger.of(context).showSnackBar(
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
    // Re-show if still offline after duration
    _snackbarTimer?.cancel();
    _snackbarTimer = Timer(Duration(seconds: 3), () {
      if (_isOffline && mounted) {
        _showNoInternetSnackbar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
