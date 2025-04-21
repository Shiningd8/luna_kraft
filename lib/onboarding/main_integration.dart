import 'package:flutter/material.dart';
import 'package:luna_kraft/onboarding/onboarding_manager.dart';
import 'package:luna_kraft/onboarding/onboarding_screen.dart';

/// This file demonstrates how to integrate the onboarding flow into your main.dart
///
/// The key integration points are:
/// 1. After splash screen but before showing the main app
/// 2. Checking if onboarding has been completed
/// 3. Showing onboarding if needed
/// 4. Navigating to main app when onboarding is complete

// Example integration with your _MyAppState class:

/*

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;
  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  late Stream<BaseAuthUser> userStream;
  
  bool _showSplashScreen = true;
  bool _showOnboarding = false;
  bool _checkingOnboarding = false;
  
  @override
  void initState() {
    super.initState();
    
    // Your existing initialization code...
    
    // Handle splash screen timing
    Timer(Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showSplashScreen = false;
          _checkOnboardingStatus(); // Check onboarding after splash
        });
      }
    });
  }
  
  Future<void> _checkOnboardingStatus() async {
    setState(() {
      _checkingOnboarding = true;
    });
    
    // Only show onboarding for authenticated users
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final hasCompletedOnboarding = await OnboardingManager.hasCompletedOnboarding();
      
      if (mounted) {
        setState(() {
          _showOnboarding = !hasCompletedOnboarding;
          _checkingOnboarding = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _showOnboarding = false;
          _checkingOnboarding = false;
        });
      }
    }
  }
  
  void _onOnboardingComplete() async {
    await OnboardingManager.markOnboardingComplete();
    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Show splash screen if needed
    if (_showSplashScreen) {
      return MaterialApp(
        // Your splash screen configuration...
        home: SplashScreen(onAnimationComplete: () {
          setState(() {
            _showSplashScreen = false;
            _checkOnboardingStatus();
          });
        }),
      );
    }
    
    // Show loading indicator while checking onboarding status
    if (_checkingOnboarding) {
      return MaterialApp(
        // Basic theme settings...
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Show onboarding if needed
    if (_showOnboarding) {
      return MaterialApp(
        // Your theme settings...
        home: OnboardingScreen(
          onComplete: _onOnboardingComplete,
        ),
      );
    }
    
    // Show main app
    return MaterialApp.router(
      // Your existing configuration...
      routerConfig: _router,
    );
  }
}

*/

/// Simplified integration example
class OnboardingIntegrationExample extends StatefulWidget {
  @override
  State<OnboardingIntegrationExample> createState() =>
      _OnboardingIntegrationExampleState();
}

class _OnboardingIntegrationExampleState
    extends State<OnboardingIntegrationExample> {
  bool _showSplashScreen = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Simulate splash screen timing
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplashScreen = false;
          _checkOnboardingStatus();
        });
      }
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final hasCompletedOnboarding =
        await OnboardingManager.hasCompletedOnboarding();

    if (mounted) {
      setState(() {
        _showOnboarding = !hasCompletedOnboarding;
      });
    }
  }

  void _onOnboardingComplete() async {
    await OnboardingManager.markOnboardingComplete();
    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplashScreen) {
      return Scaffold(
        body: Center(
          child: FlutterLogo(size: 100),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: _onOnboardingComplete,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Luna Kraft'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Luna Kraft Main App!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await OnboardingManager.resetOnboardingStatus();
                _checkOnboardingStatus();
              },
              child: Text('Show Onboarding Again'),
            ),
          ],
        ),
      ),
    );
  }
}
