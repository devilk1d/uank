import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated with exact credentials from your project `projects-d5fa8`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDpQHQKEJfJ_DFFkZPROoNPAkZBGbrpCw',
    appId: '1:249030466583:android:11d97238c3d89869091052',
    messagingSenderId: '249030466583',
    projectId: 'projects-d5fa8',
    storageBucket: 'projects-d5fa8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDpQHQKEJfJ_DFFkZPROoNPAkZBGbrpCw',
    appId: '1:249030466583:ios:11d97238c3d89869091052',
    messagingSenderId: '249030466583',
    projectId: 'projects-d5fa8',
    storageBucket: 'projects-d5fa8.firebasestorage.app',
  );
}
