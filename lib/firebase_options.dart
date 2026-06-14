import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// DefaultFirebaseOptions configuré spécifiquement pour Shokugeki Menu sur Android.
/// Ce fichier utilise tes vrais identifiants Firebase pour débloquer le démarrage sur ton téléphone.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.',
        );
    }
  }

  // Configuration Android officielle tirée de ton google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAWkRob5TLr2qRs1cPxZcY8R83c_i6RaXI",
    appId: "1:591627114214:android:d0b8b5887d9328cc078d27",
    messagingSenderId: "591627114214", // Ton project_number
    projectId: "shokugeki-menu",
    storageBucket: "shokugeki-menu.firebasestorage.app",
  );
}