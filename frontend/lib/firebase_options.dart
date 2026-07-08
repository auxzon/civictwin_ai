import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Default [FirebaseOptions] for use with the Firebase SDK.
/// Manually populated from the verified project apps config to bypass interactive CLI setup.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNaXil5EAHhpH2xD6UP5SraFEn2c1o6Qk',
    appId: '1:24823441543:web:b5030cee5dc3c045963022',
    messagingSenderId: '24823441543',
    projectId: 'civictwin-ai-c0e63',
    authDomain: 'civictwin-ai-c0e63.firebaseapp.com',
    storageBucket: 'civictwin-ai-c0e63.firebasestorage.app',
    measurementId: 'G-G93LKC59BM',
  );
}
