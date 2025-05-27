#!/bin/bash

echo "=== Simple Fix for UIBackgroundModes Issue ==="

# 1. First, make sure background modes are correctly in Info.plist
echo "Checking Info.plist..."
if grep -q "UIBackgroundModes" Runner/Info.plist; then
  echo "UIBackgroundModes already exists in Info.plist"
else
  echo "Adding UIBackgroundModes to Info.plist..."
  sed -i '' -e '/<\/dict>/i\
	<key>UIBackgroundModes<\/key>\
	<array>\
		<string>remote-notification<\/string>\
	<\/array>\
' Runner/Info.plist
fi

# 2. Modify the entitlements file to use com.apple.developer.background-modes
echo "Updating Runner.entitlements..."
cat > Runner/Runner.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
      <string>Default</string>
    </array>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.usernotifications.time-sensitive</key>
    <true/>
</dict>
</plist>
EOF

echo ""
echo "=== Manual Steps Required ==="
echo "1. Open Xcode: open Runner.xcworkspace"
echo "2. Go to Runner target > 'Signing & Capabilities' tab"
echo "3. Click the '+' button to add 'Background Modes' capability"
echo "4. Check 'Remote notifications' under Background Modes"
echo "5. Clean and build the project"
echo ""
echo "Would you like to open Xcode now? (y/n)"
read -p "> " open_xcode

if [[ $open_xcode == "y" || $open_xcode == "Y" ]]; then
  open Runner.xcworkspace
fi

echo "=== Done! ===" 