import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_icon_button.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_widgets.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:luna_kraft/main.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_util.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:provider/provider.dart';
import 'package:luna_kraft/backend/firebase/firebase_config.dart';
import 'package:luna_kraft/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:luna_kraft/services/purchase_service.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  bool subscriptionServicesInitialized = false;

  setUpAll(() async {
    await initFirebase();
    await FlutterFlowTheme.initialize();
    
    // Initialize subscription services
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(
        PurchasesConfiguration('appl_aUbICkbeGteMFoiMsBOJzdjVoTE')
          ..appUserID = null
          ..observerMode = true // Use observer mode for tests
      );
      await PurchaseService.init();
      subscriptionServicesInitialized = true;
    } catch (e) {
      print('Failed to initialize subscription services in test: $e');
    }
  });

  setUp(() async {
    await authManager.signOut();
    FFAppState.reset();
    final appState = FFAppState();
    await appState.initializePersistedState();
  });

  testWidgets('ahhhh', (WidgetTester tester) async {
    _overrideOnError();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'andrew@flutterflow.io', password: 'andrew123');
    
    final testTheme = ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Color(0xFF7963DF),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Color(0xFF7963DF).withOpacity(0.2),
        cursorColor: Color(0xFF7963DF),
        selectionHandleColor: Color(0xFF7963DF),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: Color(0xFF7963DF),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF7963DF),
        ),
      ),
      platform: TargetPlatform.android,
      useMaterial3: false,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => FFAppState()),
          ],
          child: MyApp(
            theme: testTheme,
            subscriptionServicesInitialized: subscriptionServicesInitialized,
          ),
        ),
      ),
    );
  });
}

// There are certain types of errors that can happen during tests but
// should not break the test.
void _overrideOnError() {
  final originalOnError = FlutterError.onError!;
  FlutterError.onError = (errorDetails) {
    if (_shouldIgnoreError(errorDetails.toString())) {
      return;
    }
    originalOnError(errorDetails);
  };
}

bool _shouldIgnoreError(String error) {
  // It can fail to decode some SVGs - this should not break the test.
  if (error.contains('ImageCodecException')) {
    return true;
  }
  // Overflows happen all over the place,
  // but they should not break tests.
  if (error.contains('overflowed by')) {
    return true;
  }
  // Sometimes some images fail to load, it generally does not break the test.
  if (error.contains('No host specified in URI') ||
      error.contains('EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE')) {
    return true;
  }
  // These errors should be avoided, but they should not break the test.
  if (error.contains('setState() called after dispose()')) {
    return true;
  }
  // Text selection and Cupertino errors should not break tests
  if (error.contains('CupertinoLocalizations') || 
      error.contains('TextSelectionControls') || 
      error.contains('DiagnosticsProperty<void>') || 
      error.contains('selectionControls') ||
      error.contains('_CupertinoTextSelectionControlsToolbarState')) {
    return true;
  }
  // Focus related errors in tests
  if (error.contains('FocusNode') || error.contains('unfocus')) {
    return true;
  }
  // RevenueCat related errors in tests
  if (error.contains('Purchases') || error.contains('RevenueCat')) {
    return true;
  }

  return false;
}
