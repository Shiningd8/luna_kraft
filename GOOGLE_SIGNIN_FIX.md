# Google Sign-In Fix

You're experiencing an error with Google Sign-In: `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)`. 

This is typically caused by an SHA-1 certificate mismatch or OAuth configuration issue. Here's how to fix it:

## 1. Update the SHA-1 Certificate in Firebase

You need to ensure that the SHA-1 fingerprint of your development device is added to Firebase:

1. Run this command in your project directory to get your debug SHA-1:
   ```
   cd android
   ./gradlew signingReport
   ```
   
2. Look for the "SHA1" value under the "Variant: debug" section.

3. Go to the [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Click the Android app icon (com.flutterflow.lunakraft)
   - Go to Project Settings (gear icon) > Your Android App > Add fingerprint
   - Add your SHA-1 fingerprint

4. Download the updated `google-services.json` file and replace it in your `android/app/` directory.

## 2. Check OAuth Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select the project associated with your Firebase project
3. Go to "APIs & Services" > "Credentials"
4. Find your Android OAuth client and verify it has:
   - The correct package name: `com.flutterflow.lunakraft`
   - The correct SHA-1 certificate

## 3. Test with Web Authentication First

If you're still having issues, try using web authentication first to verify your Firebase project is set up correctly:
1. Temporarily modify your sign-in code to use `signInWithPopup` on all platforms
2. If this works, the issue is specifically with Android client OAuth setup

## 4. Clear App Data and Cache

Sometimes a corrupt app state can cause sign-in issues:
1. Go to phone Settings > Apps > Luna Kraft
2. Clear cache and data
3. Uninstall and reinstall the app

## 5. Check Internet Connection

Ensure you have a stable internet connection when testing Google Sign-In.

## 6. Verify Google Play Services

Make sure your device has:
1. Latest version of Google Play Services
2. A Google account added to the device

## Need More Help?

If you're still facing issues, check:
- Firebase logs in the Firebase Console
- Logcat output with the filter tag "GoogleSignIn" for more detailed error information 