#!/bin/bash

# Exit on error
set -e

echo "=== Preparing iOS build ==="

# Navigate to iOS folder
cd ios

# Make sure pods are up to date
echo "=== Installing CocoaPods dependencies ==="
pod install --repo-update

# Build for iOS
echo "=== Building for iOS ==="
cd ..
flutter build ios --release

echo "=== Build completed ==="
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Select your signing team"
echo "3. Ensure push notification capability is enabled:"
echo "   - Select Runner target"
echo "   - Go to Signing & Capabilities tab"
echo "   - Click + Capability"
echo "   - Add 'Push Notifications'"
echo "   - Add 'Background Modes' and check 'Remote notifications'"
echo "4. Build and run on a real device to test push notifications"
echo ""
echo "Note: APNs will not work in the simulator, you must use a real device." 