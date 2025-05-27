# Google Mobile Ads SDK iOS Setup Guide

This guide provides instructions for properly setting up the Google Mobile Ads SDK in your Flutter iOS app, focusing on resolving common dependency issues, particularly related to gRPC.

## 1. Update pubspec.yaml

Ensure your `pubspec.yaml` has the correct Google Mobile Ads dependency:

```yaml
dependencies:
  google_mobile_ads: ^3.0.0  # Use the latest stable version
```

Run `flutter pub get` to update dependencies.

## 2. Podfile Configuration

The key to resolving iOS dependency conflicts is proper version pinning in your `Podfile`. Use the following configuration:

```ruby
platform :ios, '13.0'

# ... existing setup ...

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Pin specific versions to avoid conflicts
  pod 'GoogleMobileAds', '10.9.0'
  pod 'Google-Mobile-Ads-SDK', '10.9.0'
  pod 'GoogleUserMessagingPlatform', '2.1.0'
  pod 'GoogleUtilities', '7.11.5'
  pod 'GoogleAppMeasurement', '10.15.0'
  pod 'nanopb', '2.30909.0'
  
  # Pin gRPC dependencies explicitly
  pod 'gRPC-Core', '1.50.0'
  pod 'gRPC-C++', '1.50.0'
  
  # ... other dependencies ...
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end
end
```

## 3. Update Info.plist

Ensure your `Info.plist` contains the required Google Mobile Ads entries:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>

<!-- Required for iOS 14+ -->
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>

<!-- Optional: Add SKAdNetwork identifiers -->
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <!-- Add other SKAdNetwork identifiers as needed -->
</array>
```

Replace `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` with your actual AdMob App ID.

## 4. AppDelegate Configuration

Update your `AppDelegate.swift` to initialize the Google Mobile Ads SDK:

```swift
import UIKit
import Flutter
import FirebaseCore
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    // Initialize Google Mobile Ads SDK
    GADMobileAds.sharedInstance().start { status in
      // Log adapter statuses for debugging
      let statusMap = status.adapterStatusesByClassName
      for (className, adapterStatus) in statusMap {
        print("Adapter Status: \(className), state: \(adapterStatus.state.rawValue)")
      }
    }
    
    // Configure test devices during development
    GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ kGADSimulatorID ]
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 5. Troubleshooting Common Issues

### Dependency Conflicts

If you encounter dependency conflicts after running `pod install`:

1. Delete the following files/directories:
   - `ios/Pods/`
   - `ios/Podfile.lock`
   - `ios/.symlinks/`
   - `ios/Flutter/Flutter.podspec`

2. Run these commands:
   ```
   flutter clean
   flutter pub get
   cd ios
   pod deintegrate
   pod setup
   pod install --repo-update
   ```

### Build Errors

If you encounter build errors:

1. Check Xcode build logs for specific error messages
2. Look for dependency version conflicts (particularly with gRPC)
3. Update the pinned versions in your Podfile
4. Ensure your minimum iOS version is set to 13.0 or higher

### gRPC Core Issues

If you see specific gRPC core errors:

1. Ensure you've pinned the gRPC versions as shown above
2. Try removing derived data from Xcode:
   ```
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Rebuild your project

## 6. Testing Your Integration

Use test ad unit IDs during development:

- iOS Banner: `ca-app-pub-3940256099942544/2934735716`
- iOS Interstitial: `ca-app-pub-3940256099942544/4411468910`
- iOS Rewarded: `ca-app-pub-3940256099942544/1712485313`

## 7. Best Practices

1. Always initialize the SDK before loading any ads
2. Use proper error handling in your ad service
3. Test on real iOS devices, not just the simulator
4. Keep AdMob SDK and Flutter plugin versions compatible
5. Monitor production ad performance in AdMob console

## Additional Resources

- [AdMob Flutter Plugin](https://pub.dev/packages/google_mobile_ads)
- [Google Mobile Ads SDK Documentation](https://developers.google.com/admob/ios/quick-start)
- [SKAdNetwork Identifiers](https://developers.google.com/admob/ios/ios14) 