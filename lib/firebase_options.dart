import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }

    throw UnsupportedError(
      'Firebase is not configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBfrfn21Fz5YWrXf93GL1dZxOgP7pjd0s4',
    appId: '1:811453390937:web:107733ed0d91760448d148',
    messagingSenderId: '811453390937',
    projectId: 'black-queen-c218e',
    authDomain: 'black-queen-c218e.firebaseapp.com',
    storageBucket: 'black-queen-c218e.firebasestorage.app',
    measurementId: 'G-64K1E0W1V6',
  );

  // Filled in automatically by the workflow from keys/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('AND_API_KEY'),
    appId: String.fromEnvironment('AND_APP_ID'),
    messagingSenderId: String.fromEnvironment('AND_SENDER_ID'),
    projectId: String.fromEnvironment('AND_PROJECT_ID'),
    storageBucket: String.fromEnvironment('AND_BUCKET'),
  );
}
