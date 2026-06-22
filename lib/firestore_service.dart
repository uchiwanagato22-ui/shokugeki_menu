import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> envoyerCommande({
    required String clientNom,
    required String clientPhone,
    required List<Map<String, dynamic>> articles,
    required int total,
    required String typePaiement,
    String? transactionId,
    required String adresseDetails,
    required double latitude,
    required double longitude,
    required String reperesAdresse,
    required String quartier,
    required String userId,
  }) async {
    await _db.collection('commandes').add({
      'client_nom': clientNom,
      'client_telephone': clientPhone,
      'articles': articles,
      'total': total,
      'mode_paiement': typePaiement,
      'ref_transaction': transactionId ?? '',
      'statut': 'En attente',
      'adresse': adresseDetails,
      'latitude': latitude,
      'longitude': longitude,
      'reperes_adresse': reperesAdresse,
      'quartier': quartier,
      'userId': userId,
      'date_commande': FieldValue.serverTimestamp(),
    });
  }

  // MENU CLIENT TEMPS REEL CORRIGÉ
  Stream<List<Map<String, dynamic>>> obtenirMenuTempsReel() {
    return _db
        .collection('menu')
        .orderBy('nom')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> obtenirLeMenu() {
    return obtenirMenuTempsReel();
  }

  Future<void> ajouterPlat({
    required String nom,
    required String description,
    required double prix,
    required String categorie,
    required String image,
    required bool disponible,
  }) async {
    await _db.collection('menu').add({
      'nom': nom,
      'description': description,
      'prix': prix,
      'categorie': categorie,
      'image': image,
      'disponible': disponible,
      'date_creation': FieldValue.serverTimestamp()
    });
  }

  Future<void> modifierPlat({
    required String id,
    required String nom,
    required String description,
    required double prix,
    required String categorie,
    required String image,
    required bool disponible,
  }) async {
    await _db.collection('menu').doc(id).update({
      'nom': nom,
      'description': description,
      'prix': prix,
      'categorie': categorie,
      'image': image,
      'disponible': disponible,
    });
  }

  Future<void> supprimerPlat(String id) async {
    await _db.collection('menu').doc(id).delete();
  }

  Future<void> basculerDisponibilite(
      String id,
      bool disponible
  ) async {
    await _db.collection('menu').doc(id).update({
      'disponible': disponible
    });
  }
}