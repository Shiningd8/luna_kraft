#!/bin/bash

echo "🧹 Cleaning pods and reinstalling dependencies..."

# Go to the project root
cd "$(dirname "$0")/.."

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Error: Must run this script from the ios directory of your Flutter project"
  exit 1
fi

echo "🗑️  Removing old pod cache..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.podspec
rm -rf ~/Library/Developer/Xcode/DerivedData

echo "🧹 Running flutter clean..."
flutter clean

echo "📦 Running flutter pub get..."
flutter pub get

echo "📱 Moving to iOS directory..."
cd ios

echo "🔄 Pod deintegrate..."
pod deintegrate

echo "⚙️  Pod setup..."
pod setup

echo "⬇️  Installing pods with repo update..."
pod install --repo-update

echo "✅ Done! You can now open Runner.xcworkspace and build your project."
echo "If you still encounter issues, check the Google Mobile Ads setup guide in docs/GOOGLE_MOBILE_ADS_IOS_SETUP.md" 