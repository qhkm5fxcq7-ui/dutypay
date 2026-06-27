import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

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
}
