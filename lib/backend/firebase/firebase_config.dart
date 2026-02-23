import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAl7Jlzgyet26D3zO4pF56BfznA3k3AiTk",
            authDomain: "doron-b3011.firebaseapp.com",
            projectId: "doron-b3011",
            storageBucket: "doron-b3011.firebasestorage.app",
            messagingSenderId: "1020882932619",
            appId: "1:1020882932619:web:316e35c7909dc198eed58e"));
  } else {
    await Firebase.initializeApp();
  }
}
