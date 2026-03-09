// lib/firebase_options.dart
// IMPORTANT: Replace all placeholder values below with your actual Firebase config.
// Steps:
// 1. Go to Firebase Console → Project Settings → Your Android App
// 2. Download google-services.json → place at android/app/google-services.json
// 3. Copy the values from google-services.json into the fields below.
// 4. Alternatively, run: flutterfire configure (installs flutterfire CLI first)
//
// DO NOT commit real API keys. Add this file to .gitignore if it contains real values.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace with your actual Firebase Android config from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}
