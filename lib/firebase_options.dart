import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCOdOn3zhdJqf_4IQ0aZ3P5dCNGU6Gsakc',
    appId: '1:295093114967:web:b5481792792fdde4a12b12',
    messagingSenderId: '295093114967',
    projectId: 'luna-kraft-7dsjjb',
    authDomain: 'luna-kraft-7dsjjb.firebaseapp.com',
    storageBucket: 'luna-kraft-7dsjjb.appspot.com',
    measurementId: 'G-VNER4BEDXW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBD12Lf4b9UB_ZhinHFvNx3JT63u41sa_s',
    appId: '1:1097898434783:android:5c3c3c3c3c3c3c3c3c3c3c',
    messagingSenderId: '1097898434783',
    projectId: 'luna-kraft',
    storageBucket: 'luna-kraft.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBD12Lf4b9UB_ZhinHFvNx3JT63u41sa_s',
    appId: '1:1097898434783:ios:5c3c3c3c3c3c3c3c3c3c3c',
    messagingSenderId: '1097898434783',
    projectId: 'luna-kraft',
    storageBucket: 'luna-kraft.appspot.com',
    iosClientId:
        '1097898434783-5c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c.apps.googleusercontent.com',
    iosBundleId: 'com.flutterflow.lunakraft',
  );
}
