import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBNKmiL9yUpXHMOsFtSldKiXEGHQuRb1r8",
    authDomain: "bill-splitter-d1e6f.firebaseapp.com",
    projectId: "bill-splitter-d1e6f",
    storageBucket: "bill-splitter-d1e6f.firebasestorage.app",
    messagingSenderId: "594194925592",
    appId: "1:594194925592:web:2a24c4c2e667b3aa08db6d",
  );
}
