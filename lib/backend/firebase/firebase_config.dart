import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCOdOn3zhdJqf_4IQ0aZ3P5dCNGU6Gsakc",
            authDomain: "luna-kraft-7dsjjb.firebaseapp.com",
            projectId: "luna-kraft-7dsjjb",
            storageBucket: "luna-kraft-7dsjjb.firebasestorage.app",
            messagingSenderId: "295093114967",
            appId: "1:295093114967:web:b5481792792fdde4a12b12",
            measurementId: "G-VNER4BEDXW"));
  } else {
    await Firebase.initializeApp();
  }
}
