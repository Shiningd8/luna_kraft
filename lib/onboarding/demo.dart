import 'package:flutter/material.dart';
import 'package:luna_kraft/onboarding/onboarding_screen.dart';

/// A simple standalone demo of the onboarding screens
///
/// To run this demo, use:
/// flutter run -t lib/onboarding/demo.dart
void main() {
  runApp(OnboardingDemo());
}

class OnboardingDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Onboarding Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF3D376F),
          secondary: Colors.white,
          background: Color(0xFF1A1A2E),
        ),
      ),
      home: OnboardingDemoScreen(),
    );
  }
}

class OnboardingDemoScreen extends StatefulWidget {
  @override
  State<OnboardingDemoScreen> createState() => _OnboardingDemoScreenState();
}

class _OnboardingDemoScreenState extends State<OnboardingDemoScreen> {
  bool _onboardingComplete = false;
  String _selectedProfileType = '';

  void _handleOnboardingComplete() {
    setState(() {
      _onboardingComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingComplete) {
      return OnboardingScreen(
        onComplete: _handleOnboardingComplete,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Onboarding Completed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            SizedBox(height: 24),
            Text(
              'Onboarding Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _onboardingComplete = false;
                });
              },
              child: Text('Show Onboarding Again'),
            ),
          ],
        ),
      ),
    );
  }
}
