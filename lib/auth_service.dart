import 'app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Vérifier si l'application est activée par l'administrateur
  Future<Map<String, dynamic>> verifierStatutApplication() async {
    try {
      DocumentSnapshot snap = await _db.collection('statut').doc('statut').get();
      if (snap.exists) {
        return {
          'is_active': snap.get('is_active') ?? false,
          'message': snap.get('message_blocage') ?? 'Application suspendue.',
        };
      }
    } catch (e) {
      print("Erreur statut application: $e");
    }
    return {'is_active': false, 'message': 'Erreur de connexion au serveur.'};
  }

  // Connexion du Client (Email / Mot de passe)
  Future<UserCredential?> connecterClient(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Inscription du Client avec création de son profil complet (Gratuit)
  Future<UserCredential?> inscrireClient({
    required String nom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (res.user != null) {
        await _db.collection('clients').doc(res.user!.uid).set({
          'nom': nom,
          'email': email,
          'telephone': telephone,
          'reperes_favoris': '',
          'date_inscription': FieldValue.serverTimestamp(),
        });
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  // Connexion du Personnel via ton système de Code Secret à 4 chiffres
  Future<String?> connecterPersonnel(String codeSecret) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(AppConfig.personnel)
          .where('code_secret', isEqualTo: codeSecret)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Retourne le rôle trouvé : caissier, livreur, cuisine, ou directeur
        return snapshot.docs.first.get('role') as String;
      }
    } catch (e) {
      print("Erreur connexion personnel: $e");
    }
    return null;
  }

  // Déconnexion universelle
  Future<void> deconnecter() async {
    await _auth.signOut();
  }
}