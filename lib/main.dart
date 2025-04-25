import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize log filtering
  LoggingConfig.initialize();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize AdMob
  try {
    await MobileAds.instance.initialize();
    print('AdMob SDK initialized successfully');

    // Register the custom native ad factory
    LunaKraftNativeAdFactory.registerNativeAdFactory();

    // Set test device IDs for development
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['TEST_DEVICE_ID'], // Replace with your test device ID
      ),
    );
  } catch (e) {
    print('Error initializing AdMob SDK: $e');
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
      ..listen((user) => _appStateNotifier.update(user));

    jwtTokenStream.listen((_) {});

    // We're using our own splash screen
    _appStateNotifier.stopShowingSplashImage();

    // Auto-hide splash screen after a timeout (as a fallback)
    Timer(Duration(seconds: 6), () {
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
        debugShowCheckedModeBanner: false,
        title: 'LunaKraft',
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: false,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: false,
        ),
        themeMode: _themeMode,
        home: SplashScreen(onAnimationComplete: hideSplashScreen),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'LunaKraft',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.dragged)) {
              return Color(4293257195);
            }
            if (states.contains(MaterialState.hovered)) {
              return Color(4293257195);
            }
            return Color(4293257195);
          }),
        ),
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.dragged)) {
              return Color(4281414722);
            }
            if (states.contains(MaterialState.hovered)) {
              return Color(4281414722);
            }
            return Color(4281414722);
          }),
        ),
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
