# LunaKraft

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Integration Tests

To test on a real iOS / Android device, first connect the device and run the following command from the root of the project:

```bash
flutter test integration_test/test.dart
```

To test on a web browser, first launch `chromedriver` as follows:
```bash
chromedriver --port=4444
```

Then from the root of the project, run the following command:
```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/test.dart \
  -d chrome
```

Find more information about running Flutter integration tests [here](https://docs.flutter.dev/cookbook/testing/integration/introduction#5-run-the-integration-test).

Refer to this guide for instructions on running the tests on [Firebase Test Lab](https://github.com/flutter/flutter/tree/main/packages/integration_test#firebase-test-lab).

## Customizing Notification Icons

To replace the placeholder notification icons with your own:

1. Create notification icons according to Android's specifications:
   - Icons should be simple, white silhouettes on a transparent background
   - Material design icon templates are preferred
   - Recommended tool: [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-notification.html)

2. Save your icons with the name `notification_icon.png` in the following directories:
   - `android/app/src/main/res/drawable-mdpi/` (24x24 px)
   - `android/app/src/main/res/drawable-hdpi/` (36x36 px)
   - `android/app/src/main/res/drawable-xhdpi/` (48x48 px)
   - `android/app/src/main/res/drawable-xxhdpi/` (72x72 px)
   - `android/app/src/main/res/drawable-xxxhdpi/` (96x96 px)

3. You can also customize the notification color by editing:
   - `android/app/src/main/res/values/colors.xml` - update the `notification_color` value

Note: The XML vector icon at `android/app/src/main/res/drawable/notification_icon.xml` serves as a fallback and should be kept.
