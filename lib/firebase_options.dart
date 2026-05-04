import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAlHsRX_ynR27FfaPeaoEPKUaLNnQmepIc',
    appId: '1:1089739739948:web:35398726800105778f5289',
    messagingSenderId: '1089739739948',
    projectId: 'studybuddy-8d781',
    authDomain: 'studybuddy-8d781.firebaseapp.com',
    storageBucket: 'studybuddy-8d781.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARLKO7fTPQigrKhu6XIkjQVTzpmiGevCY',
    appId: '1:1089739739948:android:ea6a9da13e7f8b648f5289',
    messagingSenderId: '1089739739948',
    projectId: 'studybuddy-8d781',
    storageBucket: 'studybuddy-8d781.firebasestorage.app',
  );
}
