#!/bin/bash

echo "🔄 Starting custom iOS build process..."

# Navigate to the iOS directory and run our fix script
cd ios
./fix_flutter_build.sh

# Check if the fix script ran successfully
if [ $? -ne 0 ]; then
  echo "❌ Fix script failed. Aborting build."
  exit 1
fi

# Navigate back to the root directory
cd ..

echo "🚀 Building iOS app..."
flutter build ios --no-codesign

if [ $? -eq 0 ]; then
  echo "✅ Build completed successfully!"
  echo "You can now open the project in Xcode and run it on a device or simulator."
  echo "Xcode project path: ios/Runner.xcworkspace"
else
  echo "❌ Build failed. Please check the error messages above."
fi 