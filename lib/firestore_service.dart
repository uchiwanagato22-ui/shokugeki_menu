import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic> _mapPlat(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'id': doc.id,
      'nom': data['nom'] ?? 'Plat sans nom',
      'description': data['description'] ?? '',
      'prix': data['prix'] ?? 0,
      'categorie': data['categorie'] ?? 'Divers',
      'image': data['image'] ?? '',
      'disponible': data['disponible'] ?? true,
    };
  }

  Stream<List<Map<String, dynamic>>> obtenirLeMenu({bool disponibleUniquement = false}) {
    Query<Map<String, dynamic>> query = _db.collection('menu').orderBy('nom');
    if (disponibleUniquement) {
      query = query.where('disponible', isEqualTo: true);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(_mapPlat).toList(),
    );
  }

  Future<void> ajouterPlat({
    required String nom,
    required String description,
    required int prix,
    required String categorie,
    String image = '',
    bool disponible = true,
  }) async {
    await _db.collection('menu').add({
      'nom': nom.trim(),
      'description': description.trim(),
      'prix': prix,
      'categorie': categorie,
      'image': image.trim(),
      'disponible': disponible,
      'date_ajout': FieldValue.serverTimestamp(),
    });
  }

  Future<void> modifierPlat({
    required String id,
    required String nom,
    required String description,
    required int prix,
    required String categorie,
    String image = '',
    required bool disponible,
  }) async {
    await _db.collection('menu').doc(id).update({
      'nom': nom.trim(),
      'description': description.trim(),
      'prix': prix,
      'categorie': categorie,
      'image': image.trim(),
      'disponible': disponible,
    });
  }

  Future<void> supprimerPlat(String id) async {
    await _db.collection('menu').doc(id).delete();
  }

  Future<void> basculerDisponibilite(String id, bool disponible) async {
    await _db.collection('menu').doc(id).update({'disponible': disponible});
  }

  Future<int> importerPlatsExemple(List<Map<String, dynamic>> plats) async {
    final batch = _db.batch();
    for (final plat in plats) {
      final ref = _db.collection('menu').doc();
      batch.set(ref, {
        'nom': plat['nom'],
        'description': plat['description'] ?? '',
        'prix': plat['prix'],
        'categorie': plat['categorie'] ?? 'Divers',
        'image': plat['image'] ?? '',
        'disponible': true,
        'date_ajout': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return plats.length;
  }

  Future<void> envoyerCommande({
    required String clientNom,
    required String clientPhone,
    required List<Map<String, dynamic>> articles,
    required int total,
    required String typePaiement,
    String? transactionId,
    required String adresseDetails,
  }) async {
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
  }
}
