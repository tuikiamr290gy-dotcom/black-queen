import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'Firebase is currently configured for Web only.',
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
}
