import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  LOYALTY SERVICE — Programme de fidélité
//  ✅ 1 point gagné tous les 100 MRU dépensés (configurable)
//  ✅ 100 points = 500 MRU de réduction (configurable)
//  ✅ Stocké dans clients/{uid}.points_fidelite
//
//  ⚠️ Setup Firebase requis :
//  - Aucune nouvelle collection : utilise "clients" (déjà existante).
//  - Ajoute juste le champ "points_fidelite" (number, défaut 0) —
//    Firestore le crée tout seul au premier ajout de points.
//  - Règle de sécurité recommandée : le champ points_fidelite ne doit
//    être modifiable que par le backend/staff, pas par le client lui-même
//    (sinon un client pourrait se donner des points lui-même). Le plus
//    sûr est de faire l'incrémentation via une Cloud Function déclenchée
//    par le changement de statut "livree", plutôt que côté client comme
//    ici. Cette version est un point de départ fonctionnel.
// ═══════════════════════════════════════════════════════

class LoyaltyService {
  LoyaltyService._();
  static final LoyaltyService instance = LoyaltyService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Règles du programme (modifiables facilement ici)
  static const double montantParPoint = 100; // 100 MRU dépensés = 1 point
  static const int pointsPourReduction = 100; // 100 points =
  static const double reductionEnMru = 500; // ... 500 MRU de réduction

  /// Calcule combien de points rapporte un montant dépensé
  int calculerPointsGagnes(double montant) {
    if (montant <= 0) return 0;
    return (montant / montantParPoint).floor();
  }

  /// À appeler quand une commande passe au statut "livree".
  /// Idempotent-safe si tu passes toujours le même docId de commande :
  /// on marque la commande avec 'points_credites' pour ne jamais
  /// créditer deux fois les mêmes points (double-tap, reconnexion, etc).
  Future<void> crediterPointsPourCommande({
    required String commandeId,
    required String clientId,
    required double total,
  }) async {
    if (clientId.isEmpty || clientId == 'invite') return;

    final points = calculerPointsGagnes(total);
    if (points <= 0) return;

    final clientRef = _db.collection(AppConfig.clients).doc(clientId);
    final commandeRef = _db.collection(AppConfig.commandes).doc(commandeId);

    await _db.runTransaction((tx) async {
      final commandeSnap = await tx.get(commandeRef);

      final dejaCredite = (commandeSnap.data() as Map<String, dynamic>?)?['points_credites'] == true;
      if (dejaCredite) return; // déjà fait, on ne double-crédite pas

      tx.update(commandeRef, {'points_credites': true});
      tx.set(
        clientRef,
        {'points_fidelite': FieldValue.increment(points)},
        SetOptions(merge: true),
      );
    });
  }

  /// Flux temps réel du solde de points d'un client
  Stream<int> pointsStream(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return _db.collection(AppConfig.clients).doc(uid).snapshots().map(
        (doc) => (doc.data()?['points_fidelite'] as num?)?.toInt() ?? 0);
  }

  /// Combien de "packs de réduction" le client peut utiliser avec son solde
  int packsDisponibles(int soldePoints) => soldePoints ~/ pointsPourReduction;

  /// Montant de réduction si on utilise [nbPacks] packs de points
  double reductionPour(int nbPacks) => nbPacks * reductionEnMru;

  /// Débite les points utilisés au moment de la commande (à appeler
  /// juste après la création de la commande dans client_cart_screen).
  Future<void> debiterPoints(String uid, int nbPoints) async {
    if (uid.isEmpty || nbPoints <= 0) return;
    await _db.collection(AppConfig.clients).doc(uid).set(
      {'points_fidelite': FieldValue.increment(-nbPoints)},
      SetOptions(merge: true),
    );
  }
}
