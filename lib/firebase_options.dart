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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDusFxoYL2MWiWBDj-RD9vwFXAkdcLwS4Q',
    authDomain: 'dutypay-ec498.firebaseapp.com',
    projectId: 'dutypay-ec498',
    storageBucket: 'dutypay-ec498.firebasestorage.app',
    messagingSenderId: '1069881451179',
    appId: '1:1069881451179:web:b619adc134c6b2225c4dee',
    measurementId: 'G-2F59KS1LY2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBspdeGCfiVB8qgSNZ-o9SOqSQC8omd2Dk',
    appId: '1:1069881451179:android:42bca9f5105e812b5c4dee',
    messagingSenderId: '1069881451179',
    projectId: 'dutypay-ec498',
    storageBucket: 'dutypay-ec498.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAes2ptObzGaej5sNI5WoOkwTqSI0iZx_U',
    appId: '1:1069881451179:ios:85c0f7fb753eaf195c4dee',
    messagingSenderId: '1069881451179',
    projectId: 'dutypay-ec498',
    storageBucket: 'dutypay-ec498.firebasestorage.app',
    iosBundleId: 'com.dutypay.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAes2ptObzGaej5sNI5WoOkwTqSI0iZx_U',
    appId: '1:1069881451179:ios:85c0f7fb753eaf195c4dee',
    messagingSenderId: '1069881451179',
    projectId: 'dutypay-ec498',
    storageBucket: 'dutypay-ec498.firebasestorage.app',
    iosBundleId: 'com.dutypay.app',
  );
}
