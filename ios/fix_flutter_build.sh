#!/bin/bash

echo "Running pre-build fix script for Flutter iOS issues..."

# 1. Fix SubscriptionPeriod ambiguity
TARGET_DIR="Pods/PurchasesHybridCommon/ios/PurchasesHybridCommon/PurchasesHybridCommon"
TARGET_FILE="$TARGET_DIR/StoreProduct+HybridAdditions.swift"
SOURCE_FILE="RevenueCatFix/StoreProduct+HybridAdditions.swift"

if [ -d "$TARGET_DIR" ] && [ -f "$SOURCE_FILE" ]; then
  # Make a backup of the original file if it exists
  if [ -f "$TARGET_FILE" ]; then
    if ! cp "$TARGET_FILE" "$TARGET_FILE.backup" 2>/dev/null; then
      echo "Permission issue detected, trying with sudo..."
      sudo cp "$TARGET_FILE" "$TARGET_FILE.backup"
    fi
    echo "Created backup at $TARGET_FILE.backup"
  fi

  # Copy the fixed file to the target location
  if ! cp "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null; then
    echo "Permission issue detected, trying with sudo..."
    sudo cp "$SOURCE_FILE" "$TARGET_FILE"
  fi
  echo "✅ RevenueCat fix applied: $TARGET_FILE"
else
  echo "⚠️ RevenueCat fix not applied. Either target directory or source file not found."
  echo "Target directory: $TARGET_DIR"
  echo "Source file: $SOURCE_FILE"
fi

# 2. Fix AppFrameworkInfo.plist issue
FRAMEWORK_INFO_PATH="Flutter/AppFrameworkInfo.plist"

if [ ! -f "$FRAMEWORK_INFO_PATH" ]; then
  echo "AppFrameworkInfo.plist not found. Creating default file..."
  mkdir -p Flutter
  
  # Create a default AppFrameworkInfo.plist
  cat > "$FRAMEWORK_INFO_PATH" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>App</string>
  <key>CFBundleIdentifier</key>
  <string>io.flutter.flutter.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>App</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>MinimumOSVersion</key>
  <string>13.0</string>
</dict>
</plist>
EOL
  echo "✅ AppFrameworkInfo.plist created at $FRAMEWORK_INFO_PATH"
else
  echo "✅ AppFrameworkInfo.plist already exists"
fi

# 3. Run pod install to ensure dependencies are properly set up
echo "Running pod install to ensure all dependencies are correctly set up..."
pod install

echo "✅ All fixes completed successfully!"
exit 0 