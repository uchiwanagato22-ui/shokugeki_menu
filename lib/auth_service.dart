import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- INSCRIPTION D'UN CLIENT ---
  Future<User?> inscrireClient({
    required String email,
    required String password,
    required String nom,
    required String telephone,
  }) async {
    try {
      // 1. Création du compte dans Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 2. Enregistrement des infos et du rôle dans Firestore
        await _db.collection('utilisateurs').doc(user.uid).set({
          'uid': user.uid,
          'nom': nom,
          'email': email,
          'telephone': telephone,
          'role':
              'Client', // Par défaut, toute inscription via l'app est un client
          'date_creation': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Erreur d'inscription : ${e.toString()}");
      return null;
    }
  }

  // --- CONNEXION GLOBAL (Client, Caissier, Livreur) ---
  Future<String?> connecterUtilisateur({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Connexion via Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 2. Récupération du rôle dans Firestore
        DocumentSnapshot doc =
            await _db.collection('utilisateurs').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['role'] ??
              'Client'; // Renvoie le rôle exact (Client, Caissier, Livreur)
        }
      }
      return null;
    } catch (e) {
      print("Erreur de connexion : ${e.toString()}");
      return null;
    }
  }

  // --- DÉCONNEXION ---
  Future<void> deconnexion() async {
    await _auth.signOut();
  }
}
