import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDVAEfwAswgvJ1xi5o481N4AhOSpucIxoM',
    appId: '1:721832620853:android:79fd37ccd4c66ae3aad27c',
    messagingSenderId: '721832620853',
    projectId: 'registro-despesas-app',
    authDomain: 'registro-despesas-app.firebaseapp.com',
    storageBucket: 'registro-despesas-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVAEfwAswgvJ1xi5o481N4AhOSpucIxoM',
    appId: '1:721832620853:android:79fd37ccd4c66ae3aad27c',
    messagingSenderId: '721832620853',
    projectId: 'registro-despesas-app',
    storageBucket: 'registro-despesas-app.firebasestorage.app',
  );
}
