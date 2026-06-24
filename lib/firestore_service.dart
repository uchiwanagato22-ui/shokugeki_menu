import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  FIRESTORE SERVICE — Multi-tenant v2
//  ✅ Toutes les collections passent par AppConfig
//  ✅ Données isolées par restaurant
//  ✅ Clés unifiées camelCase
// ═══════════════════════════════════════════════════════

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Références ────────────────────────────────────────
  CollectionReference get _menu => _db.collection(AppConfig.menu);
  CollectionReference get _commandes => _db.collection(AppConfig.commandes);
  CollectionReference get _utilisateurs => _db.collection(AppConfig.utilisateurs);

  // ════════════════════════════════════════════════════
  //  MENU
  // ════════════════════════════════════════════════════

  Stream<List<Map<String, dynamic>>> obtenirMenuTempsReel() {
    return _menu
        .where('disponible', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }

  Stream<List<Map<String, dynamic>>> obtenirLeMenu() => obtenirMenuTempsReel();

  Future<void> ajouterPlat({
    required String nom,
    required String description,
    required double prix,
    required String categorie,
    required String image,
    required bool disponible,
  }) async {
    await _menu.add({
      'nom': nom,
      'description': description,
      'prix': prix,
      'categorie': categorie,
      'image': image,
      'disponible': disponible,
      'populaire': false,
      'nouveau': true,
      'date_creation': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
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
    await _menu.doc(id).update({
      'nom': nom, 'description': description, 'prix': prix,
      'categorie': categorie, 'image': image, 'disponible': disponible,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> supprimerPlat(String id) async => _menu.doc(id).delete();

  Future<void> basculerDisponibilite(String id, bool disponible) async {
    await _menu.doc(id).update({'disponible': disponible, 'updated_at': FieldValue.serverTimestamp()});
  }

  // ════════════════════════════════════════════════════
  //  COMMANDES
  // ════════════════════════════════════════════════════

  Future<void> envoyerCommande({
    required String clientNom,
    required String clientPhone,
    required List<Map<String, dynamic>> articles,
    required double total,
    required double fraisLivraison,
    required String modePaiement,
    required String modeCommande,
    required String adresseDetails,
    required double latitude,
    required double longitude,
    required String reperesAdresse,
    required String quartier,
    String? transactionId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'invite';
    await _commandes.add({
      'clientId': uid,
      'clientNom': clientNom,
      'clientTelephone': clientPhone,
      'articles': articles,
      'total': total,
      'sousTotal': total - fraisLivraison,
      'fraisLivraison': fraisLivraison,
      'mode_paiement': modePaiement,
      'mode_commande': modeCommande,
      'ref_transaction': transactionId ?? '',
      'statut': 'en_attente',
      'adresse_reperes': reperesAdresse,
      'zone': quartier,
      'quartier': quartier,
      'latitude': latitude,
      'longitude': longitude,
      'date_creation': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> obtenirCommandesClient(String uid) {
    return _commandes
        .where('clientId', isEqualTo: uid)
        .orderBy('date_creation', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }

  Stream<QuerySnapshot> commandesParStatut(String statut) {
    return _commandes.where('statut', isEqualTo: statut).snapshots();
  }

  Stream<QuerySnapshot> commandesParStatuts(List<String> statuts) {
    return _commandes.where('statut', whereIn: statuts).snapshots();
  }

  Stream<QuerySnapshot> toutesCommandesActives() {
    return _commandes.where('statut', whereNotIn: ['rejete']).snapshots();
  }

  Future<void> mettreAJourStatut(String docId, String statut, {Map<String, dynamic>? extra}) async {
    final data = <String, dynamic>{'statut': statut, 'updated_at': FieldValue.serverTimestamp()};
    if (extra != null) data.addAll(extra);
    await _commandes.doc(docId).update(data);
  }

  // ════════════════════════════════════════════════════
  //  UTILISATEURS / FCM
  // ════════════════════════════════════════════════════

  Future<void> sauvegarderToken(String uid, String token) async {
    await _utilisateurs.doc(uid).set({'fcm_token': token, 'updated_at': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<String?> obtenirToken(String uid) async {
    final doc = await _utilisateurs.doc(uid).get();
    return (doc.data() as Map<String, dynamic>?)?['fcm_token']?.toString();
  }
}