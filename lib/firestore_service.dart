import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ENVOYER UNE COMMANDE CLIENT ---
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
    try {
      await _db.collection('commandes').add({
        'client_nom': clientNom,
        'client_telephone': clientPhone,
        'articles': articles,
        'total': total,
        'mode_paiement': typePaiement,
        'ref_transaction': transactionId ?? '-',
        'statut': 'En attente',
        'adresse': adresseDetails,
        'latitude': latitude,
        'longitude': longitude,
        'reperes_adresse': reperesAdresse,
        'quartier': quartier,
        'userId': userId,
        'date_commande': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Erreur commande : $e");
    }
  }


  // --- MENU TEMPS RÉEL (UTILISÉ PAR CLIENT) ---
  Stream<QuerySnapshot<Map<String, dynamic>>> recupererMenu() {
    return _db
        .collection('menu')
        .orderBy('nom')
        .snapshots();
  }


  // --- VERSION LISTE (AUTRES ÉCRANS) ---
  Stream<List<Map<String, dynamic>>> obtenirLeMenu() {
    return _db.collection('menu').orderBy('nom').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      },
    );
  }


  // --- AJOUTER UN PLAT ---
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
      'date_creation': FieldValue.serverTimestamp(),

    });

  }



  // --- MODIFIER UN PLAT ---
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



  // --- SUPPRIMER UN PLAT ---
  Future<void> supprimerPlat(String id) async {

    await _db.collection('menu').doc(id).delete();

  }



  // --- DISPONIBILITÉ ---
  Future<void> basculerDisponibilite(
      String id,
      bool disponible
  ) async {

    await _db
        .collection('menu')
        .doc(id)
        .update({

      'disponible': disponible

    });

  }

}