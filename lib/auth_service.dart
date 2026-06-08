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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _db.collection('utilisateurs').doc(user.uid).set({
          'uid': user.uid,
          'nom': nom,
          'email': email,
          'telephone': telephone,
          'role': 'Client', 
          'date_creation': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Erreur d'inscription : ${e.toString()}");
      return null;
    }
  }

  // --- CONNEXION GLOBAL ---
  Future<String?> connecterUtilisateur({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc = await _db.collection('utilisateurs').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['role'] ?? 'Client'; 
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