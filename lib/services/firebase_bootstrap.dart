import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../firebase_options.dart';

/// Initializes the native Firebase app when platform configuration exists.
///
/// `flutterfire configure` supplies that configuration. Keeping initialization
/// guarded lets the DummyJSON lab flow remain usable while a developer is still
/// completing the one-time Firebase Console setup.
Future<bool> initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException {
    return false;
  } catch (_) {
    return false;
  }
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  }
  return true;
}
