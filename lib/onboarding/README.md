# Luna Kraft Onboarding

This module provides a beautiful, interactive onboarding experience for new Luna Kraft users.

## Features

- Animated, beautiful onboarding screens with modern UI
- Multiple animation styles (Lottie, custom animations, particles)
- Profile type selection at the end of onboarding
- Progress indicator with smooth dots
- Skip option for users to bypass onboarding
- Persistence to remember if onboarding is completed

## Required Assets

The onboarding screens use several asset files. Make sure to download Lottie animations for:

1. `assets/lottie/dream_text.json` - For the Dream Recreator screen
2. `assets/lottie/network.json` - For the Social Connections screen
3. `assets/lottie/bookshelf.json` - For the Save & Collect Dreams screen
4. `assets/lottie/chart.json` - For the Premium Insights screen
5. `assets/lottie/sound_waves.json` - For the Zen Mode screen
6. `assets/lottie/notification.json` - For the Permission Requests screen

You can download free Lottie animations from [LottieFiles](https://lottiefiles.com/).

## How to Implement

### 1. Basic Implementation

To implement the onboarding in your main app, wrap your app with the `OnboardingExample` widget:

```dart
import 'package:luna_kraft/onboarding/onboarding_example.dart';

void main() {
  runApp(
    OnboardingExample(
      child: MyApp(),
    ),
  );
}
```

### 2. Advanced Implementation (Custom Navigation)

For more control over the onboarding flow, you can use the `OnboardingManager` directly:

```dart
import 'package:luna_kraft/onboarding/onboarding_manager.dart';
import 'package:luna_kraft/onboarding/onboarding_screen.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final hasCompleted = await OnboardingManager.hasCompletedOnboarding();
    setState(() {
      _showOnboarding = !hasCompleted;
    });
  }

  void _onOnboardingComplete() async {
    await OnboardingManager.markOnboardingComplete();
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: _onOnboardingComplete,
      );
    }
    
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}
```

### 3. Testing Onboarding

To force display the onboarding screens (for testing), you can use:

```dart
// In your app's debug menu or settings
ElevatedButton(
  onPressed: () async {
    await OnboardingManager.resetOnboardingStatus();
    // Restart app or navigate to onboarding
  },
  child: Text('Reset & Show Onboarding'),
)
```

## Getting the User's Profile Type

After onboarding, you can access the user's selected profile type:

```dart
final profileType = await OnboardingManager.getUserProfileType();
print('User is a: $profileType'); // "Dreamer", "Explorer", or "Observer"
```

## Customization

To customize the appearance or content of the onboarding screens:

1. Edit the `onboardingPages` list in `onboarding_data.dart` to change content
2. Modify the animations in `onboarding_page.dart` to change visuals
3. Update `onboarding_screen.dart` to change the overall structure and navigation 