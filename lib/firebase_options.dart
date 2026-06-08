import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Le support Web nécessite une configuration manuelle. Utilisez Android pour tester avec google-services.json.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Sous Android, Firebase va lire directement ton fichier google-services.json automatiquement !
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.',
        );
    }
  }

  // Configuration automatique via google-services.json sous Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "FROM_GOOGLE_SERVICES_JSON",
    appId: "FROM_GOOGLE_SERVICES_JSON",
    messagingSenderId: "FROM_GOOGLE_SERVICES_JSON",
    projectId: "FROM_GOOGLE_SERVICES_JSON", // Il va détecter ton projet tout seul
  );
}