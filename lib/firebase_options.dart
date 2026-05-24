// File generated manually from google-services.json
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDtP7Z61uPXvbVxNJfTKXf1GYJKJLzm58',
    appId: '1:832669677192:android:b8eff928b877854f4e113d',
    messagingSenderId: '832669677192',
    projectId: 'projeodevi-e1a8f',
    storageBucket: 'projeodevi-e1a8f.firebasestorage.app',
  );

  // iOS, Web, macOS, Windows ayarları için Firebase Console'dan
  // ilgili platformları ekleyip bu değerleri güncellemeniz gerekir.
  // Şimdilik Android ayarları kullanılıyor.

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDtP7Z61uPXvbVxNJfTKXf1GYJKJLzm58',
    appId: '1:832669677192:android:b8eff928b877854f4e113d',
    messagingSenderId: '832669677192',
    projectId: 'projeodevi-e1a8f',
    storageBucket: 'projeodevi-e1a8f.firebasestorage.app',
    iosBundleId: 'com.auracook.auraCook',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDtP7Z61uPXvbVxNJfTKXf1GYJKJLzm58',
    appId: '1:832669677192:android:b8eff928b877854f4e113d',
    messagingSenderId: '832669677192',
    projectId: 'projeodevi-e1a8f',
    storageBucket: 'projeodevi-e1a8f.firebasestorage.app',
    authDomain: 'projeodevi-e1a8f.firebaseapp.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDDtP7Z61uPXvbVxNJfTKXf1GYJKJLzm58',
    appId: '1:832669677192:android:b8eff928b877854f4e113d',
    messagingSenderId: '832669677192',
    projectId: 'projeodevi-e1a8f',
    storageBucket: 'projeodevi-e1a8f.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDDtP7Z61uPXvbVxNJfTKXf1GYJKJLzm58',
    appId: '1:832669677192:android:b8eff928b877854f4e113d',
    messagingSenderId: '832669677192',
    projectId: 'projeodevi-e1a8f',
    storageBucket: 'projeodevi-e1a8f.firebasestorage.app',
  );
}
