import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  MENU RATING SERVICE
//  Complète le système de notation existant (note globale sur
//  la commande) en répercutant cette note sur chaque plat commandé,
//  pour afficher une moyenne ⭐ sur le menu.
//
//  ⚠️ Setup Firebase requis : aucune nouvelle collection.
//  Ajoute juste les champs suivants aux documents du menu (créés
//  automatiquement au premier avis, pas besoin de les initialiser) :
//    noteTotale   (number) — somme brute des notes reçues
//    nombreAvis   (number) — nombre d'avis reçus
//  La moyenne affichée = noteTotale / nombreAvis, calculée à la volée.
// ═══════════════════════════════════════════════════════

class MenuRatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Répercute une note de commande (1 à 5) sur chaque plat de la commande.
  /// À appeler juste après avoir enregistré la note globale de la commande.
  Future<void> noterPlatsDeCommande(int note, List<dynamic> articles) async {
    final batch = _db.batch();
    final menuRef = _db.collection(AppConfig.menu);

    for (final article in articles) {
      final id = (article as Map)['id']?.toString();
      if (id == null || id.isEmpty) continue;
      batch.set(
        menuRef.doc(id),
        {
          'noteTotale': FieldValue.increment(note),
          'nombreAvis': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }

    try {
      await batch.commit();
    } catch (_) {
      // Si un plat a été supprimé du menu depuis, on ignore silencieusement.
    }
  }

  /// Calcule une moyenne lisible à partir des données brutes d'un plat.
  static double moyenne(Map<String, dynamic> plat) {
    final total = (plat['noteTotale'] as num?)?.toDouble() ?? 0;
    final nombre = (plat['nombreAvis'] as num?)?.toInt() ?? 0;
    if (nombre == 0) return 0;
    return total / nombre;
  }

  static int nombreAvis(Map<String, dynamic> plat) => (plat['nombreAvis'] as num?)?.toInt() ?? 0;
}
