// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:luna_kraft/services/purchase_service.dart';

import 'package:luna_kraft/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    bool subscriptionServicesInitialized = false;

    // Try to initialize subscription services
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

    // Build our app and trigger a frame.
    final testTheme = ThemeData(
      primarySwatch: Colors.blue,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Colors.transparent,
        cursorColor: Color(0xFF7963DF),
        selectionHandleColor: Color(0xFF7963DF),
      ),
    );
    
    await tester.pumpWidget(MyApp(
      theme: testTheme,
      subscriptionServicesInitialized: subscriptionServicesInitialized,
    ));
  });
}
