import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  PROMO SERVICE — Codes de réduction
//
//  ⚠️ Setup Firebase requis (collection déjà prévue dans
//  AppConfig.promotions = "restaurants/{id}/promotions") :
//  Crée un document par code promo, avec les champs :
//    code            (string)  ex: "BIENVENUE10"
//    actif           (bool)    true pour l'activer
//    type            (string)  "pourcentage" ou "montant"
//    valeur          (number)  ex: 10 (=10%) ou 200 (=200 MRU)
//    commandeMinimum (number)  montant minimum pour l'utiliser (0 = aucun)
//    dateExpiration  (timestamp, optionnel)
// ═══════════════════════════════════════════════════════

class PromoResult {
  final bool valide;
  final String? erreur;
  final double reduction;
  final String? codeApplique;

  const PromoResult.succes({required this.reduction, required this.codeApplique})
      : valide = true,
        erreur = null;

  const PromoResult.echec(this.erreur)
      : valide = false,
        reduction = 0,
        codeApplique = null;
}

class PromoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<PromoResult> verifierCode(String code, double sousTotal) async {
    final saisie = code.trim().toUpperCase();
    if (saisie.isEmpty) {
      return const PromoResult.echec('Entrez un code promo.');
    }

    try {
      final snap = await _db
          .collection(AppConfig.promotions)
          .where('code', isEqualTo: saisie)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return const PromoResult.echec('Code promo invalide.');
      }

      final data = snap.docs.first.data();

      final actif = data['actif'] == true;
      if (!actif) {
        return const PromoResult.echec('Ce code promo n\'est plus actif.');
      }

      final expiration = data['dateExpiration'];
      if (expiration is Timestamp && expiration.toDate().isBefore(DateTime.now())) {
        return const PromoResult.echec('Ce code promo a expiré.');
      }

      final commandeMinimum = (data['commandeMinimum'] as num?)?.toDouble() ?? 0;
      if (sousTotal < commandeMinimum) {
        return PromoResult.echec(
            'Commande minimum de ${commandeMinimum.toStringAsFixed(0)} MRU pour ce code.');
      }

      final type = (data['type'] ?? 'montant').toString();
      final valeur = (data['valeur'] as num?)?.toDouble() ?? 0;

      double reduction = type == 'pourcentage' ? sousTotal * (valeur / 100) : valeur;
      if (reduction > sousTotal) reduction = sousTotal; // jamais négatif

      return PromoResult.succes(reduction: reduction, codeApplique: saisie);
    } catch (e) {
      return const PromoResult.echec('Erreur de vérification du code. Réessayez.');
    }
  }
}
