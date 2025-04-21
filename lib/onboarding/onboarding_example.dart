import 'package:flutter/material.dart';
import 'package:luna_kraft/onboarding/onboarding_manager.dart';

/// Example of how to integrate the onboarding flow into your app
///
/// This is an example implementation. In your actual app, you would
/// integrate this logic into your main app initialization flow.
class OnboardingExample extends StatefulWidget {
  final Widget child;

  const OnboardingExample({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<OnboardingExample> createState() => _OnboardingExampleState();
}

class _OnboardingExampleState extends State<OnboardingExample> {
  late Future<Widget> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _initializeOnboarding();
  }

  Future<Widget> _initializeOnboarding() async {
    // Check if the user has completed onboarding
    return OnboardingManager.handleOnboarding(
      mainApp: widget.child,
      // Set to true to always show onboarding (for testing)
      forceShow: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _onboardingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while checking onboarding status
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          // Handle error (rare, but good practice)
          return Scaffold(
            body: Center(
              child: Text('Error initializing app: ${snapshot.error}'),
            ),
          );
        }

        // Show either onboarding or main app
        return snapshot.data ?? widget.child;
      },
    );
  }
}

/// Example implementation in your app's entry point
///
/// This demonstrates how to use the OnboardingExample wrapper
/// around your main app widget.
///
/// ```dart
/// void main() {
///   runApp(
///     OnboardingExample(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
