import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions? get maybeCurrentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return null;
      case TargetPlatform.macOS:
        return null;
      case TargetPlatform.windows:
        return null;
      case TargetPlatform.linux:
        return null;
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static String get unsupportedPlatformMessage {
    if (kIsWeb) {
      return 'Firebase web config is missing. Add a Web app in Firebase Console '
          'and regenerate firebase_options.dart to use Firebase on Chrome.';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Firebase is configured for Android.';
      case TargetPlatform.iOS:
        return 'Firebase is not configured for iOS yet.';
      case TargetPlatform.macOS:
        return 'Firebase is not configured for macOS yet.';
      case TargetPlatform.windows:
        return 'Firebase is not configured for Windows yet.';
      case TargetPlatform.linux:
        return 'Firebase is not configured for Linux yet.';
      case TargetPlatform.fuchsia:
        return 'Firebase is not configured for Fuchsia yet.';
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdI05ccaKRyxFfZNCCpPCWpARm_ZhPRgo',
    appId: '1:835796562925:android:c68bb47e1d3c3d93142de4',
    messagingSenderId: '835796562925',
    projectId: 'garbage-classification-c4ab6',
    storageBucket: 'garbage-classification-c4ab6.firebasestorage.app',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxcMPVqhViYQChAUXwXxq_IxNJrdK99uU',
    appId: '1:835796562925:web:0d2ae981bf0997ae142de4',
    messagingSenderId: '835796562925',
    projectId: 'garbage-classification-c4ab6',
    storageBucket: 'garbage-classification-c4ab6.firebasestorage.app',
  );
  
}
