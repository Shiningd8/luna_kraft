#!/bin/bash

# Script to fix RevenueCat and StoreKit issues for TestFlight
echo "Preparing app for TestFlight by fixing RevenueCat and IAP configuration..."

# 1. Apply RevenueCat fix
echo "Applying RevenueCat fix..."
sh fix_revenuecat.sh

# 2. Copy the StoreKit configuration to Runner bundle
echo "Copying StoreKit configuration to Runner bundle..."
cp Configuration.storekit Runner/

# 3. Clean the build
echo "Cleaning build artifacts..."
cd ..
flutter clean
cd ios
rm -rf build
rm -rf Pods
rm Podfile.lock

# 4. Reinstall pods
echo "Reinstalling pods..."
pod install --repo-update

# 5. Fix post-install hooks
echo "Running post-install hooks..."
sh post_install_hook.sh

echo "✅ App is prepared for TestFlight!"
echo "Next steps:"
echo "1. Archive the app in Xcode"
echo "2. Upload to App Store Connect"
echo "3. Wait for TestFlight processing"
echo ""
echo "If you still encounter IAP issues in TestFlight:"
echo "- Check App Store Connect for unsigned agreements"
echo "- Ensure all tax forms are completed"
echo "- Wait 24 hours after any App Store Connect changes"
echo "- Make sure products are at least in 'Ready to Submit' state" 