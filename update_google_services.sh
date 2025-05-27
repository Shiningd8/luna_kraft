#!/bin/bash

# Script to verify and help update Firebase configuration files
echo "Luna Kraft - Google Services Configuration Check"
echo "================================================"

# Check for required Firebase configuration files
android_file="android/app/google-services.json"
ios_file="ios/Runner/GoogleService-Info.plist"

# Function to display helpful instructions
show_instructions() {
  echo "
INSTRUCTIONS FOR FIXING GOOGLE SIGN-IN:

1. Android Configuration:
   - Visit the Firebase Console (https://console.firebase.google.com/)
   - Select your project 'luna-kraft'
   - Go to Project Settings (gear icon) > General
   - Scroll down to 'Your apps' section
   - Select the Android app
   - Click 'Download google-services.json'
   - Place the downloaded file in: $android_file

2. iOS Configuration:
   - In the Firebase Console, select the iOS app
   - Click 'Download GoogleService-Info.plist'
   - Place the downloaded file in: $ios_file
   - Ensure the file contains the correct CLIENT_ID for Google Sign-In

3. Update SHA-1 Certificate Fingerprint (Android):
   - Run the following command to get your debug SHA-1:
     ./gradlew signingReport
   - Copy the SHA-1 from the debug variant
   - In Firebase Console > Project Settings > Your Android app
   - Add the SHA-1 fingerprint and save

4. Update URL Types in Xcode (iOS):
   - Open ios/Runner.xcworkspace in Xcode
   - Select Runner project > Info > URL Types
   - Add a URL Type with:
     - Identifier: google
     - URL Schemes: the reversed client ID from GoogleService-Info.plist
       (starts with 'com.googleusercontent.apps.')

After completing these steps, run:
  flutter clean
  flutter pub get
  cd ios && pod install && cd ..
  
Then rebuild your app.
"
}

# Check if files exist
missing_files=false
if [ ! -f "$android_file" ]; then
  echo "❌ Missing: $android_file"
  missing_files=true
else
  echo "✅ Found: $android_file"
  
  # Check if google-services.json contains proper client id
  if grep -q "client_id" "$android_file"; then
    echo "   ✅ The file has client_id entries"
  else
    echo "   ❌ The file does not have client_id entries - may be invalid"
  fi
fi

if [ ! -f "$ios_file" ]; then
  echo "❌ Missing: $ios_file"
  missing_files=true
else
  echo "✅ Found: $ios_file"
  
  # Check if iOS configuration contains CLIENT_ID
  if grep -q "CLIENT_ID" "$ios_file"; then
    client_id=$(grep "CLIENT_ID" "$ios_file" -A 1 | grep string | sed -E 's/.*<string>(.*)<\/string>.*/\1/')
    echo "   ✅ CLIENT_ID found: $client_id"
  else
    echo "   ❌ CLIENT_ID not found in the file - may be invalid"
  fi
  
  # Check if REVERSED_CLIENT_ID is present for iOS URL scheme configuration
  if grep -q "REVERSED_CLIENT_ID" "$ios_file"; then
    reversed_id=$(grep "REVERSED_CLIENT_ID" "$ios_file" -A 1 | grep string | sed -E 's/.*<string>(.*)<\/string>.*/\1/')
    echo "   ✅ REVERSED_CLIENT_ID found: $reversed_id"
    
    # Check if this ID is properly configured in Info.plist
    if grep -q "$reversed_id" "ios/Runner/Info.plist"; then
      echo "   ✅ REVERSED_CLIENT_ID correctly configured in Info.plist"
    else
      echo "   ❌ REVERSED_CLIENT_ID not configured in Info.plist URL schemes"
    fi
  else
    echo "   ❌ REVERSED_CLIENT_ID not found - Google Sign-In will not work on iOS"
  fi
fi

# Display instructions if files are missing
if [ "$missing_files" = true ]; then
  echo ""
  echo "Some required Firebase configuration files are missing."
  show_instructions
else
  echo ""
  echo "All required configuration files are present."
  echo "If you're still having issues with Google Sign-In, check the detailed instructions:"
  show_instructions
fi 