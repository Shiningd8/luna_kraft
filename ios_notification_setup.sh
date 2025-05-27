#!/bin/bash

# Exit on error
set -e

echo "=== Setting up iOS Push Notification Capabilities ==="

cd ios

# Make sure CocoaPods is installed and up to date
echo "=== Updating CocoaPods dependencies ==="
pod install --repo-update

# Inform user about manual steps needed in Xcode
echo ""
echo "=== IMPORTANT MANUAL STEPS ==="
echo "Please complete the following steps in Xcode manually:"
echo ""
echo "1. Open Xcode: open Runner.xcworkspace"
echo "2. Select the Runner target"
echo "3. Go to the 'Signing & Capabilities' tab"
echo "4. Ensure 'Push Notifications' capability is enabled"
echo "5. Ensure 'Background Modes' is enabled with 'Remote notifications' checked"
echo "6. Select the ImageNotification target"
echo "7. Ensure it has the same Team selected as the Runner target"
echo "8. Ensure it has 'App Groups' capability if you want to share data between extension and app"
echo "9. Build the app for a real device (not simulator) to test push notifications"
echo ""
echo "=== FCM PAYLOAD STRUCTURE ==="
echo "For notifications to work when app is terminated, use this payload structure:"
echo ""
cat << 'EOF'
{
  "to": "YOUR_DEVICE_FCM_TOKEN",
  "priority": "high",
  "content_available": true,
  "mutable_content": true,
  "notification": {
    "title": "New Activity",
    "body": "Someone liked your post",
    "sound": "default"
  },
  "data": {
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "type": "like",
    "sender_id": "user123",
    "post_id": "post456"
  },
  "apns": {
    "payload": {
      "aps": {
        "content-available": 1,
        "mutable-content": 1,
        "sound": "default",
        "badge": 1
      }
    },
    "fcm_options": {
      "image": "https://example.com/image.jpg"
    }
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "luna_kraft_channel",
      "notification_priority": "PRIORITY_MAX",
      "default_sound": true,
      "default_vibrate_timings": true
    }
  }
}
EOF
echo ""
echo "=== Setup Complete ===" 