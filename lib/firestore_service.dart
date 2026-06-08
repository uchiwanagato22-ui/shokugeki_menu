import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
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
        'plats': articles.map((item) => "${item['quantite']}x ${item['nom']}").join(", "),
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

  // --- INCLUS DANS LA CLASSE : FONCTION POUR RÉCUPÉRER LES PLATS DU MENU ---
  Stream<List<Map<String, dynamic>>> obtenirLeMenu() {
    return _db.collection('menu').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'] ?? 'Plat sans nom',
          'description': data['description'] ?? '',
          'prix': data['prix'] ?? 0,
          'categorie': data['categorie'] ?? 'Divers',
          'image': data['image'] ?? '',
          'disponible': data['disponible'] ?? true,
        };
      }).toList();
    });
  }
}