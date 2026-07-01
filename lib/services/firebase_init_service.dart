import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseInitService {
  FirebaseInitService._();

  static Future<void>? _future;

  static Future<void> inicializar() {
    if (Firebase.apps.isNotEmpty) {
      return Future.value();
    }

    _future ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) {}).catchError((Object erro) {
      _future = null;
      throw erro;
    });

    return _future!;
  }
}
