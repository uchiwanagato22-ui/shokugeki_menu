import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // On récupère l'instance de la base de données Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- FONCTION POUR ENVOYER UNE COMMANDE ---
  Future<void> envoyerCommande({
    required String clientNom,
    required String clientPhone,
    required List<Map<String, dynamic>> articles,
    required int total,
    required String typePaiement,
    String? transactionId,
    required String adresseDetails,
  }) async {
    try {
      await _db.collection('commandes').add({
        'client': clientNom,
        'phone': clientPhone,
        'plats': articles
            .map((item) => "${item['quantite']}x ${item['nom']}")
            .join(", "),
        'total': total,
        'type_paiement': typePaiement,
        'ref_transaction': transactionId ?? '-',
        'statut': 'En attente de validation',
        'adresse': adresseDetails,
        'date_commande': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Erreur lors de l'envoi de la commande : $e");
    }
  }

  Stream<List<Map<String, dynamic>>> obtenirLeMenu() {
    return _db.collection('plats').orderBy('nom').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList(),
        );
  }

  Future<void> ajouterPlat({
    required String nom,
    required String description,
    required int prix,
    required String categorie,
    required String image,
    required bool disponible,
  }) async {
    try {
      await _db.collection('plats').add({
        'nom': nom,
        'description': description,
        'prix': prix,
        'categorie': categorie,
        'image': image,
        'disponible': disponible,
      });
    } catch (e) {
      throw Exception("Erreur lors de l'ajout du plat : $e");
    }
  }

  Future<void> modifierPlat({
    required String id,
    required String nom,
    required String description,
    required int prix,
    required String categorie,
    required String image,
    required bool disponible,
  }) async {
    try {
      await _db.collection('plats').doc(id).update({
        'nom': nom,
        'description': description,
        'prix': prix,
        'categorie': categorie,
        'image': image,
        'disponible': disponible,
      });
    } catch (e) {
      throw Exception("Erreur lors de la modification du plat : $e");
    }
  }

  Future<void> supprimerPlat(String id) async {
    try {
      await _db.collection('plats').doc(id).delete();
    } catch (e) {
      throw Exception("Erreur lors de la suppression du plat : $e");
    }
  }

  Future<void> basculerDisponibilite(String id, bool disponible) async {
    try {
      await _db.collection('plats').doc(id).update({'disponible': disponible});
    } catch (e) {
      throw Exception("Erreur lors du basculement de disponibilité : $e");
    }
  }

  Future<int> importerPlatsExemple(List<Map<String, dynamic>> plats) async {
    try {
      final batch = _db.batch();
      for (final plat in plats) {
        final docRef = _db.collection('plats').doc();
        batch.set(docRef, {
          ...plat,
          'disponible': true,
        });
      }
      await batch.commit();
      return plats.length;
    } catch (e) {
      throw Exception("Erreur lors de l'import des plats exemples : $e");
    }
  }
}
