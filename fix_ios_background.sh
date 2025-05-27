#!/bin/bash

set -e
echo "=== Fixing iOS Background Modes and Provisioning Profile ==="

# Check if we need to install the xcodeproj gem
if ! gem list -i xcodeproj > /dev/null 2>&1; then
  echo "Installing xcodeproj gem..."
  sudo gem install xcodeproj
fi

# 1. Clean Xcode derived data
echo "Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 

# 2. Run the Ruby script to update project capabilities
echo "Updating Xcode project capabilities..."
ruby ./fix_provisioning.rb

# 3. Move background modes to Info.plist to ensure it's picked up
echo "Ensuring background modes are in Info.plist..."
cat > ios/background_patch.sh << 'EOF'
#!/bin/bash
INFO_PLIST="Runner/Info.plist"
if ! grep -q "UIBackgroundModes" "$INFO_PLIST"; then
  # Find closing dict tag and insert background modes before it
  sed -i '' -e '/<\/dict>/i\'$'\n''\\t<key>UIBackgroundModes<\/key>\'$'\n''\\t<array>\'$'\n''\\t\\t<string>remote-notification<\/string>\'$'\n''\\t<\/array>\'$'\n' "$INFO_PLIST"
  echo "Added UIBackgroundModes to Info.plist"
else
  echo "UIBackgroundModes already exists in Info.plist"
fi
EOF

chmod +x ios/background_patch.sh
cd ios && ./background_patch.sh
cd ..

# 4. Check for debug profile
echo "Creating a more permissive entitlements file..."
cat > ios/Runner/Debug.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>com.apple.developer.usernotifications.time-sensitive</key>
    <true/>
    <key>com.apple.developer.background-modes</key>
    <array>
        <string>remote-notification</string>
    </array>
</dict>
</plist>
EOF

# 5. Final steps
echo ""
echo "=== Manual Steps Required ==="
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Go to Runner target > 'Build Settings' > 'Code Signing Entitlements'"
echo "3. Set the value to 'Runner/Debug.entitlements' for Debug configuration"
echo "4. Go to 'Signing & Capabilities' tab and verify 'Push Notifications' and 'Background Modes' are enabled"
echo "5. Clean and build the project"
echo ""
echo "Would you like to open Xcode now? (y/n)"
read -p "> " open_xcode

if [[ $open_xcode == "y" || $open_xcode == "Y" ]]; then
  open ios/Runner.xcworkspace
fi

echo "=== Done! ===" 